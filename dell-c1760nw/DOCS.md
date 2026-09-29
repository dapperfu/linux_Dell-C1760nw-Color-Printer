# Dell C1760nw CUPS

Version 0.6.1.

The Dell C1760nw uses the 2011 Xerox Phaser 6000B driver, which is 32-bit. This app installs that driver inside its container. Home Assistant itself stays a normal 64-bit system.

The app is amd64 only. It does not run on ARM Home Assistant machines such as a Raspberry Pi.

## Install

Add this repository in **Settings → Apps → App store → Repositories**:

`https://github.com/dapperfu/linux_Dell-C1760nw-Color-Printer`

Install **Dell C1760nw CUPS** from the store and start it.

## Configuration

Open the app and select **Configuration**.

- **Admin user** defaults to `admin`.
- **Admin password** defaults to `changeme` on a new install. Edit it on this page, save, and restart the app. The new password is applied when the app starts.
- **Printer IP address** creates a shared queue named `Dell-C1760nw` at `socket://<address>:9100`. Leave it empty to add the printer once in the web interface. The queue is kept across restarts.

## Printing

Open the web interface from the app page, or go to `http://<home-assistant>:50631`.

Sign in with the admin user and password from the Configuration page. Other computers add:

`ipp://<home-assistant>:50631/printers/Dell-C1760nw`

Clients use that address. mDNS discovery is not part of this app.

Tested with `docker-compose up` on Linux Mint 22.3. With the printer IP set, a test page printed.
