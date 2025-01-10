#!/usr/bin/env bash

arg1=${1:-default}

if [ $arg1 = '--dev' ]; then
    echo 'Starting EPPlication in dev mode.'
    docker-compose -f compose.yml -f compose.devel.yml up
else
    echo 'Starting EPPlication.'
    docker-compose up
fi
