## Reboot ZyXEL VMG1312 from command line

Simple and effective command line script for rebooting the ZyXEL VMG1312.
It might work for other models, however slight modification of grep patters might be required (depends on similarity of
the web interfaces).

![VMG1312](../blob/master/screenshots/VMG1312-B30B.jpg "ZyXEL VMG1312")

### ZyXEL VMG1312

ZyXEL VMG1312 is all-in-one SOHO solution (modem, router, WiFi AP) running internally linux.
This device is just overloaded with features and when running as full router there are
some serious memory/cpu load problems and is very unstable. However, when used in bridge mode,
ZyXEl VMG1312 is very stable on ADSL/VDSL lines (with following exception).

### objective

This script is basically extension of the dd-wrt scheduled reboot capability. Now we can
schedule reboot also for xDSL modem. Reboot might be used as a workaround for various
firmware flaws and bugs. Of course user can manually switch off-on the router, but this
script can do it remotly and without user interaction if scheduled.

### iPTV

Router/modem ZyXEl VMG1312-B30B has some bug/flaw even in the latest firmware. After few weeks of uptime
the VMG1312 brings slight delay when establishing a connection. Might be caused by some unreeased
connection structures in memory so it takes longer and longer to allocate new connection structure.
Under normal usage like browsing it is hardly noticeable, however for iPTV exev such a small delay is
causing picture freezing for a few seconds as hls buffer underflows. And this iPTV video/audio freezing
is very annoying ...

So far there is no official solution from ZyXEL (and hardly it will ever be any) so simple
workaround is just from time-to-time to reboot/restart/power-cycle the ZyXEL modem.

### How does it work

The script uses standard dd-wrt **wget**, **awk** and **grep** utilities to access ZyXEL VMG1312 web interface.
The execution flow is quite simple:
* login to info page
* get session-key (required for requesting reboot)
* request reboot (with session-key)

### requirements

This script requires:
* unix utilities (included in dd-wrt):
  * wget, awk, grep, sed
* access to modem web interface - this requires some config on VMG1312 and DD-WRT

### usage

Script can be used manually from command line or scheduled by cron job. There are two modalities
currently implemented:
* uptime modality just shows various uptime and load values (no reboot is executed)
* reboot modality shows various uptime and load values and executes reboot
There are many optional parametes (see bellow) and few mandatory ones:

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

All outputs go to STDOUT by default (useful for debugging).
By using -log parameter they are redirected to syslog (useful for cron jobs).

## Modem in bridge mode - access to web interface

Access to web interface to modem in bridge mode is very useful for statistical and management purposes.

We have to assign some private subnet for LAN interface on modem site, for example 192.168.100.1/24:

![VMG1312 LAN interface](https://github.com/blue-sky-r/ZyXEL-VMG1312/blob/master/screenshots/vmg1312-lan.png "VMG1312 LAN settings")

Then on router / DD-WRT site we have to add another address from this subnet to WAN interface
and also add postrouting iptables rule (for example 192.168.100.3/24):

![dd-wrt](../blob/master/screenshots/dd-wrt.png "DD-WRT Administration")

_NOTE: Of course you can use different subnets and different ip addresses_

