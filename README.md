# Container Stack Builder

Builds development and production environments for full stack applications

## Requirements ##


### Docker ###
Install Docker CE for your OS:
* [Docker CE for Windows](https://docs.docker.com/docker-for-windows/install/)
* [Docker CE for Mac](https://docs.docker.com/docker-for-mac/install/) 
* [Docker CE for Linux](https://docs.docker.com/install/) Follow instructions for your OS: [CentOS](https://docs.docker.com/install/linux/docker-ce/centos/), [Debian](https://docs.docker.com/install/linux/docker-ce/debian/), [Fedora](https://docs.docker.com/install/linux/docker-ce/fedora/), [Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/). Follow this [Post-Install Instructions](https://docs.docker.com/install/linux/linux-postinstall/) if required.

After installation run "docker-compose -v" to verify it is also installed or follow this guide: [docker-compose](https://docs.docker.com/compose/install/). Recent version of docker (Native windows virtualization for Hyper-V or Mac version) should install it by default. 

### Git and Git Bash ###
* [Install Git and Git Bash](https://git-scm.com/downloads) (Git Bash is only required if you are using Windows).Follow instructions for your OS. Runs on Linux, Mac and Windows. 

## Install
Run the following command in a terminal (ssh or bash):

    curl https://raw.githubusercontent.com/one-tec-lab/container-stack/master/install-container-stack.sh > $HOME/install-container-stack.sh;source install-container-stack.sh; install-stack 2>&1 | tee install-container-stack.log

Logs will be available at the file install-container-stack.log of your user home.
