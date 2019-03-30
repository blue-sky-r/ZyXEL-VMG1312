#!/bin/sh

# force reboot of VDSL modem [ ZyXEL VMG1312 in bridge mode ] from command line (cron)
#
# usage: $0 [-log|-log-tag tag] [-try limit] [-guard cmd] -user user:pass (uptime|reboot) target
#
# -log            ... (optional) log script output to syslog instead to stdout (usefull when executing from cron)
# -log-tag tag    ... (optional) log to syslog (see -log above) with specific tag (default tag is VDSL)
# -try limit      ... (optional) limit login tries to limit (default 3)
# -guard cmd      ... (optional) do not reboot target if cmd is running (download ia wget/curl etc)
# -user user:pass ... valid login for target device separated by :
# uptime          ... only show target uptime/load, do not reboot (usefull for checking if target was recently rebooted)
# reboot          ... perform reboot (see -gurad parameter above)
# target          ... target device to reboot (hostname or ip address)
#
# It is intended for use on dd-wrt capable router, just copy to /jffs/bin/ directory
# and setup a cron job (weekly/monthly) to reboot your ZyXEl VMG1312-B30B:
#   https://wiki.dd-wrt.com/wiki/index.php/CRON

# default login tries limit
#
LIMIT=3

# default logger tag
#
TAG="VDSL"

# default output to stdout
#
OUT="echo"

# version
#
VERSION="2019.3"

# sleep in seconds between login tries
#
SLP=5

# VMG1312 web interface pages
#
PAGE_INF=info.html
PAGE_KEY=resetrouter.html
PAGE_RBT=rebootinfo.cgi

# detect if executed on dd-wrt (returns DD-WRT)
#
os=$( nvram get router_name 2>/dev/null )

# wget options - quiet, stdout
#
WGET="wget -q -O -"
# disable challenge auth. outside of dd-wrt
[ "$os" != 'DD-WRT' ] && WGET="$WGET --auth-no-challenge"

# print/log message
#
msg()
{
    $OUT "$1"
}

# print msg and exit with exit code (default 1)
#
die()
{
    msg "$1"
    exit ${2:-1}
}

# usage
#
[ $# -lt 2 ] && die "usage: $0 [-log-tag tag] [-log] [-try limit] [-guard cmd] -user user:pass (uptime|reboot) target"

# cli pars parser
#
while [ $# -gt 0 ]
do
    case "$1" in
    -t|=try)
        shift
        LIMIT=$1
        ;;
    -l|-log)
        OUT="logger -t $TAG"
        ;;
    -a|-log-tag)
        shift
        TAG=$1
        OUT="logger -t $TAG"
        ;;
    -g|-guard)
        shift
        GUARD=$1
        ;;
    -u|-user)
        shift
        USRPSW=$1
        ;;
    *)
        [ ! $ACTION ] && ACTION=$1 && shift && continue
        MDM=$1
        ;;
    esac
    shift
done

# validate action
#
[ $ACTION != "uptime" ] && [ $ACTION != "reboot" ] && die "ERR - Unknown action:$ACTION, see usage help ..."

# validate login (non empty and contains separator :)
#
([ -z "$USRPSW" ] || [ -z $(echo $USRPSW | cut -d: -f2) ]) && die "ERR - Empty/invalid format login/password:$USRPSW, see usage help ..."

# try to login to main page, limit tries to $LIMIT
#
i=0
while ! $WGET http://$USRPSW@$MDM | grep -q "Broadband Router"
do
	i=$((i+1))
	# login attempt falied message
	msg "WARNING - Modem $MDM login attempt $i from $LIMIT failed, keep trying after $SLP sec ..."
	# if limit has been reached just die with error and exitcode 2
	[ $i -ge $LIMIT ] && die "ERR - Modem $MDM login failed after $i attempts, check login/password/target" 2
	# sleep between tries
	sleep $SLP
done

# get uptime, cpu/mem usage from info page
#
info=$( $WGET http://$MDM/$PAGE_INF )
# uptime
uptime=$( echo "$info" | grep -A1 -i 'up \?time' | awk -F '<|>' '/time/ {txt=$3; gsub(/ time/,"time",txt); getline; up=tolower($3); gsub(/ /,"",up); printf "%s %s, ",txt,up}')
# load
load=$( echo "$info" | grep -A1 'Usage Info' | awk -F '<|>' '/CPU/ {getline; cpu=$3} /Memory/ {getline; mem=$3; printf "CPU:%s MEM:%s",cpu,mem}')

# if only uptime was requested just die with message and exitcode 0
#
[ $ACTION = "uptime" ] && die "Modem $MDM has $uptime$load" 0

# process guard was requested
#
if [ -n "$GUARD" ]
then
    # check if process is running
    psguard=$( ps | grep "$GUARD" | grep -v "grep" | grep -v $0 )

    # if running, exit with error
    [ -n "$psguard" ] && die "ERR - Modem $MDM Reboot not executed, $GUARD is running: $psguard" 3
fi

# get session key from page
#
key=$( $WGET http://$MDM/$PAGE_KEY | grep 'var sessionKey=' | grep -o "[0-9]\+" )

# reboot
#
msg=$( $WGET "http://$MDM/$PAGE_RBT?sessionKey=$key" | grep 'is rebooting' | sed -e 's/<br>//g' )

msg "Modem $MDM has $uptime$load - Reboot Request sessionKey($key) - Response($msg)"
