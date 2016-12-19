FROM alpine:3.4
MAINTAINER Tobias Kaefer tobias+dckrsmb@tkaefer.de

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
    python-dev \
    linux-pam-dev \
    py-pip \
    popt-dev \
    openldap-dev \
    libbsd-dev \
    cups-dev \
    ca-certificates \
    py-certifi \
    rsyslog \
    expect \
    tdb \
    tdb-dev \
    py-tdb \
    && \
    rm -rf /var/cache/apk/*

RUN pip install dnspython
RUN pip install

ADD kdb5_util_create.expect kdb5_util_create.expect
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh
VOLUME ["/etc/samba", "/var/lib/samba", "/var/run/samba"]
EXPOSE 22 53 389 88 135 139 138 445 464 3268 3269
ENTRYPOINT ["/entrypoint.sh"]
CMD ["app:start"]
