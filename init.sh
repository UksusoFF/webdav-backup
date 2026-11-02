git init
git remote add origin https://github.com/UksusoFF/webdav-backup
git fetch
git reset origin/master
git checkout -t origin/master
git branch --set-upstream-to=origin/master master
