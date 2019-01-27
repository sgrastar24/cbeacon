# cbeacon
iBeacon transmitter program for CLI

### Help

```text
$ cbeacon
OVERVIEW:
  This command line tool is for transmit iBeacon advertisements.
  iBeacon technology uses Bluetooth Low Energy (BLE).

USAGE:
  cbeacon [--time duration] <uuid> <major> <minor>
  cbeacon --version

OPTIONS:
  --time, -t      Duration time for transmission in seconds. 5 seconds default.
  --version, -v   Print version
  --help          Display available options

POSITIONAL ARGUMENTS:
  uuid            Proximity UUID
  major           Major (16bits)
  minor           Minor (16bits)
```
