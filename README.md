# osinstall-hardware

This repository provides the hardware tools for cloudboot

## raid

`megaraidcfg.sh` is megacli wrapper for LSI MegaRAID

```bash
./megaraidcfg.sh
raid.sh: raid config tool
Usage: raid.sh [OPTION...]
  -c, --clear                           Clear raid config
  -r, --raid 0/1/5/10                   Raid level for disk
  -d, --disk [0|1,2|3-5|6-|all]         Disk slot num
  -H, --hotspare [0|1,2|3-5|6-|all]     Hotspare disk slot num
  -i, --init                            Initialize all disk
  -D, --debug                           Show debug mode
  -h, --help                            Show this help message
```

`hpraidcfg.sh` is hpssacli wrapper for HP Smart Array

```bash
./hpraidcfg.sh
raid.sh: raid config tool
Usage: raid.sh [OPTION...]
  -c, --clear                           Clear raid config
  -r, --raid 0/1/5/10                   Raid level for disk
  -d, --disk [1|2,3|4-6|7-|all]         Disk slot num
  -H, --hotspare [1|2,3|4-6|7-|all]     Hotspare disk slot num
  -i, --init                            Initialize all disk
  -D, --debug                           Show debug mode
  -h, --help                            Show this help message
```
