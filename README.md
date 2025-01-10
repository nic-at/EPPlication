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

### Use container image from hub.docker.com
```
./script/container/start.sh
```

### Development mode
```
./script/container/build.sh
```

the host directory is mounted inside the container
```
./script/container/start.sh --dev
```

webinterface
> http://localhost:8080  
> username: admin  
> password: admin123

## Selenium
The selenium server can be accessed using `epplication-selenium` as host when creating a SeleniumConnect step.

a VNC server is running in the selenium container.  
Connect on port 5900 to see EPPlication controlling the browser.  
`xtightvncviewer localhost::5900` (password: `secret`)

## Run dev testsuite
Setup test database and run testserver
```
./script/container/init_testsuite.sh
```

Run tests
```
./script/container/run_testsuite.sh
```

## Copyright & License
Copyright (c) 2012-2025, [David Schmidt](mailto:david.schmidt@univie.ac.at), [Free Artistic 2.0](https://opensource.org/licenses/Artistic-2.0).
