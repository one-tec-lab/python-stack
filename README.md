# Container Stack Builder

Builds development and production environments for full stack applications

## Requirements ##


* [Install Docker CE](https://docs.docker.com/install/) 
Follow instructions for your OS. Runs on Linux, Mac and windows. After installation run "docker-compose -v" is also installed or follow this guide: [docker-compose](https://docs.docker.com/compose/install/). Recent version of docker (Native windows virtualization for Hyper-V or Mac version) should install it by default. 



## Install
Run the following command in a terminal (ssh or bash):

    curl https://raw.githubusercontent.com/one-tec-lab/container-stack/master/install-container-stack.sh > $HOME/install-container-stack.sh;source install-container-stack.sh; install-stack 2>&1 | tee install-container-stack.log

Logs will be available at the file install-container-stack.log of your user home.
