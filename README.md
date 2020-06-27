# linux_Dell-C1760nw-Color-Printer
Instructions/files for Dell C1760nw Color Printer.

```Dell C1760nw == Xerox Phaser 6000B```

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
