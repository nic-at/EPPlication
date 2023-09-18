# EPPlication

a Testing Framework developed and used by [nic.at](https://www.nic.at), the austrian domain name registry.

 - create tests in your browser
 - organize tests using tags
 - multiuser support
 - run tests in parallel
 - display results with extensive search functionality
 - deep linking to specific result parts
 - HTTP API for automated test execution and monitoring integration
 - wide variety of commands:
   - control browsers with selenium
   - bash commands
   - make HTTP, SOAP, EPP requests
   - run commands on remote hosts via SSH
   - execute SQL statements on databases
   - regular expressions
   - create random strings (format customizable)
   - datetime arithmetics
   - diff - data comparison utility
   - query data structures to extract information

[![EPPlication Video](https://i.vimeocdn.com/video/714314727.jpg?mw=1000&mh=560)](https://vimeo.com/280733237)


## Installation
Pull docker image from hub.docker.com and run it  
`docker-compose up`

Build docker image and run it  
```
docker-compose -f docker-compose.yml -f docker-compose.dev.yml build --build-arg CONTAINER_UID=`id -u` app
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

webinterface
> http://localhost:8080  
> username: admin  
> password: admin123

## Selenium
The selenium server can be accessed using `epplication-selenium` as host when creating a SeleniumConnect step.

a VNC server is running on the selenium docker container.
Connect on port 5900 to see EPPlication controlling the browser.  
`xtightvncviewer localhost::5900` (password: `secret`)

## Run dev testsuite
Setup test database and run testserver (./script/docker/init_testsuite.sh)
```
docker exec epplication-db dropdb --force --username=epplication epplication_testing
docker exec epplication-db createdb --username=epplication --owner=epplication epplication_testing
docker exec -u epplication epplication-app bash -c 'CATALYST_CONFIG_LOCAL_SUFFIX=testing CATALYST_DEBUG=1 carton exec plackup -Ilib epplication.psgi --port 3000'
```

Run tests (./script/docker/run_testsuite.sh)
```
docker exec -u epplication epplication-app bash -c "ssh-keyscan -H -t ecdsa epplication-app >> ~/.ssh/known_hosts"
docker exec -u epplication epplication-app bash -c 'EPPLICATION_DO_INIT_DB=1 EPPLICATION_TESTSSH=1 EPPLICATION_TESTSSH_USER=epplication EPPLICATION_HOST=localhost EPPLICATION_PORT=3000 EPPLICATION_TESTSELENIUM=1 EPPLICATION_TESTSELENIUM_HOST=epplication-selenium EPPLICATION_TESTSELENIUM_PORT=4444 carton exec prove -lvr t'
```

## Copyright & License
Copyright (c) 2012-2018, [David Schmidt](mailto:david.schmidt@univie.ac.at), [Free Artistic 2.0](https://opensource.org/licenses/Artistic-2.0).
