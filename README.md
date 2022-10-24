## Samba 4 AD container based on Alpine Linux

### Credits
Some parts are collected from:
* https://github.com/Osirium/docker-samba-ad-dc
* https://github.com/myrjola/docker-samba-ad-dc
* https://wiki.samba.org/index.php/Samba,_Active_Directory_%26_LDAP


### Usage

Without any config and thrown away when terminated:
```
docker run -it --rm tkaefer/alpine-samba-ad-container
```

### Environment variables

Environment variables are controlling the way how this image behaves therefore please check this list an explanation:

| Variabale | Explanation | Default |
| --- | --- | --- |
| `SAMBA_DOMAIN` | The domain name used for Samba AD | `SAMDOM` |
| `SAMBA_REALM` | The realm for authentication (eg. Kerberos) | `SAMDOM.EXAMPLE.COM` |
| `LDAP_ALLOW_INSECURE` | Allow insecure LDAP setup, by using unecrypted password. *Please use only in debug and non productive setups.* | `false` |
| `SAMBA_ADMIN_PASSWORD` | The samba admin user password  | set to `$(pwgen -cny 10 1)` |
| `KERBEROS_PASSWORD` | The kerberos password  | set to `$(pwgen -cny 10 1)` |


### Use existing data

Using (or reusing data) is done by providing
* `/etc/samba/smb.conf`
* `/etc/krb5.conf`
* `/usr/lib/samba/`
* `/var/lib/krb5kdc/`

as volumes to the docker container.

### Example

#### Plain docker
```
touch /tmp/krb-conf/krb5.conf

docker run -d -e SAMBA_DOMAIN=TEST -e SAMBA_REALM=TEST.MYDOMAIN.COM -v /tmp/smb-conf:/etc/samba -v /tmp/krb-conf/krb5.conf:/etc/krb5.conf -v /tmp/smb-data:/var/lib/samba -v /tmp/krb-data:/var/lib/krb5kdc --name smb4ad tkaefer/alpine-samba-ad-container
```

For details how to store data in directories, containers etc. please check the Docker documentation for details.

#### Docker compose

Get the `docker-compose.yaml` [file from the github repo](https://github.com/tkaefer/alpine-samba-ad-container/blob/master/docker-compose.yaml).
Copy it to an appropriate directory, do a `touch /tmp/krb-conf/krb5.conf` and run `docker-compose up -d` within that directory.

Watch the logs via `docker-compose logs -f`.

## notes
Create clean volumes
```bash
if [ -d $HOME/tmp ]; then echo "Removing tmp dir"; rm -rf $HOME/tmp; fi; \
echo "Creating tmp dir" \
&& mkdir -p $HOME/tmp/krb-conf \
&& mkdir $HOME/tmp/krb-data \
&& mkdir $HOME/tmp/smb-conf \
&& touch $HOME/tmp/krb-conf/krb5.conf \
&& docker volume rm samba-data \
&& docker volume create samba-data
```

Run an instance
```bash
docker volume create samba-data

docker run -it --rm --cap-add SYS_ADMIN \
-e SAMBA_ADMIN_PASSWORD=...secr3t... \
-e SAMBA_DOMAIN=local \
-e SAMBA_REALM=local.patodiaz.io \
-e LDAP_ALLOW_INSECURE=true \
--mount type=bind,source=$HOME/tmp/krb-conf/krb5.conf,target=/etc/krb5.conf \
--mount type=bind,source=$HOME/tmp/krb-data,target=/var/lib/krb5kdc \
--mount type=bind,source=$HOME/tmp/smb-conf,target=/etc/samba \
--mount type=volume,source=samba-data,target=/var/lib/samba \
-p 389:389 \
--name smb4ad \
padiazg/samba4dc
```