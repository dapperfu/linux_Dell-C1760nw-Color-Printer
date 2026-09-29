# linux_Dell-C1760nw-Color-Printer
Instructions/files for Dell C1760nw Color Printer.

```Dell C1760nw == Xerox Phaser 6000B```

The only Linux driver is a 32-bit Xerox package from 2011. Installing it on a current machine turns on the i386 architecture and pulls a pile of 32-bit libraries onto an otherwise 64-bit system. The Docker image keeps that install in one container. This machine and the other computers in the house print to it over the network and stay on a normal 64-bit setup.

Tested with `docker-compose up` on Linux Mint 22.3. With the printer IP set, a test page printed. mDNS discovery was out of scope; clients use the server's IP address and port 50631.

Run as root: 

```
wget https://github.com/dapperfu/linux_Dell-C1760nw-Color-Printer/releases/download/v0.0.1/6000_6010_deb_1.01_20110210.zip
unzip 6000_6010_deb_1.01_20110210.zip

dpkg --add-architecture i386
dpkg -i deb_1.01_20110210/xerox-phaser-6000-6010_1.0-1_i386.deb
apt-get install -f --yes
apt-cache search libcups | cut -f1 -d" " | xargs -n1 -I{} apt-get install --yes {}:i386
```

1. Add printer through normal means.
2. "Select printer from database"
3. Xerox > Phaser 6000B

## CUPS server

Run the server from this directory instead of installing the driver on each computer. `docker compose up` builds an amd64 image, installs the 32-bit driver inside it, and publishes CUPS on host port 50631.

Set these in `docker-compose.yml`:

- `CUPS_USER` — admin user (`admin` by default)
- `CUPS_PASSWORD` — admin password
- `PRINTER_IP` — printer address. When set, the server creates a shared queue named `Dell-C1760nw` at `socket://<PRINTER_IP>:9100` using the Xerox Phaser 6000B driver. Leave it empty to add the printer in the web UI; that queue is kept in a volume.

Open `http://<this-machine>:50631` and sign in with `CUPS_USER` and `CUPS_PASSWORD`. Other machines can add `ipp://<this-machine>:50631/printers/Dell-C1760nw`.

## Home Assistant

Release 0.6.0 is a Home Assistant app. The app version matches tag `v0.6.0`. It is amd64 only, because the driver is 32-bit x86.

On the Home Assistant machine, open **Settings → Apps** (older versions call this **Add-ons**), open the store, and choose **Repositories**. Add:

`https://github.com/dapperfu/linux_Dell-C1760nw-Color-Printer`

[![Open your Home Assistant instance and show the add repository dialog with this repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fdapperfu%2Flinux_Dell-C1760nw-Color-Printer)

**Dell C1760nw CUPS** shows in the store. Install it and start it. The admin password defaults to `changeme`. Change it under **Configuration**, save, and restart the app. The web interface is on port 50631. Details are in [dell-c1760nw/DOCS.md](dell-c1760nw/DOCS.md).
