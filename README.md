# Container Stack Builder

Builds development and production environments for full stack applications

**Server components**
verifies Docker

Optionally, provides commands for installing Go language, NodeJS 10, npm and yarn (check install-container-stack.sh for available commands)




## Install
Run the following command in a terminal (ssh or bash):

    curl https://raw.githubusercontent.com/one-tec-lab/container-stack/master/install-container-stack.sh > $HOME/install-container-stack.sh;source install-container-stack.sh; install-stack 2>&1 | tee install-container-stack.log

Logs will be available at the file install-container-stack.log of your user home.
