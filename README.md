## ZyXEL VMG1312 Reboot from command line

Simple and effective command line script for rebooting the ZyXEL VNG1312.
It might work for other models too (depends on similarity of web interfaces).

![VMG1312](https://github.com/blue-sky-r/ZyXEL-VMG1312/blob/master/screenshots/VMG1312-B30B.jpg)

### do I need this script

### why do we need this utility/script

### ZyXEL VMG1312

ZyXEL VMG1312 is all-in-one SOHO solution (modem, router, WiFi AP) running internally linux.
This device is just overloaded with features and when running is causing serious memory/cpu problems
and is hardly useable. However, when used in bridge mode, ZyXEl VMG1312 is very stable on ADSl/VDSL
lines and can easily achive uptime in years.

### iPTV

Router/modem ZyXEl VMG1312-B30B has some bug/flaw even in the latest firmware. After few weeks of uptime
the VMG1312 brings slight delay when establishing a connection. Might be caused by some unreeased
connection structures in memory so it takes longer and longer to allocate new connection structure.
Under normal usage like browsing it is hardly noticeable, however for iPTV exev such a small delay is
causing picture freezing for a few seconds as hls buffer underflows. And this iPTV video/audio freezing
is very annoying ...

So far there is no official solution from ZyXEL (and hardly it will ever be any) so simple
workaround is just from time-to-time to reboot/restart/power-cycle the ZyXEL modem.


    '''
    usage: zyxel-vmg1312-reboot.sh [-log-tag tag] [-log] [-try limit] [-guard cmd] -user user:pass (uptime|reboot) target

    log-tag TAG    ... [optional] use tag TAG for logging (default VDSL)
    log            ... [optional] output to syslog (for cron jobs etc) instead of stdout (default stdout)
    try limit      ... [optional] try login max. limit times (default 3)
    guard cmd      ... [optional] do not reboot reouter if comman cmd is running (for example wget downloading)
    user user:pass ... [mandatory] valid login to VMG1312
    uptime|reboot  ... [mandatory] either just get uptime or request reboot
    target         ... VMG1312 local hostname or ip address

    '''