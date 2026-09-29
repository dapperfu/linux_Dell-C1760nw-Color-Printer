FROM --platform=linux/amd64 debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        avahi-daemon \
        ca-certificates \
        cups \
        cups-client \
        cups-filters \
        dbus \
        ghostscript \
        unzip \
        wget \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && rm -rf /var/lib/apt/lists/*

# Driver install follows the README. apt-get update is required after
# enabling i386, and policy-rc.d keeps the package postinst from starting
# CUPS during the build.
RUN <<'EOF'
set -eux
apt-get update
printf '%s\n' '#!/bin/sh' 'exit 101' > /usr/sbin/policy-rc.d
chmod 755 /usr/sbin/policy-rc.d

cd /tmp
wget https://github.com/dapperfu/linux_Dell-C1760nw-Color-Printer/releases/download/v0.0.1/6000_6010_deb_1.01_20110210.zip
unzip 6000_6010_deb_1.01_20110210.zip

dpkg --add-architecture i386
apt-get update
dpkg -i deb_1.01_20110210/xerox-phaser-6000-6010_1.0-1_i386.deb || true
apt-get install -f --yes
dpkg -s xerox-phaser-6000-6010 | grep -q 'Status: install ok installed'

apt-cache search libcups | cut -f1 -d" " | xargs -n1 -I{} apt-get install --yes {}:i386 || true

apt-get install -y --no-install-recommends \
    avahi-daemon \
    cups \
    cups-client \
    cups-filters \
    dbus \
    ghostscript

install_soname() {
    soname=$1
    case "$soname" in
        libcupsimage.so.2) pkg=libcupsimage2 ;;
        libstdc++.so.6) pkg=libstdc++6 ;;
        libgcc_s.so.1) pkg=libgcc-s1 ;;
        libc.so.6|libm.so.6) pkg=libc6 ;;
        libcups.so.2) pkg=libcups2 ;;
        *)
            if ! command -v apt-file >/dev/null 2>&1; then
                apt-get install -y apt-file
                apt-file update
            fi
            pkg=$(apt-file search -x "/${soname}\$" | awk -F: '/i386-linux-gnu/ { print $1; exit }')
            if [ -z "$pkg" ]; then
                echo "No i386 package provides ${soname}" >&2
                return 1
            fi
            ;;
    esac
    apt-get install -y "${pkg}:i386"
}

missing=$(
    dpkg -L xerox-phaser-6000-6010 | while read -r file; do
        if [ -f "$file" ]; then
            ldd "$file" 2>/dev/null | awk '/not found/ { print $1 }' || true
        fi
    done | sort -u
)
for soname in $missing; do
    install_soname "$soname"
done

still_missing=$(
    dpkg -L xerox-phaser-6000-6010 | while read -r file; do
        if [ -f "$file" ]; then
            ldd "$file" 2>/dev/null | awk '/not found/ { print $1 }' || true
        fi
    done | sort -u
)
if [ -n "$still_missing" ]; then
    echo "Xerox filters are missing libraries: ${still_missing}" >&2
    exit 1
fi

# CUPS lists drivers from /usr/share/cups/model. The package ships PPDs in
# /usr/share/ppd, which is the path the README's printer database uses.
mkdir -p /usr/share/cups/model/Xerox
ln -sfn /usr/share/ppd/Xerox/Xerox_Phaser_6000B.ppd.gz /usr/share/cups/model/Xerox/Xerox_Phaser_6000B.ppd.gz
ln -sfn /usr/share/ppd/Xerox/Xerox_Phaser_6010N.ppd.gz /usr/share/cups/model/Xerox/Xerox_Phaser_6010N.ppd.gz

if command -v apt-file >/dev/null 2>&1; then
    apt-get remove -y apt-file
fi
rm -f /usr/sbin/policy-rc.d
rm -rf /tmp/6000_6010_deb_1.01_20110210.zip /tmp/deb_1.01_20110210 /var/lib/apt/lists/*
EOF

RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

EXPOSE 631
ENTRYPOINT ["/entrypoint.sh"]

LABEL \
    io.hass.version="0.6.0" \
    io.hass.type="app" \
    io.hass.arch="amd64" \
    io.hass.name="Dell C1760nw CUPS" \
    io.hass.description="CUPS server that keeps the 32-bit Xerox driver off the host" \
    io.hass.url="https://github.com/dapperfu/linux_Dell-C1760nw-Color-Printer"
