# linux_Dell-C1760nw-Color-Printer

```Dell C1760nw == Xerox Phaser 6000B```

The only Linux driver is a 32-bit Xerox package from 2011. Three ways to use it are below. The Docker and Home Assistant installs keep that 32-bit software in one place, so the rest of the machines stay on a normal 64-bit setup and print to the server.

Tested with `docker-compose up` on Linux Mint 22.3. With the printer IP set, a test page printed. mDNS discovery was out of scope; clients use the server's IP address and port 50631.

## 1. Install the i386 package on the host

Run as root:

```
wget https://github.com/dapperfu/linux_Dell-C1760nw-Color-Printer/releases/download/v0.0.1/6000_6010_deb_1.01_20110210.zip
unzip 6000_6010_deb_1.01_20110210.zip

dpkg --add-architecture i386
dpkg -i deb_1.01_20110210/xerox-phaser-6000-6010_1.0-1_i386.deb
apt-get install -f --yes
apt-cache search libcups | cut -f1 -d" " | xargs -n1 -I{} apt-get install --yes {}:i386
```

Then add the printer:

1. Add printer through normal means.
2. "Select printer from database"
3. Xerox > Phaser 6000B

This is the original install. It turns on the i386 architecture and installs a stack of 32-bit libraries on that machine, including every package whose name matches `libcups`. That set includes development packages, so a desktop or server that only needed a printer driver also gets 32-bit build libraries.

That gets worse on current releases. Debian and Ubuntu are shrinking i386 support, so `apt-get install -f` and the `libcups:i386` loop will fail more often, or they will pull packages that conflict with the 64-bit CUPS already on the machine. A later `apt upgrade` can then break printing or remove the 64-bit print stack while it tries to keep the 2011 filter satisfied. The filter is also linked against the libcups of its era, so a newer libcups soname can leave the queue installed and still unable to print. Every computer that prints this way needs the same i386 install. ARM machines, including many Home Assistant boxes, cannot run it at all.

## 2. Docker Compose

Run this on the machine that should serve the printer, or on another server on the LAN. From this directory:

```
docker compose up
```

`docker-compose up` is the same command on older installs. The image is amd64. It installs the i386 driver inside the container and publishes CUPS on host port **50631**, mapped to port 631 in the container. Port 50631 is used so this server can run beside a CUPS that is already listening on 631.

Set these in `docker-compose.yml`:

- `CUPS_USER` — admin user (`admin` by default)
- `CUPS_PASSWORD` — admin password (`changeme` by default)
- `PRINTER_IP` — printer address. When set, the server creates a shared queue named `Dell-C1760nw` at `socket://<PRINTER_IP>:9100` using the Xerox Phaser 6000B driver. Leave it empty to add the printer once in the web UI. The queue is kept in a volume.

Open `http://<this-machine>:50631` and sign in with `CUPS_USER` and `CUPS_PASSWORD`. Other machines add `ipp://<this-machine>:50631/printers/Dell-C1760nw`.

## 3. Home Assistant

Release 0.6.1 is a Home Assistant app. The app version matches tag `v0.6.1`. Install it on an amd64 Home Assistant machine and that machine becomes the CUPS server for the Dell C1760nw. The 32-bit Xerox driver stays inside the app.

Open **Settings → Apps** (older versions call this **Add-ons**), open the store, and choose **Repositories**. Add:

`https://github.com/dapperfu/linux_Dell-C1760nw-Color-Printer`

[![Open your Home Assistant instance and show the add repository dialog with this repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fdapperfu%2Flinux_Dell-C1760nw-Color-Printer)

**Dell C1760nw CUPS** shows in the store. Install it and start it. The admin password defaults to `changeme`. Change it under **Configuration**, along with the printer IP if the queue should be created on startup. Save, and restart the app. The web interface is on port 50631. Other computers add `ipp://<home-assistant>:50631/printers/Dell-C1760nw`. Details are in [dell-c1760nw/DOCS.md](dell-c1760nw/DOCS.md).
