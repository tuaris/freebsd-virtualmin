# FreeBSD Install Script for Virtualmin

## Still under active development.

This install script works best with a clean system.  It automaitcly disables standard FreeBSD
PKG repositories and sets up custom PKG repos.  

![](http://phobos.morante.net/downloads/unibia/screenshots/virtualmin-5.png "Virtualmin on FreeBSD")

## Try it out

```
fetch -o - http://ftp.morante.net/pub/FreeBSD/extra/virtualmin/install.sh | sh
```

### What works

- BIND DNS server
- Apache web server, suEXEC
- PHP (mod_php, FCGId)
- Postfix and Dovecot mail system
- MySQL and Postgresql
- Usermin

### Not Tested, but should work

- Mod_perl CGI
- SSL Websites (needs to be enabled manaully)
- FTP
- Script Installers
- Webalizer
- Mail client Autoconfiguration

### Not Working

- Spam and Virus Filtering
- Procmail
- DomainKeys, SPF, Greylisting
- Mail Rate Limiting
- Mailing lsits (mailman)

## Kown Issues

If you are unable to sign into Webmin due to a rejected password, you can manually reset the password with:

```
/usr/local/lib/webmin/changepass.pl /usr/local/etc/webmin admin <newpass>
```

This has been known to occur when there are no user accounts (other than root) invited to the `wheel` group.  

To add an existing account to the `wheel` group:

```
pw groupmod wheel -m <user>
```

If you did not create a standard user account during the FreeBSD installation, you can use the `adduser` command to create one:

```
adduser

Username: admin
Full name: Administrator
Uid (Leave empty for default):
Login group [admin]:
Login group is admin. Invite admin into other groups? []: wheel
Login class [default]:
Shell (sh csh tcsh nologin) [sh]:
Home directory [/home/admin]:
Home directory permissions (Leave empty for default):
Use password-based authentication? [yes]:
Use an empty password? (yes/no) [no]:
Use a random password? (yes/no) [no]:
Enter password:
Enter password again:
Lock out the account after creation? [no]:
Username   : admin
Password   : *****
Full Name  : Administrator
Uid        : 1001
Class      :
Groups     : admin wheel
Home       : /home/admin
Home Mode  :
Shell      : /bin/sh
Locked     : no
OK? (yes/no): yes
adduser: INFO: Successfully added (admin) to the user database.
Add another user? (yes/no): no
Goodbye!
```
