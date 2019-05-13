#!/bin/bash

################################################################
# Script_Name : stackbuilder.sh
# Description : Build stack for application deployment.

# Compatibulity : ubuntu 18.04.1 and later
# Date : May 4th, 2019
# written by : Tadeo Gutierrez
# 
# Version : SB_VERSION export
# History : 0.3 - sourced by .bashrc

# 0.1 - Initial Script
# Disclaimer : Script provided AS IS. Use it at your own risk.
# Licence : MIT
##################################################################

export SB_VERSION="4.1.1"

validbash=0
os=${OSTYPE//[0-9.-]*/}
echo "Stackbuilder v $SB_VERSION $(date -r stackbuilder.sh '+%m-%d-%Y %H:%M:%S')"
case "$os" in
  darwin)
    echo "I'm in a Mac"
    validbash=1
    ;;

  msys)
    echo "I'm in Windows using git bash"
    validbash=1
    ;;

  linux)
    echo "I'm in Linux"
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
      #add source line if not in .bashrc
      grep -qxF 'source stackbuilder.sh' ~/.bashrc || echo 'source stackbuilder.sh' >> ~/.bashrc
      source ./stackbuilder.sh 
   else
    echo "You need to be inside a valid stackbuilder project and bash terminal"
   fi
   echo "Stack utilities updated to $SB_VERSION"
}

function stackb {
  local current_dir=$(pwd)
  local full_params=$@
  local stackdomain=""
  local default_host="localhost"
  local default_admin_user="admin"
  local sb_db_sec_0=""
  local sb_db_sec_1=""
  local sb_db_sec_0_def="ch4ng3m3"
  local password2=""
  local admin_mail=""
  local first_run=1
  local spec_container=""
  local spec_params=""
  local compose_cmd="up -d"
  echo "Executing : stackb $full_params"
  if [ -f .stack.env ]; then
    echo "Using .stack.env"
    source .stack.env
    first_run=0
  else 
    first_run=1
  fi

  # Get script arguments for non-interactive mode
  while [ "$1" != "" ]; do
      case $1 in
          -b | --bash )
              shift
              local sb_container="$1"
              echo "Connecting bash to container [$sb_container]. Type 'exit' to quit"
              docker-compose exec $sb_container bash
              return
              ;;
          -l | --logs )
              shift
              local sb_container="$@"
              local log_str=docker-compose logs $sb_container
              echo $log_str
              return
              ;;
          --mysqlrootpwd )
              shift
              sb_db_sec_0="$1"
              ;;
          --dbuserpwd )
              shift
              sb_db_sec_1="$1"
              ;;
          elk )
              shift
              local elk_cmd="$@"
              local elk_file_name=".elk.stack.env"
              if [ "$elk_cmd" == "up" ] || [ -z  "$elk_cmd"  ]; then
                elk_cmd="up -d"
              fi
              cd docker-elk
              docker-compose $elk_cmd 
              if [ -f $elk_file_name ]; then
                echo "elk firs time run"
                stack-wait-log elasticsearch "Quit the server with CONTROL-C"
                #docker-compose exec -T elasticsearch 'bin/elasticsearch-setup-passwords' auto --batch >> $elk_file_name
                cat $elk_file_name
              fi
              cd $current_dir
              return 
              ;;
          --tools )
              cd stackb-dev
              docker-compose up -d
              cd $current_dir
              return 
              ;;
          --prod )
              cd stackb-dev
              docker-compose down 
              cd $current_dir
              return 
              ;;          
          -d | --domain )
              shift
              stackdomain="$1"
              ;;
          -z | --down )
              compose_cmd="down"
              spec_container="$2"
              if [ "$spec_container" == "-"* ] || [ -z  "$spec_container"  ]; then
                echo "all containers"
                spec_container=""
              else
                shift
              fi              
              ;;            
          down )
              compose_cmd="down"
              shift
              spec_container="$@"
              ;;
          stop )
              compose_cmd="stop"
              shift
              spec_container="$@"
              ;;              
          up )
              compose_cmd="up -d"
              shift
              spec_container="$@"
              ;;
          build )
              stack-build
              ;;
          recreate )
              shift
              spec_container="$@"
              spec_params="--no-deps --build"
              docker-compose stop $spec_container
              docker-compose rm -f $spec_container
              ;;
          --prune_all ) 
              stack-clean-all
              return
              ;;
      esac
      shift
  done

  if [ -z  $sb_db_sec_0  ] || [ $first_run == 1 ];then
    while true
    do
        read -s -p "Enter a MySQL ROOT Password: " sb_db_sec_0
        sb_db_sec_0="${sb_db_sec_0:-$sb_db_sec_0_def}"
        echo
        read -s -p "Confirm MySQL ROOT Password: " password2
        password2="${password2:-$sb_db_sec_0_def}"
        echo
        [ "$sb_db_sec_0" = "$password2" ] && break
        echo "Passwords don't match. Please try again."
        echo
    done
    echo
  fi
  if [[ -z  $sb_db_sec_1  ]];then
    while true
    do
        read -s -p "Enter a database user Password: " sb_db_sec_1
        sb_db_sec_1="${sb_db_sec_1:-$sb_db_sec_0_def}"
        echo
        read -s -p "Confirm database user Password: " password2
        password2="${password2:-$sb_db_sec_0_def}"
        echo
        [ "$sb_db_sec_1" = "$password2" ] && break
        echo "Passwords don't match. Please try again."
        echo
    done
    echo
  fi

  if [[ -z  $admin_user  ]];then
    while true
    do
        read  -p "Provide an admin user name (default: [$default_admin_user]): "  admin_user  
        admin_user="${admin_user:-$default_admin_user}"
        echo
        [ -z "$admin_user" ] && echo "Please provide an admin user name" || break
        echo
    done
  fi

  if [[ -z  $stackdomain  ]];then
    while true
    do
        read  -p "Provide a DOMAIN (default: [$default_host]): "  stackdomain  
        stackdomain="${stackdomain:-$default_host}"
        echo
        [ -z "$stackdomain" ] && echo "Please provide a DOMAIN" || break
        echo
    done
  fi
  if [[ -z  $admin_mail  ]];then
    while true
    do
        read  -p "Provide admin E-MAIL (ENTER for admin@mail.com): "  
        admin_mail="${admin_mail:-admin@mail.com}"
        echo
        [ -z "$admin_mail" ] && echo "Please provide a valid mail for certs" || break
        echo
    done
    echo
  fi


  cd $current_dir

  if [ $first_run == 1 ]; then
    echo "stackdomain=$stackdomain" >> ./.stack.env
    echo "sb_db_sec_0=$sb_db_sec_0" >> ./.stack.env
    echo "sb_db_sec_1=$sb_db_sec_1" >> ./.stack.env
    echo "admin_user=$admin_user" >> ./.stack.env
    echo "admin_mail=$admin_mail" >> ./.stack.env

    echo "First Run Configuration..."
    STACK_MAIN_DOMAIN=$stackdomain \
    SB_MYSQL_ROOT_PASSWORD=$sb_db_sec_0 \
    SB_MYSQL_PASSWORD=$sb_db_sec_1 \
    SB_RDS_PASSWORD=$sb_db_sec_1 \
    CURRENT_UID=$(id -u):$(id -g) \
    docker-compose up -d --build
    # Sleep to let MySQL load (there's probably a better way to do this)
    echo
    echo "Connecting app to DB for first time. Please wait..."

    stack-wait-log app "Quit the server with CONTROL-C"

    echo "Creating Django Admin user"
    docker-compose exec app python3 manage.py createsuperuser --username $admin_user  --noinput --email "$admin_mail"
    docker-compose exec app python3 manage.py changepassword $admin_user
    
  else
    echo "EXECUTING Compose Params:[${spec_params:-default}] Container(s):[${spec_container:-all}]"
    STACK_MAIN_DOMAIN=$stackdomain \
    SB_MYSQL_PASSWORD=$sb_db_sec_1 \
    SB_RDS_PASSWORD=$sb_db_sec_1 \
    CURRENT_UID=$(id -u):$(id -g) \
    docker-compose $compose_cmd $spec_params $spec_container

  fi
  echo "Stackb completed."

}

function stack-wait-log {
  local stack_service="$1"
  local log_str="$2"
  local step_count=1 
  echo "service: [$stack_service] waiting for: [$log_str]"   
  while true
  do
    ##wait for app server logs to contain message = "Quit the server with CONTROL-C"
    echo "Step $step_count : Reading logs... "
    echo "Reading logs"
    local app_log=$(docker-compose logs $stack_service 2>&1 | grep "$log_str")
    if [ ${#app_log} -ne 0 ];then 
      echo "App server Ready. Waiting for container (5 secs)..."
      tickforseconds 10
      break
    else 
      tickforseconds 20
      step_count=$(( $step_count + 1 ))
    fi
  done
}

function stack-log {
  local log_entry="$@"
  echo $log_entry >> ./logs/stackb.log
}
function echoline {
  echo "-----------------------------------------------------------------------"
}
function tickforseconds {
  local tick=1
  local wait_seconds=$1
  while true
  do
    sleep 1
    echo  -ne "."
    if [ $tick -gt $wait_seconds ]; then
      break
    fi
    tick=$(( $tick + 1 ))
  done
  echo

}

function stack-traefik-configure {
  local comment_acme_staging=" "
  local comment_redirect="#"
  local comment_acme="#"
  local stackdomain=$(readvaluefromfile stackdomain .stack.env)
  local admin_mail=$(readvaluefromfile admin_mail .stack.env)

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
$comment_acme   email = "$admin_mail"
$comment_acme   storage = "acme/certs.json"
$comment_acme   entryPoint = "https"
$comment_acme   onHostRule = true
$comment_acme   [acme.httpChallenge]
$comment_acme      entryPoint = "http"
EOF
addreplacevalue "ALLOWED_HOSTS =" "ALLOWED_HOSTS = ['$stackdomain','127.0.0.1']" ./app/project/settings.py
}

function stack-domain-configure {
  while [ "$1" != "" ]; do
      case $1 in
          -m | --mysqlrootpwd )
              shift
              sb_db_sec_0="$1"
              ;;
          -a | --apidbpwd )
              shift
              apidbpwd="$1"
              ;;
          -d | --domain )
              shift
              $stackdomain="$1"
              ;;
      esac
      shift
  done  
}

function stack-nginx-self-cert {
  local param_subj="$2"
  local param_domain="$1"

  #local env_domain=$(readvaluefromfile stackdomain .stack.env)
  local subj_str="/C=US/ST=CA/L=SF/O=Dis/CN=$param_domain"
  if [[ !  -z  $param_subj  ]];then
    subj_str="$param_subj"
  fi
  echo "Creating self-signed certificate for $param_domain"
  echo "Subject: $subj_str" 
  docker-compose exec -u 0 nginx-proxy bash -c "openssl req -x509 -nodes -days 1000 -newkey rsa:2048 -subj '$subj_str' -keyout /opt/bitnami/certs_stack/nginx-selfsigned.key -out /opt/bitnami/certs_stack/nginx-selfsigned.crt"
  addreplacevalue "ssl_certificate /opt/bitnami/certs" "ssl_certificate /opt/bitnami/certs_stack/nginx-selfsigned.crt;" ./nginx/sb_block.conf
  addreplacevalue "ssl_certificate_key /opt/bitnami/certs" "ssl_certificate_key /opt/bitnami/certs_stack/nginx-selfsigned.key;" ./nginx/sb_block.conf
  addreplacevalue "#sb_replace_sb_domain" "server_name $param_domain www.$param_domain; #sb_replace_sb_domain" ./nginx/sb_block.conf
  #echo "Creating Diffie-Helman dhparam"
  #docker-compose exec nginx-proxy exec -u 0 nginx-proxy bash -c "openssl dhparam -out /opt/bitnami/certs_stack/dhparam.pem 2048"
  addreplacevalue "ssl_dhparam /opt/bitnami/certs" "#ssl_dhparam /opt/bitnami/certs_stack/dhparam.pem;" ./nginx/sb_block.conf

}

function stack-nginx-default-conf {
  addreplacevalue "ssl_dhparam /opt/bitnami/certs" "#ssl_dhparam /opt/bitnami/certs/dhparam.pem;" ./nginx/sb_block.conf
  addreplacevalue "ssl_certificate /opt/bitnami/certs" "ssl_certificate /opt/bitnami/certs/server.crt;" ./nginx/sb_block.conf
  addreplacevalue "ssl_certificate_key /opt/bitnami/certs" "ssl_certificate_key /opt/bitnami/certs/server.key;" ./nginx/sb_block.conf
}

function stack-build {
    #docker-compose run app django-admin startproject project .
    #docker-compose down --remove-orphans
    docker-compose build
}
function stack-clean-all {
  local confirm_action=""
  echo "CAUTION: This action will delete all containes and data volumes"
  echo
  read  -p "Are you sure you want to delete all containters and data? (y/N) "  confirm_action  
  confirm_action="${confirm_action:-n}"

  if [ "$confirm_action" == "y" ];then
    docker-compose down
    rm -rf .stack.env
    docker system prune --all --force --volumes
  fi
}

function readvaluefromfile {
   local file="$2"
   local label="$1"

   local listalineas=""
   local linefound=0
   local value_found=""       
   local listalineas=$(cat $file)
   if [[ !  -z  $listalineas  ]];then
     #echo "buscando lineas existentes con:"
     #echo "$nuevacad"
     #$usesudo >$temporal
     while read -r linea; do
     #strip spaces
     clean_line=${linea//[[:blank:]]/}
     if [[ $clean_line == *"$label="* ]];then
       #echo "... $linea ..."
       value_found=${linea#*=}
       linefound=1
     fi
     done <<< "$listalineas"

   fi

   echo $value_found
}  

function addreplacevalue {

   local usesudo="$4"
   local archivo="$3"
   local nuevacad="$2"
   local buscar="$1"
   local temporal="$archivo.sb.tmp"
   local listalineas=""
   local linefound=0       
   local listalineas=$(cat $archivo)
   if [[ !  -z  $listalineas  ]];then
     #echo "buscando lineas existentes con:"
     #echo "$nuevacad"
     #$usesudo >$temporal
     while read -r linea; do
     if [[ $linea == *"$buscar"* ]];then
       #echo "... $linea ..."
       if [ ! "$nuevacad" == "_DELETE_" ];then
          ## just add new line if value is NOT _DELETE_
          echo $nuevacad >> $temporal
       fi
       linefound=1
     else
       echo $linea >> $temporal

     fi
     done <<< "$listalineas"

     cat $temporal > $archivo
     rm -rf $temporal
   fi
   if [ $linefound == 0 ];then
     echo "Adding new value to file: $nuevacad"
     echo $nuevacad>>$archivo
   fi
}