#!/bin/bash
set -e -u -x

# Save dpkg setup for an existing system in Git history, to possibly be restored at a later point.

name=${1-}
tgt=dpkg-backup/${name}

cd $(dirname $BASH_SOURCE)

if [[ -z "${name}" ]]; then
    dpkg-query -f='${PackageSpec;-60}\t${Architecture;-10}\t${Version;-30}\t${Source}\n' -W "*" > dpkg.txt
    cp ~/.bash_history bash_history
fi

# http://askubuntu.com/questions/9135/how-to-backup-settings-and-list-of-installed-packages
mkdir -p $tgt
(
    cd $tgt
    dpkg --get-selections > ./package.list
    cp -R /etc/apt/sources.list* ./
    apt-key exportall > ./repo.keys
    dconf dump / > ./dconf.db
)

<<RESTORE
sudo apt-key add ./repo.keys
sudo cp -R ./sources.list* /etc/apt/
sudo apt-get update
sudo apt-get install dselect
sudo dselect update
sudo dpkg --set-selections < ./package.list
sudo apt-get dselect-upgrade -y

apt-cache dumpavail > ~/temp_avail
sudo dpkg --merge-avail ~/temp_avail
rm ~/temp_avail

dconf load < ./dconf.db
RESTORE
