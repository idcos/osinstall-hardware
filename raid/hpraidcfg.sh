#!/usr/bin/env bash
# version 1.0
# wangsu@idcos.com

export LC_ALL=C
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

usage() {
    cat <<EOF
raid.sh: raid config tool
Usage: raid.sh [OPTION...]
  -c, --clear                           Clear raid config
  -r, --raid 0/1/5/10                   Raid level for disk
  -d, --disk [1|2,3|4-6|7-|all]         Disk slot num
  -H, --hotspare [1|2,3|4-6|7-|all]     Hotspare disk slot num
  -i, --init                            Initialize all disk
  -D, --debug                           Show debug mode
  -h, --help                            Show this help message
EOF
}

[[ $# -lt 1 ]] && usage && exit

ARGS=$(getopt -q -o cr:d:H:iDh -l clear,raid:,disk:,hotspare:,init,debug,help -- "$@")
[[ $? -ne 0 ]] && echo "Unknown options: $1" && exit 1
eval set -- "${ARGS}"

while [[ $# -gt 0 ]]
do
    case "$1" in
        -c|--clear)
            _clear=1
            ;;
        -r|--raid)
            _raid=$2
            shift
            ;;
        -d|--disk)
            _disk=$2
            shift
            ;;
        -H|--hotspare)
            _hotspare=$2
            shift
            ;;
        -i|--init)
            _init=1
            ;;
        -D|--debug)
            _debug=1
            ;;
        -h|--help)
            usage
            ;;
    esac
    shift
done

awk '
function error(s) {
    printf("\033[31merror: %s\033[0m\n", s)
    exit 1
}

function shellcmd(s) {
    if ("'$_debug'" == 1)
        printf("\033[33m# %s\033[0m\n", s)
    system(s)
}

function check_disk(s) {
    delete disk
    if (s ~ /^[[:digit:]]+$/) {
        disk[s]
    } else if (s ~ /^[[:digit:],]+$/) {
        len = split(s, a, ",")
        for (i = 1; i <= len; i++)
            disk[a[i]]
    } else if (s ~ /^[[:digit:]-]+[[:digit:]]$/) {
        split(s, a, "-")
        for (i = a[1]; i <= a[2]; i++)
            disk[i]
    } else if (s ~ /^[[:digit:]]+-$/) {
        split(s, a, "-")
        for (i = a[1]; i <= length(SLOT); i++)
            disk[i]
    } else if (s == "all") {
        for (i in SLOT)
            disk[i]
    }

    for (i in disk)
        if (i in SLOT == 0 )
            error("slot "i" not found")
}

function check_raid(r, num) {
    if (r == 0) {
        if (num < 1)
            error("Disk count must be greater than 1")
    } else if (r == 1) {
        if (num != 2)
            error("Disk count must be 2")
    } else if (r == 5) {
        if (num < 3)
            error("Disk count must be greater than 3")
    } else if (r == 10) {
        if (num < 4 || num % 2 != 0)
            error("Disk count must be greater than 4 and must be in multiples of 2")
    } else {
        error("Raid level only support 0/1/5/10")
    }
}

function clearcfg() {
    cmd = sprintf("%s ctrl slot=%s delete forced override", HPSSACLI, DEVICE)
    shellcmd(cmd)
}

function mkraid(level, disk) {
    if (level == "10")
        level = "1+0"
    len = asorti(disk, a)
    for (i = 1; i <= len; i++)
        parm = sprintf("%s,%s", parm, SLOT[a[i]])
    sub(/^,/, "", parm)
    cmd = sprintf("%s ctrl slot=%s create type=ld drives=%s raid=%s", HPSSACLI, DEVICE, parm, level)
    shellcmd(cmd)
}

function hotspare(disk) {
    len = asorti(disk, a)
    for (i = 1; i <= len; i++)
        parm = sprintf("%s,%s", parm, SLOT[a[i]])
    sub(/^,/, "", parm)
    cmd = sprintf("%s ctrl slot=%s array all add spares=%s", HPSSACLI, DEVICE, parm)
    shellcmd(cmd)
}

function ldinit() {
    cmd = "dd if=/dev/urandom of=/dev/sda bs=512 count=2"
    shellcmd(cmd)
}

BEGIN {
    HPSSACLI = "/usr/sbin/hpssacli"
    while (HPSSACLI" ctrl all show" | getline s) {
        if (s ~ /Smart Array.*Slot/) {
            len = split(s, a, "[[:space:]]+")
            DEVICE = a[6]
            break
        }
    }

    while (HPSSACLI" ctrl slot="DEVICE" pd all show" | getline s) {
        if (s ~ /physicaldrive/) {
            len = split(s, a, "[[:space:]]+")
            sub(/,$/, "", a[7])
            SLOT[a[7]] = a[3]
        }
    }

    # Check disk slot number
    if ("'$_disk'" != "")
        check_disk("'$_disk'")

    # Check raid level
    if ("'$_raid'" != "")
        check_raid("'$_raid'", length(disk))

    # Clear raid config
    if ("'$_clear'" == 1)
        clearcfg()

    # Config raid
    if ("'$_raid'" != "" && "'$_disk'" != "")
        mkraid("'$_raid'", disk)

    # Check hotspare slot number
    if ("'$_hotspare'" != "")
        check_disk("'$_hotspare'")

    # Setup hotspare disk
    if ("'$_hotspare'" != "")
        hotspare(disk)

    # Initialize all disk
    if ("'$_init'" == 1)
        ldinit()
}'
