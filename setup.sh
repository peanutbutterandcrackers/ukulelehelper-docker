#!/bin/bash -i
set -o errexit # exit if any command exits with a non-zero status

# The URL to download and host inside the container
URL="https://ukulelehelper.com/"
# The port to publish the URL in, in the container
port=8000

host_port=80 # host-machine port to map to the container port
container_port=$port

image_name=ukehelper
container_name=uke_helper
exported_command_name=ukehelp # shell-function to start/stop the container

docker build --tag $image_name \
		--build-arg URL=$URL --build-arg port=$port .
docker create --name $container_name \
		--publish $host_port:$container_port $image_name

# The following adds a shell-function with the name $exported_command_name to
# ~/.bashrc, with a logical check to verify that the command does not already
# exist: to prevent ~/.bashrc from being cluttered by the same function defn.
# multiple times.
# It is because of the check that this script is running in -i (interactive)
# mode: aliases and shell functions aren't available to the script otherwise
command -v $exported_command_name || {
cat << _EOF_

function $exported_command_name {

	# ASCII COLOR CODES
	LIGHT_CYAN='\033[1;36m'
	NC='\033[0m'

	MESSAGE="Please navigate to '\${LIGHT_CYAN}localhost:$host_port\${NC}' in your web-browser."

	if [ "\$1" == 'stop' ]; then
		docker stop $container_name
	else
		docker start $container_name && echo -e \${MESSAGE}
	fi
}
_EOF_
} >> ~/.bashrc

source ~/.bashrc
$exported_command_name
