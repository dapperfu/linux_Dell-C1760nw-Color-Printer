# Dell C1760nw CUPS

The Dell C1760nw uses the 2011 Xerox Phaser 6000B driver, which is 32-bit. This app installs that driver inside its container. Home Assistant itself stays a normal 64-bit system.

The app is amd64 only. It does not run on ARM Home Assistant machines such as a Raspberry Pi.

## Configuration

- **Admin user** and **Admin password** sign in to the CUPS web interface. Change the password before you start the app.
- **Printer IP address** creates a shared queue named `Dell-C1760nw` at `socket://<address>:9100`. Leave it empty to add the printer once in the web interface. The queue is stored in the app's data and kept across restarts.

## Printing

Open the web interface from the app page, or go to `http://<home-assistant>:50631`.

Other computers add:

`ipp://<home-assistant>:50631/printers/Dell-C1760nw`

Printers are reached by that address. mDNS discovery is not part of this app.

Tested with `docker-compose up` on Linux Mint 22.3. With the printer IP set, a test page printed.
