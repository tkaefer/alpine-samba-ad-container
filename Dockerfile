FROM alpine:3.15
MAINTAINER Patricio Diaz padiazg@gmail.com

ENV TERM=xterm-color
RUN apk --update add \
    bash \
    samba-dc \
    krb5-server \
    supervisor \
    bind \
    bind-tools \
    pwgen \
    acl-dev \
    attr-dev \
    blkid \
    gnutls-dev \
    readline-dev \
    python3-dev \
    linux-pam-dev \
    py3-pip \
    popt-dev \
    openldap-dev \
    libbsd-dev \
    cups-dev \
    ca-certificates \
    py3-certifi \
    rsyslog \
    expect \
    tdb \
    tdb-dev \
    py3-tdb \
    acl \
    && \
    rm -rf /var/cache/apk/*

RUN pip3 install dnspython

ADD kdb5_util_create.expect kdb5_util_create.expect
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD named.conf /etc/bind/named.conf
ADD named.conf.options /etc/bind/named.conf.options

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

EXPOSE 22 53 389 88 135 139 138 445 464 3268 3269
ENTRYPOINT ["/entrypoint.sh"]
CMD ["app:start"]
