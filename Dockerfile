FROM ubuntu:16.10

MAINTAINER TRAN Alexandre

ENV DEBIAN_FRONTEND noninteractive

RUN apt update && \
        apt upgrade -y && \
        apt dist-upgrade -y && \
        apt install -q -y gnupg2 dirmngr vim dialog mc lynx apt-utils && \
        apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E5267A6C && \
        apt update && \
        apt install -y python-software-properties software-properties-common build-essential && \
        LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php && \
        apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E1DF1F24 && \
        LC_ALL=C.UTF-8 add-apt-repository ppa:git-core/ppa && \
        apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8

RUN echo 'deb [arch=amd64,i386] http://fr.mirror.babylon.network/mariadb/repo/10.0/ubuntu yakkety main' > /etc/apt/sources.list.d/mariadb.list
RUN echo 'deb-src http://fr.mirror.babylon.network/mariadb/repo/10.0/ubuntu yakkety main' >> /etc/apt/sources.list.d/mariadb.list

RUN apt update && \
        apt dist-upgrade -y && \
        apt install -y git

RUN apt install -q -y language-pack-en language-pack-fr

RUN apt install -y php7.1 libapache2-mod-php7.1 php7.1-mysql php7.1-cli php7.1-gd php7.1-imap php7.1-curl \
        php7.1-dev php7.1-json php7.1-mbstring php7.1-mcrypt php7.1-opcache php7.1-readline php7.1-xml php7.1-intl \
        php7.1-sybase php7.1-bz2 composer memcached php-memcache php-memcached libapache2-mod-rpaf && \
        apt-get install -y htop mutt locate && \
        apt-get install -y --fix-missing monit cron

RUN apt install -y --no-install-recommends munin-node munin-plugins-extra

RUN apt install -y make gcc telnet mtr wget dnsutils net-tools mime-construct

RUN apt install -y mariadb-server

RUN apt install -y rsyslog

RUN apt install -y postfix

RUN \
  sed -ri 's/^log_file.*/# \0/; \
           s/^pid_file.*/# \0/; \
           s/^background 1$/background 0/; \
           s/^setsid 1$/setsid 0/; \
          ' /etc/munin/munin-node.conf && \
  /bin/echo -e "cidr_allow 192.168.0.0/16\ncidr_allow 172.16.0.0/12\ncidr_allow 10.0.0.0/8" >> /etc/munin/munin-node.conf

RUN apt install incron

RUN rm /etc/incron.allow

RUN apt-get autoremove && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* && \
        rm -rf /var/cache/apt/archives/*

RUN echo "export HISTFILESIZE=" >> /root/.bashrc
RUN echo "export HISTSIZE=" >> /root/.bashrc
RUN echo "export HISTTIMEFORMAT=\"[%F %T] \"" >> /root/.bashrc
RUN echo "export HISTFILE=/var/log/bash_eternal_history_$(id -u -n)" >> /root/.bashrc
RUN echo "PROMPT_COMMAND=\"history -a; $PROMPT_COMMAND\"" >> /root/.bashrc

ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN updatedb

RUN dircolors -p > /root/.dircolors

RUN echo "colorscheme desert" >> /etc/vim/vimrc

RUN sed -i 's/DIR 01;34/DIR 01;34;47/g' /root/.dircolors

RUN /bin/rm /var/www/html/index.html
RUN /bin/rm -rf /var/log/*.log
RUN /bin/rm /var/log/apt/*

RUN echo '<?php\n\
echo date("d/m/Y H:i:s");\n\
phpinfo();\n'\
>> /var/www/html/index.php

RUN /bin/bash -c "/usr/bin/mysqld_safe &" && \
  sleep 5 && \
  mysql -u root -e "grant all privileges on *.* to 'atran'@'192.168.%' identified by 'atran' with grant option;"

RUN sed -i "s/bind-address.*/#bind-address = 127.0.0.1/" /etc/mysql/my.cnf

RUN postconf compatibility_level=2

RUN echo '#!/bin/bash \n\
/etc/init.d/cron start \n\
/etc/init.d/mysql start \n\
service rsyslog start \n\
service postfix start \n\
service incron start \n\
/bin/sh -c "munin-node-configure --remove --shell | sh; exec /usr/sbin/munin-node --config /etc/munin/munin-node.conf" & \n\
/usr/sbin/apache2ctl -D FOREGROUND &\n\
while true; do sleep 500; done \n'\
>> /root/startup.sh

CMD ["/bin/bash", "/root/startup.sh"]
