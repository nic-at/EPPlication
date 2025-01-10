#!/usr/bin/env bash

docker-compose -f compose.yml -f compose.devel.yml build --build-arg CONTAINER_UID=`id -u` app
