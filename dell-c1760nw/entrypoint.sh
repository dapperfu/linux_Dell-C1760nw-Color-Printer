#!/bin/bash
set -euo pipefail

# Home Assistant writes the app options here and mounts /data for persistence.
if [ -f /data/options.json ]; then
    CUPS_USER=$(jq -r '.cups_user // "admin"' /data/options.json)
    CUPS_PASSWORD=$(jq -r '.cups_password // empty' /data/options.json)
    PRINTER_IP=$(jq -r '.printer_ip // empty' /data/options.json)
    export CUPS_USER CUPS_PASSWORD PRINTER_IP

    mkdir -p /data/cups /data/spool
    if [ ! -f /data/cups/cupsd.conf ]; then
        cp -a /etc/cups/. /data/cups/
    fi
    rm -rf /etc/cups
    ln -s /data/cups /etc/cups
    rm -rf /var/spool/cups
    ln -s /data/spool /var/spool/cups
fi

: "${CUPS_USER:=admin}"
if [ -z "${CUPS_PASSWORD:-}" ]; then
    echo "CUPS_PASSWORD is required" >&2
    exit 1
fi

if id "$CUPS_USER" >/dev/null 2>&1; then
    usermod -a -G lpadmin "$CUPS_USER"
else
    useradd -r -G lpadmin -M -s /usr/sbin/nologin "$CUPS_USER"
fi
echo "${CUPS_USER}:${CUPS_PASSWORD}" | chpasswd

if [ ! -s /etc/machine-id ]; then
    dbus-uuidgen --ensure=/etc/machine-id
fi

ensure_cupsd_conf() {
    local conf=/etc/cups/cupsd.conf
    if ! grep -q '^ServerAlias \*' "$conf"; then
        printf '\nServerAlias *\n' >> "$conf"
    fi
    if grep -q '^DefaultEncryption ' "$conf"; then
        sed -i 's/^DefaultEncryption .*/DefaultEncryption Never/' "$conf"
    else
        printf 'DefaultEncryption Never\n' >> "$conf"
    fi
    # Debian exits an idle cupsd after 60 seconds. The container has to stay up.
    if grep -q '^IdleExitTimeout ' "$conf"; then
        sed -i 's/^IdleExitTimeout .*/IdleExitTimeout 0/' "$conf"
    else
        printf 'IdleExitTimeout 0\n' >> "$conf"
    fi
}

start_avahi() {
    if avahi-daemon -D; then
        return 0
    fi
    if avahi-daemon --no-chroot -D; then
        return 0
    fi
    echo "Avahi did not start (UDP 5353 may already be in use). CUPS will run without mDNS advertisements." >&2
}

wait_for_cupsd() {
    local _
    for _ in $(seq 1 50); do
        if lpstat -r >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.2
    done
    echo "cupsd did not become ready" >&2
    return 1
}

stop_cupsd() {
    local pidfile=/run/cups/cupsd.pid
    local pid _
    if [ ! -f "$pidfile" ]; then
        return 0
    fi
    pid=$(cat "$pidfile")
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        for _ in $(seq 1 50); do
            kill -0 "$pid" 2>/dev/null || break
            sleep 0.1
        done
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null || true
        fi
    fi
    rm -f "$pidfile"
}

add_printer() {
    local printer_name model
    printer_name=${PRINTER_NAME:-Dell-C1760nw}
    if lpstat -p "$printer_name" >/dev/null 2>&1; then
        echo "Printer ${printer_name} already exists"
        return 0
    fi
    model=$(lpinfo -m | grep -i 'Phaser 6000B' | head -n 1 | awk '{ print $1 }' | tr -d '"' || true)
    if [ -z "$model" ]; then
        echo "Xerox Phaser 6000B driver was not found" >&2
        exit 1
    fi
    lpadmin -p "$printer_name" -v "socket://${PRINTER_IP}:9100" -m "$model" -o printer-is-shared=true -E
    echo "Created shared printer ${printer_name} at socket://${PRINTER_IP}:9100 using ${model}"
}

rm -f /run/dbus/pid /run/dbus/system_bus_socket /run/avahi-daemon/pid /run/cups/cupsd.pid
mkdir -p /run/dbus /run/avahi-daemon /run/cups /var/log/cups /var/spool/cups

dbus-daemon --system --fork

start_avahi

cupsd
wait_for_cupsd
cupsctl --remote-any --remote-admin --share-printers
wait_for_cupsd

if [ -n "${PRINTER_IP:-}" ]; then
    add_printer
fi

stop_cupsd
ensure_cupsd_conf

if awk '$4 == "0A" && $2 ~ /:0277$/ { found = 1 } END { exit !found }' /proc/net/tcp /proc/net/tcp6 2>/dev/null; then
    echo "Port 631 is already in use. Stop the other CUPS service before starting this one." >&2
    exit 1
fi

echo "CUPS is starting on port 631. Admin user: ${CUPS_USER}"
exec cupsd -f
