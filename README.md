To demo the docker deployment
1. Install docker
2. Add host 'dockerhost' to /etc/hosts, pointing to localhost or the virtualbox VM
3. Build the image (e.g. ./build.sh)
4. Run the container (e.g. ./run.sh)
5. Go to https://dockerhost/

Configuration Files
The conf/ directory contains the configuration files necesarry to run Strudel Web.
1. guacamole.properties --> Auth configuration file for Guacamole Client
2. nginx.conf --> Configuration file for nginx proxy server
3. setenv.sh --> Catalina startup configuration file
4. strudel-web.log4j2.xml --> Configuration file for Strudel Web app logging
5. strudel-web.properties --> Auth configuration for Strudel Web
