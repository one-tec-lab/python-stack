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

SB_VERSION="4.1.5"
SB_VERSION_DATE=""
SB_PROJECT="$(basename $(pwd))"
SB_COMPOSE_CMD="sudo docker-compose"
SB_DOCKER_CMD="sudo docker"
validbash=0
full_os=${OSTYPE}
os=${OSTYPE//[0-9.-]*/}
if [ -f stackbuilder.sh ];then
  SB_VERSION_DATE="$(date -r stackbuilder.sh '+%m-%d-%Y %H:%M:%S')"
fi
echo "Stackbuilder v $SB_VERSION $SB_VERSION_DATE"

echo "PROJECT [ $SB_PROJECT ] $(get_source_dir)"
case "$os" in
  darwin)
    echo "I'm in a Mac"
    validbash=1
    ;;

  msys)
    echo "I'm in Windows using git bash"
    SB_COMPOSE_CMD="docker-compose"
    SB_DOCKER_CMD="docker"
    validbash=1
    ;;

  linux)
    echo "I'm in Linux : $full_os"
     validbash=1
   ;;
  *)

  echo "Unknown Operating system $OSTYPE"
  exit 1
esac

function get-source-dir {
  local SOURCE="${BASH_SOURCE[0]}"
  local DIR=""
  while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  done
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  echo "$DIR"
}

function sb-rancher {
  local cmd_str="$SB_DOCKER_CMD run -d --name=sb_rancher --restart=unless-stopped -p 80:80 -p 443:443 rancher/rancher "
  echo $cmd_str
  $cmd_str
}


function remote-host {
    local host_config_id=$1
    shift
    local cmd_str=$@
    if [[ -z  $host_config_id  ]];then
      create-host-config
    else
      local config_str=$(readvaluefromfile $host_config_id stack_hosts.conf)
      if [[ -z  $config_str  ]];then
        echo "Must specify a valid host configuration:"
        echo "-----------------------------------------"
        cat stack_hosts.conf
        echo "-----------------------------------------"
      else
        echo "Stackbuilder will execute at $config_str "
        case $cmd_str in
          setup-ubuntu)
            echo $cmd_str
            if [ ! -f ~/.ssh/id_rsa.pub ];then
              echo "Must generate ssh keys localy"
              ssh-keygen -t rsa -b 4096
            fi
            if [ -f ~/.ssh/id_rsa.pub ];then
              echo "Copying keys to remote server"
              ssh-copy-id $config_str
              run-on-host $host_config_id ./lib/sb_remote.sh setup-ubuntu
            else
              echo "No public key found (must have ssh and ssh-keygen installed"
            fi      
            ;;
          *)
            echo $cmd_str
            run-on-host $host_config_id $cmd_str
            ;;
          "")
            echo "command empty"
            ;;
        esac
  
      fi
    fi 
}


function create-host-config {
  local config_title=$1
  local host_str=$2
  local user_str=$3  
  if [[ -z  $config_title  ]];then
    while true
    do
        read  -p "Provide a name for host configuration (ctrl+c to cancel) : "  config_title  
        echo
        [ -z "$config_title" ] && echo "Please provide a name for host configuration : " || break
        echo
    done
  fi
  if [[ -z  $host_str  ]];then
    while true
    do
        read  -p "Provide a host name or IP for connection (ctrl+c to cancel) : "  host_str  

        echo
        [ -z "$host_str" ] && echo "Please provide a host name or IP for connection : " || break
        echo
    done
  fi
  if [[ -z  $user_str  ]];then
    while true
    do
        read  -p "Provide a user name for connection (ctrl+c to cancel) : "  user_str  

        echo
        [ -z "$user_str" ] && echo "Please provide a user name for connection : " || break
        echo
    done
  fi
  if [[ -z  $config_title  ]] || [[ -z  $host_str  ]] || [[ -z  $user_str  ]];then
    echo "Must provide a config title, host/IP and user name to configure ssh connection. CANCELED"
    return
  else

    addreplacevalue "$config_title =" "$config_title = $user_str@$host_str" stack_hosts.conf
  fi
  echo $config_title
}

function run-on-host {
  local host_config_id=$1
  shift
  local param_str=$@
  local config_str=$(readvaluefromfile $host_config_id stack_hosts.conf)
  local user_str=$(echo $config_str | cut -d'@' -f 1)
  local host_str=$(echo $config_str | cut -d'@' -f 2)
  run-remote-script $user_str $host_str $param_str
}
function run-remote-script {
# run-remote-script stackbuilder ip_address ./lib/sb_remote.sh bash
  local user=$1
  local host=$2
  local realscript=$3
  shift 3

  # escape the arguments
  declare -a args

  count=0
  for arg in "$@"; do
    args[count]=$(printf '%q' "$arg")
    count=$((count+1))
  done

  local remote_user_path="/home/$user"
  if [ "$user" == "root" ]; then
     remote_user_path="/"
  fi

  local file_name=${realscript##*/}
  local remote_script=""
  if [ -f $realscript ];then
    echo "Authenticating to copy file: $file_name"
    scp  "$realscript" "$user"@"$host":$remote_user_path
    remote_script="$remote_user_path/$file_name"
  fi
  echo "Authenticating to execute"
  ssh -t $user@$host bash "$remote_script" "${args[@]}" 
  echo "remote execution finished : $remote_script ${args[@]}"
}

function zip-proyect {
  local dest_file=$1
  local current_dir=$(pwd)
  local current_proyect=$(basename $current_dir)
  dest_file="${dest_file:-$current_proyect}"
  echo "creating $dest_file.zip $current_proyect"
  git archive --format=zip HEAD > $dest_file.zip
}
function update-stackbuilder {
   
   git fetch --all
   git reset --hard origin/master
   git pull origin master
   if [ -f stackbuilder.sh ] && [ validbash=1 ]; then 
      echo "updating stackbuilder script for bash"
      cat ./stackbuilder.sh > ~/stackbuilder.sh
      #add source line if not in .bashrc
      grep -qxF 'source ~/stackbuilder.sh' ~/.bashrc || echo 'source ~/stackbuilder.sh' >> ~/.bashrc
      source ./stackbuilder.sh 
   else
    echo "You need to be inside a valid stackbuilder project and bash terminal"
   fi
   echo "Stack utilities updated to $SB_VERSION"
}

function sb-bash {
  cat ./stackbuilder.sh > ~/stackbuilder.sh
}
function sbansible {
  local current_dir=$(pwd)
  SHARED="./src/:/app/"
  ARG0=$2
  cd ansible
  case $1 in
     "bake")
          $SB_DOCKER_CMD build -t stackb/ansibledocker . --network=host
          ;;
      "run")
          #$SB_DOCKER_CMD run -v $SHARED --rm --name ansibledocker diegopacheco/ansibledocker
          $SB_COMPOSE_CMD run --rm ansible
          ;;
       "lint")
          if [[ "$ARG0" = *[!\ ]* ]];
          then
            $SB_COMPOSE_CMD run ansible sh -c "/usr/bin/ansible-lint /app/$ARG0"
            #$SB_DOCKER_CMD run -v $SHARED --rm -ti stackb/ansibledocker /bin/sh -c "ansible-lint /app/$ARG0"
          else
            echo "Missing lint file! Valid sample: ./ansible-docker.sh lint main.yml"
          fi
          ;;
      *)
          echo "Ansible-Docker"
          echo "bake : bake the docker image"
          echo "run  : run whats inside src/main.yml with ansible-playbook"
          echo "lint : run ansible-lint in a specific file. .ie: ./ansible-docker.sh lint main.yml"
  esac
  cd $current_dir
}

function sb {
  stackb $@
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
  local portainer_port="29000"
  local enable_central_log_str=""
  SB_PROJECT="$(basename $(pwd))"
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
              $SB_COMPOSE_CMD exec $sb_container bash
              return
              ;;
          logs )
              shift
              local sb_container="$@"
              $SB_COMPOSE_CMD logs --no-color -t $sb_container

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
              $SB_COMPOSE_CMD $elk_cmd 
              if [ -f $elk_file_name ]; then
                echo "elk firs time run"
                stack-wait-log elasticsearch "Quit the server with CONTROL-C"
                #$SB_COMPOSE_CMD exec -T elasticsearch 'bin/elasticsearch-setup-passwords' auto --batch >> $elk_file_name
                cat $elk_file_name
              fi
              cd $current_dir
              return 
              ;;
          devtoolsup  )
              cd devtools
              $SB_COMPOSE_CMD up -d
              cd $current_dir
              return 
              ;;
          devtoolsdown )
              cd devtools
              $SB_COMPOSE_CMD down 
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
              compose_cmd="down --remove-orphans"
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
              compose_cmd="up -d"
              spec_container="$@"
              spec_params="--no-deps --build"
              $SB_COMPOSE_CMD stop $spec_container
              $SB_COMPOSE_CMD rm -f $spec_container
              ;;
          --prune_all ) 
              stack-clean-all
              return
              ;;
          --version ) 
              echo $SB_VERSION
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
    SB_VERSION=$SB_VERSION \
    STACK_MAIN_DOMAIN=$stackdomain \
    SB_MYSQL_ROOT_PASSWORD=$sb_db_sec_0 \
    SB_MYSQL_PASSWORD=$sb_db_sec_1 \
    SB_RDS_PASSWORD=$sb_db_sec_1 \
    CURRENT_UID=$(id -u):$(id -g) \
    $SB_COMPOSE_CMD -f docker-compose.yml up -d --build
    # Sleep to let MySQL load (there's probably a better way to do this)
    echo
    echo "Connecting app to DB for first time. Please wait..."
    stack-wait-log db "mysqld: ready for connections."
    stack-wait-log app "Quit the server with CONTROL-C"

    echo "Creating Django Admin user"
    set-django-admin $admin_user $admin_mail

    $SB_COMPOSE_CMD logs --no-color -t >& .stack.log
    
  else
    source stack.conf
    local enable_central_log=$(readvaluefromfile enable_central_log stack.conf)
    local yml_includes=""
    echo "Central log : $enable_central_log"
    if [[ $compose_cmd == up* ]];then
      echo "Adding yml files..."
      yml_includes="-f docker-compose.yml"
      if [[ "$enable_central_log" == "1" ]];then
        echo "Central logging enabled"
        yml_includes="$yml_includes -f docker-compose-central-log.yml"
        
      fi    
    fi

    echo "EXECUTING Compose Params:[${spec_params:-default}] Container(s):[${spec_container:-all}]"
    local  cmd_str="$SB_COMPOSE_CMD $yml_includes $compose_cmd $spec_params $spec_container"
    echo $cmd_str
    SB_VERSION=$SB_VERSION \
    STACK_MAIN_DOMAIN=$stackdomain \
    SB_MYSQL_PASSWORD=$sb_db_sec_1 \
    SB_RDS_PASSWORD=$sb_db_sec_1 \
    CURRENT_UID=$(id -u):$(id -g) \
    $cmd_str

  fi
  echo "Stackb completed."

}

function set-django-admin {
    local admin_user=$1
    local admin_mail=$2
    local create_response=$($SB_COMPOSE_CMD exec app python3 manage.py createsuperuser --username $admin_user  --noinput --email "$admin_mail")
    $SB_COMPOSE_CMD exec app python3 manage.py changepassword $admin_user
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
    local app_log=$($SB_COMPOSE_CMD logs $stack_service 2>&1 | grep "$log_str")
    if [ ${#app_log} -ne 0 ];then 
      echo "Service $stack_service Ready. Waiting for container (5 secs)..."
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
  $SB_COMPOSE_CMD exec -u 0 nginx-proxy bash -c "openssl req -x509 -nodes -days 1000 -newkey rsa:2048 -subj '$subj_str' -keyout /opt/bitnami/certs_stack/nginx-selfsigned.key -out /opt/bitnami/certs_stack/nginx-selfsigned.crt"
  addreplacevalue "ssl_certificate /opt/bitnami/certs" "ssl_certificate /opt/bitnami/certs_stack/nginx-selfsigned.crt;" ./nginx/sb_block.conf
  addreplacevalue "ssl_certificate_key /opt/bitnami/certs" "ssl_certificate_key /opt/bitnami/certs_stack/nginx-selfsigned.key;" ./nginx/sb_block.conf
  addreplacevalue "#sb_replace_sb_domain" "server_name $param_domain www.$param_domain; #sb_replace_sb_domain" ./nginx/sb_block.conf
  #echo "Creating Diffie-Helman dhparam"
  #$SB_COMPOSE_CMD exec nginx-proxy exec -u 0 nginx-proxy bash -c "openssl dhparam -out /opt/bitnami/certs_stack/dhparam.pem 2048"
  addreplacevalue "ssl_dhparam /opt/bitnami/certs" "#ssl_dhparam /opt/bitnami/certs_stack/dhparam.pem;" ./nginx/sb_block.conf

}

function stack-nginx-default-conf {
  addreplacevalue "ssl_dhparam /opt/bitnami/certs" "#ssl_dhparam /opt/bitnami/certs/dhparam.pem;" ./nginx/sb_block.conf
  addreplacevalue "ssl_certificate /opt/bitnami/certs" "ssl_certificate /opt/bitnami/certs/server.crt;" ./nginx/sb_block.conf
  addreplacevalue "ssl_certificate_key /opt/bitnami/certs" "ssl_certificate_key /opt/bitnami/certs/server.key;" ./nginx/sb_block.conf
}

function stack-build {
    #$SB_COMPOSE_CMD run app django-admin startproject project .
    #$SB_COMPOSE_CMD down --remove-orphans
    $SB_COMPOSE_CMD build
}
function stack-clean-all {
  local confirm_action=""
  local confirm_delete_data=""
  local confirm_delete_images="" 
  local options_str="$SB_COMPOSE_CMD down"
  echo "CAUTION: This action can delete all containers and data"
  echo
  read  -p "delete containers? (y/N) "  confirm_action  
  confirm_action="${confirm_action:-n}"
  echo
  read  -p "delete images? (y/N) "  confirm_delete_images  
  confirm_delete_images="${confirm_delete_images:-n}"
  echo
  read  -p "delete data? (y/N) "  confirm_delete_data  
  confirm_delete_data="${confirm_delete_data:-n}"
  echo
  if [ "$confirm_action" == "y" ];then
    echo "Removing containers"
    options_str="$options_str --remove-orphans"
  fi

  if [ "$confirm_delete_images" == "y" ];then
    echo "Removing images"
    options_str="$options_str --rmi all"

  fi
  if [ "$confirm_delete_data" == "y" ];then
    echo "Removing volumes"
    options_str="$options_str --volumes"
    rm -f .stack.env
    rm -f .stack.log
    rm -rf ./proxy-manager/data
    rm -rf ./proxy-manager/letsencrypt
  fi
  echo "Executing : $options_str"
  $options_str
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

if [ -z $1 ];then

  echo "Sourced"
else
  $@
fi
