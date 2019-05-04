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
export CONTAINER_STACK_VER="4.1"
validbash=0
os=${OSTYPE//[0-9.-]*/}

case "$os" in
  darwin)
    echo "I'm a Mac"
    validbash=1
    ;;

  msys)
    echo "I'm Windows using git bash"
    validbash=1
    ;;

  linux)
    echo "I'm Linux"
     validbash=1
   ;;
  *)

  echo "Unknown Operating system $OSTYPE"
  exit 1
esac




function update-stackbuilder {
   
   git fetch --all
   git reset --hard origin/master
   git pull origin master
   if [ -f stackbuilder.sh ] && [ validbash=1 ]; then 
      echo "updating stackbuilder script for bash"
      cat ./stackbuilder.sh > ~/stackbuilder.sh
      grep -qxF 'source ~/stackbuilder.sh' ~/.bashrc || echo 'source ~/stackbuilder.sh' >> ~/.bashrc
      source ./stackbuilder.sh 
   else
    echo "You need to be inside a valid stackbuilder project and bash terminal"
   fi
   echo "Stack utilities updated to $CONTAINER_STACK_VER"
}

function stack-up {
  comment_acme_staging=" "
  comment_redirect="#"
  comment_acme="#"
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
       mysqlrootpassword="${mysqlrootpassword:-changeme}"
       echo
       read -s -p "Confirm MySQL ROOT Password: " password2
       password2="${password2:-changeme}"
       echo
       [ "$mysqlrootpassword" = "$password2" ] && break
       echo "Passwords don't match. Please try again."
       echo
    done
    echo
    while true
    do
       read -s -p "Enter a database user Password: " dbuserpassword
       dbuserpassword="${dbuserpassword:-changeme}"
       echo
       read -s -p "Confirm database user Password: " password2
       password2="${password2:-changeme}"
       echo
       [ "$dbuserpassword" = "$password2" ] && break
       echo "Passwords don't match. Please try again."
       echo
    done
    echo


    while true
    do
        read  -p "Enter DOMAIN (ENTER for 'localhost'): "  stackdomain  
        stackdomain="${stackdomain:-localhost}"
        echo
        [ -z "$stackdomain" ] && echo "Please provide a DOMAIN" || break
        echo
    done

    echo "STACK_MAIN_DOMAIN=$stackdomain" > ./.env

    while true
    do
        read  -p "Enter E-MAIL for certificates notifications (ENTER for admin@mail.com): "  
        certs_mail="${certs_mail:-admin@mail.com}"
        echo
        [ -z "$certs_mail" ] && echo "Please provide a valid mail for certs" || break
        echo
    done

    bash -c "cat > ./proxy/traefik.toml" <<-EOF
debug = false
logLevel = "ERROR"
defaultEntryPoints = ["https","http"]
[entryPoints]
  [entryPoints.http]
      address = ":80"
      $comment_redirect [entryPoints.http.redirect]
      $comment_redirect   entryPoint = "https"
  [entryPoints.https]
      address = ":443"
      [entryPoints.https.tls]
[retry]
[docker]
endpoint = "unix:///var/run/docker.sock"
domain = "$stackdomain"
watch = true
exposedByDefault = false
$comment_acme [acme]
$comment_acme  $comment_acme_staging caServer = "https://acme-staging-v02.api.letsencrypt.org/directory"
$comment_acme   email = "$certs_mail"
$comment_acme   storage = "acme/certs.json"
$comment_acme   entryPoint = "https"
$comment_acme   onHostRule = true
$comment_acme   [acme.httpChallenge]
$comment_acme      entryPoint = "http"
EOF

    
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
