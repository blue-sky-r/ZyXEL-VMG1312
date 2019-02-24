#!/bin/sh

# force reboot of VDSL modem [ ZyXEL VMG1312 in bridge mode ] from command line (cron)
#
# usage: $0 [-log] [-try limit] [-guard cmd] -user user:pass (uptime|reboot) target
#
# -log            ... (optional) log script output to syslog instead to stdout (usefull when executing from cron)
# -try limit      ... (optional) limit login tries to limit (default 3)
# -guard cmd      ... (optional) do not reboot target if cmd is running (download ia wget/curl etc)
# -user user:pass ... valid login for target device separated by :
# uptime          ... only show target uptime, do not reboot (usefull for checking if target was recently rebooted)
# reboot          ... perform reboot (see -gurad parameter above)
# target          ... target device to reboot (hostname or ip address)
#
# intended for use on dd-wrt capable router, just copy to /jffs/bin/
# and setup cron job (weekly/monthly) to reboot your ZyXEl VMG1312

# login tries limit
#
LIMIT=3

# VMG1312 web interface pages
#
PAGE_INF=info.html
PAGE_KEY=resetrouter.html
PAGE_RBT=rebootinfo.cgi

# wget options - quiet, stdout
#
WGET="wget -q -O -"

# logger tag
#
TAG="VDSL"

# default output to stdout
#
OUT="echo"

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
[ $# -lt 2 ] && die "usage: $0 [-log] [-try limit] [-guard cmd] -user user:pass (uptime|reboot) target"

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
	[ $i -ge $LIMIT ] && die "ERR - Modem $MDM login failed after $i attempts, check login/password" 2
	msg "WARNING - Modem $MDM login attempt $i from $LIMIT failed, keep trying ..."
	sleep 5
done

# uptime
#
uptime=$( $WGET http://$MDM/$PAGE_INF | grep -A1 -i 'up \?time' | awk -F '<|>' '/time/ {txt=$3; gsub(/ time/,"time",txt); getline; up=tolower($3); gsub(/ /,"",up); printf "%s %s, ",txt,up}')

# only uptime was requested
#
[ $ACTION = "uptime" ] && die "Modem $MDM has $uptime" 0

# process guard was requested
#
if [ -n "$GUARD" ]
then
    # check if process is running
    psguard=$( ps | grep "$GUARD" | grep -v "grep" | grep -v $0 )

    # if running, exit with error
    [ -n "$psguard" ] && die "ERR - Modem $MDM Reboot not executed, $GUARD is running: $psguard" 3
fi

# get session key
#
key=$( $WGET http://$MDM/$PAGE_KEY | grep 'var sessionKey=' | grep -o "[0-9]\+" )

# reboot
#
msg=$( $WGET "http://$MDM/$PAGE_RBT?sessionKey=$key" | grep 'is rebooting' | sed -e 's/<br>//g' )

msg "Modem $MDM has $uptime Reboot Request sessionKey($key) - Response($msg)"
