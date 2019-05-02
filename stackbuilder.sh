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
