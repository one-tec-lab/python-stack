#!/bin/bash

################################################################
# Script_Name : stackbuilder.sh
# Description : Perform an automated standard installation
# of a container stack environment 
# on ubuntu 18.04.1 and later
# Date : may 2019
# written by : tadeo
# 
# Version : 4.0
# History : 0.3 - sourced by .bashrc

# 0.1 - Initial Script
# Disclaimer : Script provided AS IS. Use it at your own risk....
##################################################################
export CONTAINER_STACK_VER="4.0"
os=${OSTYPE//[0-9.-]*/}

case "$os" in
  darwin)
    echo "I'm a Mac"
    ;;

  msys)
    echo "I'm Windows using git bash"
    ;;

  linux)
    echo "I'm Linux"
    ;;
  *)

  echo "Unknown Operating system $OSTYPE"
  exit 1
esac


function update-stackbuilder {
   
   git fetch --all
   git reset --hard origin/master
   git pull origin master
   

   echo "Stack utilities updated to $CONTAINER_STACK_VER"
}

function stack-up {
   # Get script arguments for non-interactive mode
    while [ "$1" != "" ]; do
       case $1 in
           -m | --mysqlrootpwd )
               shift
               mysqlrootpwd="$1"
               ;;
           -a | --apidbpwd )
               shift
               apidbpwd="$1"
               ;;
           -d | --domain )
               shift
               $domain_name="$1"
               ;;

       esac
       shift
    done
  
    while true
    do
       read -s -p "Enter a MySQL ROOT Password: " mysqlrootpassword
       echo
       read -s -p "Confirm MySQL ROOT Password: " password2
       echo
       [ "$mysqlrootpassword" = "$password2" ] && break
       echo "Passwords don't match. Please try again."
       echo
    done
    echo
    while true
    do
       read -s -p "Enter a database user Password: " dbuserpassword
       echo
       read -s -p "Confirm database user Password: " password2
       echo
       [ "$dbuserpassword" = "$password2" ] && break
       echo "Passwords don't match. Please try again."
       echo
    done
    echo
    
    
    MYSQL_ROOT_PASSWORD=$mysqlrootpassword \
    MYSQL_PASSWORD=$dbuserpassword \
    RDS_PASSWORD=$dbuserpassword \
    CURRENT_UID=$(id -u):$(id -g) \
    docker-compose up -d

}

function stack-build {
    docker-compose run app django-admin startproject project .
    docker-compose down --remove-orphans

}
