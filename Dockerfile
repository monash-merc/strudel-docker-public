FROM ubuntu:18.04
MAINTAINER Jafaruddin Lie <jafar.lie@monash.edu>

# Note: Configuration files should be mounted to /opt using the -v option when creating the container

RUN apt update
RUN apt -y upgrade
RUN apt install -y logrotate openjdk-8-jdk openjdk-8-jre-headless tomcat8 maven git npm unzip
RUN update-java-alternatives --jre-headless --jre --set java-1.8.0-openjdk-amd64
#RUN ln -s /var/lib/tomcat8 /usr/share/

# The node binary isn't called node in ubuntu; link it so bower works
#RUN ln -s /usr/bin/nodejs /usr/bin/node
RUN npm -g install bower
# Docker runs all this as root, and bower doesn't like this.
RUN echo '{ "allow_root": true }' > ~/.bowerrc

# Add SSH deployment key (not required when github repo is made public)
#RUN mkdir ~/.ssh
#ADD id_rsa /root/.ssh/id_rsa
#ADD id_rsa.pub /root/.ssh/id_rsa.pub
#RUN chmod 700 ~/.ssh
#RUN chmod 600 ~/.ssh/id_rsa*

# Clone and build requried java packages
RUN mkdir -p ~/.ssh
RUN ssh-keyscan github.com >> ~/.ssh/known_hosts
RUN git clone https://github.com/monash-merc/jobcontrol.git ~/jobcontrol
ADD guacamole-client-1.0.0.tar.gz /root/
RUN git clone https://github.com/monash-merc/massive-guacamole-remote-guac1.git ~/massive-guacamole-remote

RUN cd ~/jobcontrol && mvn package
RUN cd ~/guacamole-client-1.0.0/ && mvn package
RUN cd ~/massive-guacamole-remote && mvn package

# Deploy the guacamole webapp
RUN mkdir -p /var/lib/tomcat8/.guacamole/extensions

ADD conf/guacamole.properties /opt/

RUN cp ~/massive-guacamole-remote/target/massive-guacamole-remote-*jar /var/lib/tomcat8/.guacamole/extensions
RUN cp ~/massive-guacamole-remote/target/massive-guacamole-remote-*.jar /var/lib/tomcat8/lib/
RUN mv ~/guacamole-client-1.0.0/guacamole/target/guacamole*.war /var/lib/tomcat8/webapps/guacamole.war

RUN mkdir /var/lib/tomcat8/webapps/guacamole/
RUN cd /var/lib/tomcat8/webapps/guacamole/ && unzip ../guacamole.war

ADD http://central.maven.org/maven2/com/google/code/gson/gson/2.4/gson-2.4.jar /var/lib/tomcat8/webapps/guacamole/WEB-INF/lib/gson-2.4.jar
RUN chown -R tomcat8:tomcat8 /var/lib/tomcat8/webapps/guacamole

# Deploy strudel web
ADD conf/strudel-web.properties /opt/
RUN ln -s /opt/strudel-web.properties ~tomcat8
RUN mv ~/jobcontrol/target/strudel-web.war /var/lib/tomcat8/webapps/

# Comment out filtering for | character so Strudel can work
RUN echo "tomcat.util.http.parser.HttpParser.requestTargetAllow=|" >> /etc/tomcat8/catalina.properties

RUN ln -s /opt/strudel-web.properties /usr/share/tomcat8/

# Copy across setenv.sh
ADD setenv.sh /opt/
RUN ln -s /opt/setenv.sh /usr/share/tomcat8/bin/

# Clone and build guacd
RUN apt-get install -y autoconf libtool libcairo2-dev libjpeg-turbo8-dev libpng-dev libossp-uuid-dev libfreerdp-dev libpango1.0-dev libssh2-1-dev libvncserver-dev libpulse-dev libvorbis-dev libwebp-dev less net-tools telnet libssl-dev

ADD guacamole-server-1.0.0.tar.gz /root/

RUN cd ~/guacamole-server-1.0.0 && autoreconf -fi && ./configure --with-init-dir=/etc/init.d && make install
RUN ldconfig

# Install nginx
RUN apt -y install -y nginx ssl-cert
ADD conf/nginx.conf /etc/nginx/sites-enabled/default
ADD conf/nginx.conf /opt/
RUN rm -rf /etc/nginx/sites-enabled/default
RUN ln -s /opt/nginx.conf /etc/nginx/sites-enabled/default

# Copy the logging file
ADD conf/strudel-web.log4j2.xml /opt/
RUN ln -s /opt/strudel-web.log4j2.xml /var/lib/tomcat8/


EXPOSE 80
EXPOSE 443

CMD service nginx start; service guacd start; service tomcat8 start; tail -F /var/log/tomcat8/catalina.out
