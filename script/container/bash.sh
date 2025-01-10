#!/usr/bin/env bash

arg1=${1:-default}
user='epplication'

if [ $arg1 = '--root' ]; then
    user='root'
fi

echo "Enter container (user: $user)."
docker exec -it -u $user epplication-app bash
