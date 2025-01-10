#!/usr/bin/env bash

arg1=${1:-default}

if [ $arg1 = '--dev' ]; then
    echo 'Stopping EPPlication (dev mode).'
    docker-compose -f compose.yml -f compose.devel.yml down
else
    echo 'Stopping EPPlication.'
    docker-compose -f compose.yml down
fi
