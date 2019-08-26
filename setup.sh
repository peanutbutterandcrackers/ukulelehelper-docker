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

# eval: because it wasn't working without it
eval docker build ${image_name:+"--tag $image_name"} --build-arg URL=$URL --build-arg port=$port .
IMAGE_ID=$(docker images --quiet | head --lines 1)
# host-port is auto-selected by docker daemon during container restart if it is unspecified ('')
docker create --name ${container_name:-''} --publish ${host_port:-''}:$container_port $IMAGE_ID
CONTAINER_ID=$(docker ps --latest --quiet)

# Figure out docker-daemon-set stuffs
container_name=${container_name:-$(basename $(docker inspect $CONTAINER_ID --format {{.Name}}))}

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

	if [ "\$1" == 'stop' ]; then
		docker stop $container_name
	else
		docker start $container_name || return
		# Figure out \$host_port from scratch because it changes with restart if not set manually
		host_port=\$(docker port $container_name | cut --delimiter ':' --fields 2)
		MESSAGE="Please navigate to '\${LIGHT_CYAN}localhost:\${host_port}\${NC}' in your web-browser."
		echo -e \${MESSAGE}
	fi
}
_EOF_
} >> ~/.bashrc

set +o errexit # for some reason, with errexit set, source was not working
source ~/.bashrc
set -o errexit

$exported_command_name
