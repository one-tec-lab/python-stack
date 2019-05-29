#!/bin/bash
#
# remember:
# generate ssh keys:
# ssh-keygen -t rsa -b 4096
# copy keys:
# ssh-copy-id username@remote_ip
# will end in remote server ~/.ssh/authorized_keys
# public key to copy from local host:
# ~/.ssh/id_rsa.pub
# example using ssh:
# cat ~/.ssh/id_rsa.pub | ssh demo@198.51.100.0 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >>  ~/.ssh/authorized_keys"

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

function install-docker {
  sudo apt-get update
  sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
  echo "Installing Docker..."
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  echo "Check fingerprint for 9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88"
  sudo apt-key fingerprint 0EBFCD88
  sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
   sudo apt-get update
   sudo apt-get install -y docker-ce docker-ce-cli containerd.io
   sudo docker run -rm hello-world
   sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
}
function create-stackuilder-user {
    local new_user=$1
    new_user="${new_user:-stackbuilder}"
    echo "Creating user [$new_user]"
    sudo adduser $new_user
    sudo usermod -aG sudo $new_user

    cd /home/$new_user
    mkdir -p /home/$new_user/.ssh
    touch /home/$new_user/.ssh/authorized_keys
    sudo chmod 600 /home/$new_user/.ssh/authorized_keys
    sudo chown -R $new_user:$new_user /home/$new_user
}

function info {
  echo    "system   : $(uname)"
  echo    "User     : $(whoami)"
  echo -n "hostname : "
  cat /etc/hostname
  echo    "folder   : $(get-source-dir)"
  
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
    local source_dir=$(get-source-dir)
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

function devtoolsup {

    echo "STARTING rancher ports 22080,22443"
    sudo docker run -d --name=sb_rancher --restart=unless-stopped -p 22080:80 -p 22443:443 rancher/rancher
    sudo docker start sb_rancher 
    echo "STARTING portainer port 29000"
    sudo docker volume create portainer_data
    sudo docker run -d --name=sb_portainer --restart=unless-stopped -p 29000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer
    sudo docker start sb_portainer
}

function devtoolsdown {

    echo "STOPPING rancher ports 22080,22443"
     sudo docker stop sb_rancher 
    echo "STOPPING portainer port 29000"

    sudo docker stop sb_portainer
}
 
function setup-ubuntu {
  local cmd_line="$@"
  local first_param="$1"
  local devtools_str=""
  if [[ $cmd_line == *"devtools"* ]]; then
    devtools_str="$devtools_str ansible"
    echo "INSTALLING devtools : $devtools_str"
  fi

  #create-stackuilder-user
  install-docker

  #sudo apt-get update -y
  sudo apt-get install -y fail2ban sendmail ufw git jq $devtools_str
  sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
  #sudo cat /etc/fail2ban/jail.local
  sudo ufw disable
  sudo ufw default deny incoming
  sudo ufw allow ssh
  sudo ufw allow http
  sudo ufw allow https

  sudo bash -c "cat > /etc/fail2ban/jail.local" <<-EOF
[DEFAULT]

# email address to receive notifications.
destemail = root@localhost    
# the email address from which to send emails.
sender = root@<fq-hostname>    
# name on the notification emails.
sendername = Fail2Ban    
# email transfer agent to use. 
mta = sendmail   

# see action.d/ufw.conf
actionban = ufw.conf
# see action.d/ufw.conf 
actionunban = ufw.conf   

[sshd]
enabled = true
port = ssh
filter = sshd
# the length of time between login attempts for maxretry. 
findtime = 3600
# attempts from a single ip before a ban is imposed.
maxretry = 4
# the number of seconds that a host is banned for.
bantime = 86400
EOF

echo "enable fail2ban with systemctl"
sudo systemctl service enable fail2ban
sudo systemctl service start fail2ban
echo "enable fail2ban with client"
sudo fail2ban-client restart
sudo fail2ban-client status
sudo fail2ban-client status sshd
echo "enabling ufw"
sudo ufw enable
sudo ufw status verbose
#check log:
# cat /var/log/auth.log

echo "setup-ubuntu Finished"
}


main $@