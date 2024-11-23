# Linux-CHR 
Convert your Linux OS into Mikrotik CHR

Tested on Ubuntu 22.04/Ubuntu 20.04

## How to use this script?

Clone this repo

```bash
git clone https://github.com/aryapramudika/linux-chr.git
```

Run script

```bash
cd linux-chr
chmod +x linux-chr.sh && bash linux-chr.sh -h
```

```bash
Usage: linux-chr.sh [OPTIONS]
Install MikroTik RouterOS (CHR)

Options:
  -v, --version VERSION    CHR version to install (default: 7.13.3)
  -p, --password PASSWORD  Set admin password (default: admin)
  -d, --device DEVICE      Target disk device (default: /dev/vda)
  -h, --help              Show this help message

Example:
  linux-chr.sh -v 7.13.3 -p mypassword -d /dev/vda
```

### Default values

* User: admin
* Passsword: admin
* CHR version: 7.13.3
* Target disk: /dev/vda

You can customize password for admin, chr version, and target disk

for example if target disk is sata:

```
bash linux-chr.sh -v 7.13.3 -p securepass -d /dev/sda
```


