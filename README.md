# DNagios

Based on Alpine Linux version 3.17.3

WEB access: admin / nagiosadmin

  *  Nagios 4.4.11 (without any default config files!)
  *  Nagios Plugins ver. 2.4.4
  *  NRPE ver. 4.1.0
  *  NagiosGraph ver. 1.5.2
  *  Hosted with nginx web-server (without Apache)
  *  Ready for PERL nagios plugins
  *  Vautour Style (https://exchange.nagios.org/directory/Addons/Frontends-%28GUIs-and-CLIs%29/Web-Interfaces/Themes-and-Skins/Vautour-Style/details)
  *  Process control system for all services: http://supervisord.org/introduction.html

## How to run:

docker run --name nagios --restart=always -td -v /opt/nagios/spool/:/usr/local/nagios/var/spool/ -v /opt/nagios/etc/:/usr/local/nagios/etc/ -v /opt/nagios/log:/var/log/nagios:rw -p 8080:80 zxandy/nagios:1.x

where:

* /opt/nagios/etc - Nagios configuration files with all your plugins;
* /opt/nagios/logs - Nagios log and RRD-graph files;

Access:

 /etc/htpasswd.users - user access file in container

Please create /opt/nagios/logs/rrd for graph files and /opt/nagios/logs/archives for archives.

## Known issues
 
  * Not checked email notification
