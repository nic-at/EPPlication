#!/usr/bin/env bash

set -x

docker exec -u epplication epplication-app bash -c 'EPPLICATION_DO_INIT_DB=1 EPPLICATION_TESTSSH=1 EPPLICATION_TESTSSH_USER=epplication EPPLICATION_HOST=localhost EPPLICATION_PORT=3000 EPPLICATION_TESTSELENIUM=1 EPPLICATION_TESTSELENIUM_HOST=epplication-selenium EPPLICATION_TESTSELENIUM_PORT=4444 carton exec prove -lvr t'

set +x
