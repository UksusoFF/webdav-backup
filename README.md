# webdav-backup

Bash script for create MySQL/PostgreSQL and files dump and upload them via to WebDAV server.

## Install 

1. Create config.sh and include.list files

2. Add `crontab -e` config:
```
MAILFROM=backup@example.ru
MAILTO=user@example.ru
0 3 * * * /paht/to/repository/run.sh
```

3. Install `apt-get install ssmtp` and create `/etc/ssmtp/ssmtp.conf`:
```
root=backup@example.ru
mailhub=smtp.yandex.ru:465
AuthUser=backup@example.ru
AuthPass=your-password-here
AuthMethod=LOGIN
FromLineOverride=NO
UseTLS=YES
```

`/etc/ssmtp/revaliases`:
```
root:backup@example.ru:smtp.yandex.ru:465
```
