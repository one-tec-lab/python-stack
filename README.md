# Container Stack Builder

Builds development and production environments for full stack applications

## Requirements ##


### Docker ###
Install Docker CE for your OS:
* [Docker CE for Windows](https://docs.docker.com/docker-for-windows/install/). Follow the [Getting Started Guide for Windows](https://docs.docker.com/docker-for-windows/) to enable shared drives option.
* [Docker CE for Mac](https://docs.docker.com/docker-for-mac/install/). Follow the [Getting Started Guide for Mac](https://docs.docker.com/docker-for-mac/) to enable File sharing.
* [Docker CE for Linux](https://docs.docker.com/install/) Follow instructions for your OS: [CentOS](https://docs.docker.com/install/linux/docker-ce/centos/), [Debian](https://docs.docker.com/install/linux/docker-ce/debian/), [Fedora](https://docs.docker.com/install/linux/docker-ce/fedora/), [Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/). Follow this [Post-Install Instructions](https://docs.docker.com/install/linux/linux-postinstall/) if required.

After installation run "docker-compose -v" to verify it is also installed or follow this guide: [docker-compose](https://docs.docker.com/compose/install/). Recent version of docker (Native windows virtualization for Hyper-V or Mac version) should install it by default. 

### Git and Git Bash ###
* [Install Git and Git Bash](https://git-scm.com/downloads): Follow instructions for your OS. Runs on Linux, Mac and Windows.(Git Bash is only required if you are using Windows).

## Install
1-Run the following command in a terminal (ssh or bash):

    git clone https://github.com/one-tec-lab/stackbuilder.git your-awesome-project

This will create a new folder your-awesome-project called under your current directory. Replace "your-awesome-project" with any name.

2-cd to the new project folder

    cd your-awesome-project

3-Source the stackbuilder script to make commands available

    source stackbuilder.sh

4-Run the stack-build command

    stack-build
    
Read stackbuilder.sh file for available commands.
