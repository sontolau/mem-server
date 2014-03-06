#!/bin/sh

DIST_TYPE=
DIST_VERSION=
OS_BITS=

check_os() {
    if [ -f "/etc/redhat-release" ]; then
        os_info=`cat /etc/redhat-release`
        DIST_TYPE=`echo $os_info | awk -F" " '{print $1;}'`
        DIST_VERSION=`echo $os_info | awk -F" " '{print $3;}' | awk -F"." '{print $1;}'`

        OS_BITS=`uname -m`
        if [ "$OS_BITS" == "x86_64" ]; then
            OS_BITS="64"
        else
            OS_BITS="32"
        fi
    fi
}

install_opensips() {
    echo "Downloading opensips for version 1.8, please stand by... ..."
    git clone https://github.com/OpenSIPS/opensips.git -b 1.8 opensips > /dev/null 2>&1

    echo "--->Installing opensips with mysql support ... ..."
    (cd opensips && \
     make include_modules="db_mysql" all && \
     make include_modules="db_mysql" install) > /dev/null 2>&1

    rm -rf opensips
}

install_asterisk() {
    echo "Downloading asterisk and dependencies... ..."
    ( wget http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz && \
      wget http://downloads.asterisk.org/pub/telephony/libpri/libpri-1.4-current.tar.gz && \
      wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-11-current.tar.gz ) > /dev/null 2>&1

    echo "--->Installing asterisk package ... ..."

    ( tar zxvf dahdi-linux-complete* && \
      tar zxvf libpri* && \
      tar zxvf asterisk* ) > /dev/null 2>&1

    ( cd dahdi-linux-complete* && \
      make && make install && make config ) > /dev/null 2>&1

    ( cd libpri* && \
      make && make install ) > /dev/null 2>&1

    ( cd asterisk* && \
      ./configure && \
      make && \
      make install && \
      make samples && \
      make config ) > /dev/null 2>&1

    rm -rf dahdi-linux-complete* libpri* asterisk*
}

if [ "$UID" -ne "0" ]; then
    echo "You must be supervisor to run it."
    exit 1
fi

check_os

echo "The server will be installed on $DIST_TYPE($DIST_VERSION)"

install_opensips
install_asterisk

if [ ! -d "/etc/aotain-mem" ]; then
    mkdir /etc/aotain-mem
fi

cp -rf templates /etc/aotain-mem/
install -m 0755 bin/AT-memctl /usr/bin/
install -m 0644 AT-mem.conf /etc/aotain-mem/
