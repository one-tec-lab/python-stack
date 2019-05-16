#!/bin/bash
#Run this commands on remote cost where stackbuilder will be installed

function create_user {
    local new_user=$1

    sudo adduser $new_user
    sudo usermod -aG sudo $new_user

    cd /home/$new_user
    mkdir /home/$new_user/.ssh
    touch /home/$new_user/.ssh/authorized_keys
    sudo chmod 600 /home/$new_user/.ssh/authorized_keys
    sudo chown -R $new_user:$new_user /home/$new_user
}

function info {
  echo "Remote testing"
  echo "system : $(uname)"
  echo "User : $(whoami)"
  echo -n "hostname : "
  cat /etc/hostname
  echo "folder : $(pwd)"
}

if [ -z $1 ];then
  echo "Sourced"
else
  $@
fi
