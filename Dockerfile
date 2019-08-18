FROM alpine:latest

ARG targetURL=https://ukulelehelper.com
ARG port=8000

RUN apk add wget
RUN apk add mini_httpd
RUN wget --recursive --no-parent $targetURL

EXPOSE $port/tcp

# Need to figure out a correct way to use variables here
CMD mini_httpd -D -p 8000 -d ukulelehelper.com
