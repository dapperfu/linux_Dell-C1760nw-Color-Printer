# Dell C1760nw CUPS

Home Assistant app that runs a CUPS server for the Dell C1760nw (Xerox Phaser 6000B).

The driver is a 32-bit package from 2011. Installing it on the host turns on the i386 architecture and pulls 32-bit libraries onto the machine. This app keeps that install in one container. Other computers print to port 50631.

amd64 only. See [DOCS.md](DOCS.md).
