FROM alpine:latest

RUN apk add wget mini_httpd

RUN adduser -D foo
USER foo
WORKDIR /home/foo

# Build-time variables
# This will aid in generalizing the Dockerfile
ARG URL=https://ukulelehelper.com
ARG port=8000

RUN wget --recursive --no-parent $URL
EXPOSE $port/tcp

# Setting build-time vars to env. vars
# so as to make them available to CMD
ENV URL=${URL}
ENV port=${port}

CMD mini_httpd -D -p $port -d $(basename $URL)
