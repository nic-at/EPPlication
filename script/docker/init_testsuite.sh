#!/usr/bin/env bash

set -x

docker exec epplication-db dropdb --username=epplication epplication_testing
docker exec epplication-db createdb --username=epplication --owner=epplication epplication_testing
docker exec -it -u epplication epplication-app bash -c 'CATALYST_CONFIG_LOCAL_SUFFIX=testing CATALYST_DEBUG=1 carton exec plackup -Ilib epplication.psgi --port 3000'

set +x
