FROM mysql
MAINTAINER asami

ENV MYSQL_ALLOW_EMPTY_PASSWORD true

RUN apt-get update && apt-get -y install redis-server

COPY app.sh /opt/app.sh
RUN chmod +x /opt/app.sh

ENTRYPOINT /opt/app.sh
