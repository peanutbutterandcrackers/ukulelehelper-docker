#!/bin/bash

container_port=8000
host_port=80

docker build --tag ukehelper .
docker run --detach --name uke_helper --publish $host_port:$container_port ukehelper

# INSTEAD OF THIS, REGISTER A FUNCTION THAT CAN START, STOP THE CONTAINER
echo -e "\nalias ukehelp='docker start uke_helper'" >> ~/.bashrc
