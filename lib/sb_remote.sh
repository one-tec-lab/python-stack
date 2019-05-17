#!/bin/bash
#

function get_source_dir {
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

function create_stackuilder_user {
    local new_user=$1
    new_user="${new_user:-stackbuilder}"
    echo "Creating user [$new_user]"
    sudo adduser $new_user
    sudo usermod -aG sudo $new_user

    cd /home/$new_user
    mkdir /home/$new_user/.ssh
    touch /home/$new_user/.ssh/authorized_keys
    sudo chmod 600 /home/$new_user/.ssh/authorized_keys
    sudo chown -R $new_user:$new_user /home/$new_user
}

function info {
  echo    "system   : $(uname)"
  echo    "User     : $(whoami)"
  echo -n "hostname : "
  cat /etc/hostname
  echo    "folder   : $(get_source_dir)"
  
}

function run {
  $@
}

function main {
  if [ -z $1 ];then
    echo "Sourced"
  else
    local cmd_line="$@"
    local first_param="$1"
    #local source_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
    local source_dir=$(get_source_dir)
    local source_file="${BASH_SOURCE[0]}"

    case $first_param in
      --selfdelete)
            shift
            cmd_line="$@"
            echo "Deleted... [$source_file]"
            rm $source_file
            $cmd_line
            ;;
        "run")
            shift
            run $@
            ;;
        *)
            echo "command: [$cmd_line]"
            $cmd_line
    esac
  fi
}

main $@