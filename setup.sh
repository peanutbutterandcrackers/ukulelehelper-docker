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

TEMP_FILE=$(mktemp /tmp/whale_whale_whale.$$.XXXXXXXXXXXX)

# eval: because it wasn't working without it
eval docker build ${image_name:+"--tag $image_name"} --build-arg URL=$URL --build-arg port=$port . | tee $TEMP_FILE
# host-port is auto-selected by docker daemon during container restart if it is unspecified ('')
docker create --name ${container_name:-''} --publish ${host_port:-''}:$container_port ${image_name:-$IMAGE_ID} | tee --append $TEMP_FILE

# Figure out docker-daemon-set stuffs
IMAGE_ID=$(grep 'Successfully built \([[:alnum:]]\{12\}$\)' $TEMP_FILE | grep -o '\([[:alnum:]]\{12\}$\)')
CONTAINER_ID=$(grep '\(^[[:alnum:]]\{12,\}$\)' $TEMP_FILE)
container_name=${container_name:-$(basename $(docker inspect $CONTAINER_ID --format {{.Name}}))}
rm $TEMP_FILE

# The following adds a shell-function with the name $exported_command_name to
# a startup file (~/.bashrc). If the command does already exist, it uses sed
# to replace it with a newer version of the function.
# It is because of the check for the command's pre-existance that this script
# is running in -i (interactive) mode: aliases and shell functions aren't av-
# ailable to the script otherwise

STARTUP_FILE=~/.bashrc

function remove_preexisting_function {
	# Syntax explanation for the (ugly) regex
	# /starting_regex/{:storeintothisVar;N; # take next line into the buffer
	# /end_regex/!bstoreintothisVar # go back to starting block stored in var
	# /regex pattern to match inside the block/d' # 'd' deletes the matching block
	# The regex is further uglified by the usage of '' and "" (because parameter
	# expansions do not happen inside single quotes
	sed --in-place=.bak \
	'/function'" $exported_command_name {"'/{:a;N;
	/\n}$/!ba};
	/function '"$exported_command_name"'/d' $1
}

command_already_exists=$(command -v $exported_command_name || echo "false")
[[ "$command_already_exists" != "false" ]] && remove_preexisting_function $STARTUP_FILE

{
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
} >> $STARTUP_FILE

set +o errexit # for some reason, with errexit set, source was not working
source ~/.bashrc
set -o errexit

$exported_command_name
