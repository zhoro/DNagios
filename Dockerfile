FROM alpine:3.17.3

ENV NAGIOS_HOME /usr/local/nagios
ENV NAGIOS_BRANCH nagios-4.4.11
ENV NAGIOS_PLUGINS 2.4.4
ENV NAGIOS_NRPE nrpe-4.1.0
ENV NAGIOS_GRAPH 1.5.2

RUN apk update && apk upgrade
RUN apk add bc tzdata bash sudo supervisor shadow unzip bind-tools ca-certificates nginx fcgiwrap wget iputils perl perl-net-snmp net-snmp-libs net-snmp-perl net-snmp-tools net-snmp
RUN apk add php81 php81-curl php81-fpm php81-gd build-base linux-headers perl-dev perl-module-build openssl openssl-dev perl-libwww perl-net-ssleay
RUN apk add gd gd-dev fontconfig-dev jpeg-dev libx11-dev rrdtool perl perl-rrd perl-cgi perl-gd perl-time-hires curl
RUN apk add terminus-font ttf-inconsolata ttf-dejavu font-noto font-noto-cjk ttf-font-awesome font-noto-extra font-vollkorn font-misc-cyrillic font-mutt-misc font-screen-cyrillic font-winitzki-cyrillic font-cronyx-cyrillic

RUN set -x ; \
    addgroup -g 82 -S www-data ; \
    adduser -u 82 -D -S -G www-data www-data && exit 0 ; exit 1;
# 82 is the standard uid and gid for "www-data" in Alpine Linux

RUN adduser -u 102 -S -h ${NAGIOS_HOME} -H nagios \
	&& addgroup -g 103 -S nagcmd \
	&& addgroup -g 104 -S nagios \
	&& usermod -a -G nagcmd nagios \ 
	&& usermod -a -G nagcmd www-data 

RUN cd /tmp  \
	&& wget https://assets.nagios.com/downloads/nagioscore/releases/${NAGIOS_BRANCH}.tar.gz \
	&& tar -zxvf ${NAGIOS_BRANCH}.tar.gz \
	&& cd /tmp/${NAGIOS_BRANCH}  \
	&& ./configure \
		--disable-ssl \
		--with-nagios-group=nagios \
		--with-command-group=nagcmd \
		--with-mail=/usr/sbin/sendmail \
	&& make all \
	&& make install \
	&& make install-init \
	&& make install-commandmode \
	&& make install-cgis \
	&& cp -R contrib/eventhandlers/ ${NAGIOS_HOME}/libexec/ \
	&& chown -R nagios:nagios ${NAGIOS_HOME}/libexec/eventhandlers \
	&& rm -rf /tmp/${NAGIOS_BRANCH}*

RUN cd /tmp \
    && wget https://github.com/nagios-plugins/nagios-plugins/releases/download/release-${NAGIOS_PLUGINS}/nagios-plugins-${NAGIOS_PLUGINS}.tar.gz \
    && tar -zxvf nagios-plugins-${NAGIOS_PLUGINS}.tar.gz \
    && cd /tmp/nagios-plugins-${NAGIOS_PLUGINS} \
    && ./configure \
	--with-nagios-user=nagios \
	--with-nagios-group=nagios \
    --disable-nls \
		--with-ps-command="/bin/ps -o stat,pid,ppid,vsz,rss,comm,args" \
		--with-ps-format="%s %d %d %d %d %s %n" \
		--with-ps-varlist="procstat,&procpid,&procppid,&procvsz,&procrss,procprog,&pos" \
		--with-ps-cols=7 \
		--enable-perl-modules \
		--enable-extra-opts \
        --with-ping-command='/bin/ping -n -U -w %d -c %d %s' \
        --with-ping6-command='/bin/ping6 -n -U -w %d -c %d %s' \
	--with-ssh-command=/usr/bin/ssh \
    && make \
    && make install \
    && rm -rf /tmp/nagios-plugins-${NAGIOS_PLUGINS}* 


RUN cd /tmp \
    && wget https://github.com/NagiosEnterprises/nrpe/releases/download/${NAGIOS_NRPE}/${NAGIOS_NRPE}.tar.gz \
    && tar -zxvf ${NAGIOS_NRPE}.tar.gz \ 
    && cd /tmp/${NAGIOS_NRPE} \
    && ./configure                                   \
        --with-ssl=/usr/bin/openssl               \
        --with-ssl-lib=/usr/lib                   \ 
        --enable-ssl                   \ 
    && make check_nrpe                             \
    && cp src/check_nrpe ${NAGIOS_HOME}/libexec/  \
    && rm -rf /tmp/${NAGIOS_NRPE}*

RUN /usr/bin/cpan App::cpanminus && rm -rf /root/.cpan
RUN cpanm install inc::latest  Module::Build Nagios::Config Net::SNMP Getopt::Long  Net::IP; rm -fr root/.cpanm 

RUN cd /tmp \
    && wget http://downloads.sourceforge.net/project/nagiosgraph/nagiosgraph/${NAGIOS_GRAPH}/nagiosgraph-${NAGIOS_GRAPH}.tar.gz \
    && tar -zxvf nagiosgraph-${NAGIOS_GRAPH}.tar.gz  
 
#RUN NG_PREFIX=/usr/local/nagiosgraph	NG_WWW_DIR=/usr/local/nagios/share \
#     /tmp/nagiosgraph-${NAGIOS_GRAPH}/install.pl --prefix=/usr/local/nagiosgraph || true

RUN  cd /tmp/nagiosgraph-${NAGIOS_GRAPH};  NG_PREFIX=/usr/local/nagiosgraph NG_WWW_DIR=${NAGIOS_HOME}/share \ 
	 /tmp/nagiosgraph-${NAGIOS_GRAPH}/install.pl   --log-dir /var/log/nagios \	
			--var-dir /var/log/nagios \
			--prefix /usr/local/nagiosgraph \
			--install \
			--silent \ 
			--layout standalone \
			--nagios-cgi-url /nagisograph/cgi || true
RUN cp /tmp/nagiosgraph-${NAGIOS_GRAPH}/share/nagiosgraph.ssi ${NAGIOS_HOME}/share/ssi/common-header.ssi
RUN rm -rf /tmp/nagiosgraph-${NAGIOS_GRAPH}* 

RUN cd /tmp \ 
    && wget https://github.com/ynlamy/vautour-style/releases/download/1.8/vautour_style.zip \
    && /usr/bin/unzip -o vautour_style.zip -d ${NAGIOS_HOME}/share/ \
    && rm vautour_style.zip

RUN mkdir -p /run/nginx
RUN mkdir -p /var/log/supervisor
RUN mkdir -p /var/log/nagios
RUN mkdir -p /var/log/nagios/rrd
RUN mkdir -p /usr/local/nagios/var/spool

RUN cp /usr/share/zoneinfo/Europe/Kiev /etc/localtime
RUN /bin/echo "Europe/Kiev" >  /etc/timezone

COPY critical.wav /usr/local/nagios/share/media/
COPY warning.wav /usr/local/nagios/share/media/
COPY noproblem.wav /usr/local/nagios/share/media/
COPY hostdown.wav /usr/local/nagios/share/media/

RUN apk del tzdata perl-dev build-base linux-headers pcre-dev perl-module-build gd-dev fontconfig-dev jpeg-dev libx11-dev
RUN rm -rf /var/cache/apk/*
RUN rm -rf /etc/nginx/http.d/

COPY htpasswd.users /etc/htpasswd.users
COPY nginx.conf /etc/nginx/http.d/default.conf
COPY supervisord.conf /etc/supervisord.conf

#Next command for Windows users https://github.com/docker/for-win/issues/39
RUN sed -i '1i nagios ALL=(root)  NOPASSWD: /usr/local/nagiosgraph/bin/insert.pl ""' /etc/sudoers

RUN chown nagios:nagcmd /usr/local/nagios/var/spool
RUN chown nagios:nagcmd /usr/local/nagiosgraph -R
RUN chown nagios:nagcmd /var/log/nagios -R

EXPOSE  80/tcp

VOLUME "/usr/local/nagios/etc" "/var/log/nagios"

CMD ["supervisord", "-n", "-c", "/etc/supervisord.conf"]

