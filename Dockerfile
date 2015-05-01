FROM mysql:5.6
MAINTAINER asami

RUN apt-get update && apt-get -y install wget curl

# Install JDK 1.7
RUN cd /opt; wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/7u51-b13/jdk-7u51-linux-x64.tar.gz" -O /opt/jdk-7-linux-x64.tar.gz

# Install in /usr/java/jdk1.7.0_51 
RUN mkdir /usr/java && (cd /usr/java; tar xzf /opt/jdk-7-linux-x64.tar.gz)
RUN rm /opt/jdk-7-linux-x64.tar.gz
RUN update-alternatives --install /usr/bin/java java /usr/java/jdk1.7.0_51/jre/bin/java 20000; update-alternatives --install /usr/bin/jar jar /usr/java/jdk1.7.0_51/bin/jar 20000; update-alternatives --install /usr/bin/javac javac /usr/java/jdk1.7.0_51/bin/javac 20000; update-alternatives --install /usr/bin/javaws javaws /usr/java/jdk1.7.0_51/jre/bin/javaws 20000; update-alternatives --set java /usr/java/jdk1.7.0_51/jre/bin/java; update-alternatives --set javaws /usr/java/jdk1.7.0_51/jre/bin/javaws; update-alternatives --set javac /usr/java/jdk1.7.0_51/bin/javac; update-alternatives --set jar /usr/java/jdk1.7.0_51/bin/jar;

RUN curl --create-dirs -o /opt/embulk -L "http://dl.embulk.org/embulk-latest.jar" && chmod +x /opt/embulk

RUN /opt/embulk gem install embulk-output-mysql

COPY charset.cnf /etc/mysql/conf.d/charset.cnf
COPY entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh

VOLUME ["/var/lib/mysql", "/etc/mysql/conf.d", "/opt/setup.d"]

ENTRYPOINT ["/opt/entrypoint.sh"]

CMD ["mysqld"]
