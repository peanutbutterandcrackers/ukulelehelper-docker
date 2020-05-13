#!/bin/bash -i
set -o errexit # exit if any command in the script exits with a non-zero status

URL="https://ukulelehelper.com/" # The URL to download and host inside the container; REQUIRED!!!
CONTAINER_PORT=8000 # The port to publish the URL in, inside the container; REQUIRED!!!
EXPORTED_COMMAND_NAME=ukehelp # shell-function to start/stop the container. REQUIRED!!!
IMAGE_NAME=ukehelper # Optional, but better if set to something.
CONTAINER_NAME=uke_helper # Entirely Optional
HOST_PORT= # host-machine port to map to the container port. Entirely Optional. Somewhat better if unset.

# The temp file is used to properly figure out docker-daemon-set parameters like image/container id, etc. from
# the stdoutput (piped to the tempfile using `tee`) of the `docker build` and `docker create` commands. This
# makes sure that the script will continue with the exact name/ids of the built/created images/containers.
TEMP_FILE=$(mktemp /tmp/whale_whale_whale.$$.XXXXXXXXXXXX)

# eval: because the build-without-a-tag-if-image-name-is-unspecified parameter-expansion trick wasn't working without it
eval docker build ${IMAGE_NAME:+"--tag $IMAGE_NAME"} --build-arg URL=$URL --build-arg port=$CONTAINER_PORT . | tee $TEMP_FILE
IMAGE_ID=$(grep 'Successfully built \([[:alnum:]]\{12\}$\)' $TEMP_FILE | grep -o '\([[:alnum:]]\{12\}$\)')
# host-port is auto-selected by docker during container restart if it is unspecified ('')
# container name is assigned by docker automatically at creation time if unspecified ('')
docker create --name ${CONTAINER_NAME:-''} --publish ${HOST_PORT:-''}:$CONTAINER_PORT ${IMAGE_NAME:-$IMAGE_ID} | tee --append $TEMP_FILE
CONTAINER_ID=$(grep '\(^[[:alnum:]]\{12,\}$\)' $TEMP_FILE)
# In case the container name was not provided by the user, figure out the docker-assigned one
CONTAINER_NAME=${CONTAINER_NAME:-$(basename $(docker inspect $CONTAINER_ID --format {{.Name}}))}
rm $TEMP_FILE

# The following adds a shell-function with the name $EXPORTED_COMMAND_NAME to
# a startup file (~/.bashrc). If the command does already exist, it uses sed
# to replace it with a newer version of the function.
# It is because of the check for the command's pre-existance that this script
# is running in -i (interactive) mode: aliases and shell functions aren't av-
# ailable to the script otherwise

STARTUP_FILE=~/.bashrc

function remove_preexisting_function {
	# Syntax explanation for the (rather ugly) regex
	# /starting_regex/{:storeintothisVar;N; # take next line into the buffer
	# /end_regex/!bstoreintothisVar # go back to starting block stored in var
	# /regex pattern to match inside the block/d' # 'd' deletes the matching block
	# The regex is further uglified by the usage of '' and "" (because parameter
	# expansions do not happen inside single quotes
	sed --in-place=.bak \
	'/function'" $EXPORTED_COMMAND_NAME {"'/{:a;N;
	/\n}$/!ba};
	/function '"$EXPORTED_COMMAND_NAME"'/d' $1
}

command_already_exists=$(command -v $EXPORTED_COMMAND_NAME || echo "false")
[[ "$command_already_exists" != "false" ]] && remove_preexisting_function $STARTUP_FILE

{
cat << _EOF_

function $EXPORTED_COMMAND_NAME {

	# ASCII COLOR CODES
	LIGHT_CYAN='\033[1;36m'
	NC='\033[0m'

	if [ "\$1" == 'stop' ]; then
		docker stop $CONTAINER_NAME
	else
		docker start $CONTAINER_NAME || return
		# Figure out \$HOST_PORT from scratch because it changes with restart if not set manually
		HOST_PORT=\$(docker port $CONTAINER_NAME | cut --delimiter ':' --fields 2)
		MESSAGE="Please navigate to '\${LIGHT_CYAN}localhost:\${HOST_PORT}\${NC}' in your web-browser."
		echo -e \${MESSAGE}
	fi
}
_EOF_
} >> $STARTUP_FILE

set +o errexit # for some reason, with errexit set, source was not working
source ~/.bashrc
set -o errexit

$EXPORTED_COMMAND_NAME
