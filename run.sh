docker run --mount type=bind,source="$(pwd)"/conf,target=/opt \
	--mount type=bind,source=/mnt/tomcat8,target=/var/log/tomcat8 \
--name=strudel-web --restart=always \
-d  -p 443:443 -p 80:80 -ti strudel-web
