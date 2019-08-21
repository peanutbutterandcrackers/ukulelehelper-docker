#!/bin/bash -i
########################
# -i (interactive) mode because bash scripts, apparently,
# don't have access to shell functions or aliases; and it
# is necessary to check for the existance of one so as to
# not clutter up the .bashrc file on multipe executions.

container_port=8000
host_port=80

docker build --tag ukehelper .
docker run --detach --name uke_helper --publish $host_port:$container_port ukehelper

# If the shell function that we add to .bashrc already exists, don't do anything
command -v ukehelp || {
cat << _EOF_

function ukehelp {
	if [ "\$1" == 'stop' ]; then
		docker stop uke_helper
	else
		docker start uke_helper
	fi
}
_EOF_
} >> ~/.bashrc
