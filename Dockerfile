FROM alpine:latest

# Build-time variables
# This will aid in generalizing the Dockerfile
ARG URL=https://ukulelehelper.com
ARG port=8000

RUN apk add wget mini_httpd
RUN wget --recursive --no-parent $URL

EXPOSE $port/tcp

# Setting build-time vars to env. vars
# so as to make them available to CMD
ENV URL=${URL}
ENV port=${port}

CMD mini_httpd -D -p $port -d $(basename $URL)
