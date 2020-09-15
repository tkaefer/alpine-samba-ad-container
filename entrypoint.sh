#!/bin/bash

set -e

SAMBA_DOMAIN=${SAMBA_DOMAIN:-SAMDOM}
SAMBA_REALM=${SAMBA_REALM:-SAMDOM.EXAMPLE.COM}
LDAP_ALLOW_INSECURE=${LDAP_ALLOW_INSECURE:-false}
SETUP_LOCK_FILE="/var/lib/samba/private/.setup.lock.do.not.remove"

if [[ $SAMBA_HOST_IP ]]; then
    SAMBA_HOST_IP="--host-ip=${SAMBA_HOST_IP}"
fi

appSetup () {
    echo "Initializing samba database..."

    SAMBA_ADMIN_PASSWORD=${SAMBA_ADMIN_PASSWORD:-$(pwgen -cny 10 1)}
    export KERBEROS_PASSWORD=${KERBEROS_PASSWORD:-$(pwgen -cny 10 1)}
    echo Samba administrator password: $SAMBA_ADMIN_PASSWORD
    echo Kerberos KDC database master key: $KERBEROS_PASSWORD

    # Provision Samba
    rm -f /etc/samba/smb.conf
    rm -rf /var/lib/samba/*
    mkdir -p /var/lib/samba/private
    samba-tool domain provision \
      --use-rfc2307 \
      --domain=$SAMBA_DOMAIN \
      --realm=$SAMBA_REALM \
      --server-role=dc\
      --dns-backend=BIND9_DLZ \
      --adminpass=$SAMBA_ADMIN_PASSWORD \
      $SAMBA_HOST_IP
    cat /var/lib/samba/private/krb5.conf > /etc/krb5.conf
    if [ "${LDAP_ALLOW_INSECURE,,}" == "true" ]; then
	     sed -i '/\[global\]/a # enable unencrypted passwords \
         ldap server require strong auth = no' /etc/samba/smb.conf
	fi
    # Create Kerberos database
    expect kdb5_util_create.expect

    # Export kerberos keytab for use with sssd
    if [ "${OMIT_EXPORT_KEY_TAB}" != "true" ]; then
        samba-tool domain exportkeytab /etc/krb5.keytab --principal ${HOSTNAME}\$
    fi

    touch "${SETUP_LOCK_FILE}"
}

appStart () {
    if [ ! -f "${SETUP_LOCK_FILE}" ]; then
      appSetup
    fi
    /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
}

appHelp () {
	echo "Available options:"
	echo " app:start          - Starts all services needed for Samba AD DC"
	echo " app:setup          - First time setup."
	echo " app:setup_start    - First time setup and start."
	echo " app:help           - Displays the help"
	echo " [command]          - Execute the specified linux command eg. /bin/bash."
}

case "$1" in
	app:start)
		appStart
		;;
	app:setup)
		appSetup
		;;
	app:setup_start)
		appSetup
		appStart
		;;
	app:help)
		appHelp
		;;
	*)
		if [ -x $1 ]; then
			$1
		else
			prog=$(which $1)
			if [ -n "${prog}" ] ; then
				shift 1
				$prog $@
			else
				appHelp
			fi
		fi
		;;
esac

exit 0
