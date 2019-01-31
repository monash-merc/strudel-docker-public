#!/bin/bash
docker stop strudel-web
for job in `docker ps -qa` ; do docker rm $job; done
docker build -t strudel-web .
