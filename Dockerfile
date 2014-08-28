FROM ubuntu:14.04
MAINTAINER Alexis DUQUE "alexis.duque@openmrs.org"

ENV TOMCATVER 7.0.53

#Add universe repository and update
RUN echo "debconf debconf/frontend select Teletype" | debconf-set-selections &&apt-get -y update &&\
	apt-get -y install software-properties-common &&\
    add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) main universe" &&\
    add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc)-updates main universe" 

RUN apt-get -y update &&\
    apt-mark hold initscripts &&\
    apt-get -y upgrade

RUN apt-get -y update && apt-get install -y wget mysql-server

RUN useradd openmrs -s /bin/bash -m -U

RUN wget --progress=bar --no-check-certificate -O /tmp/server-jre-7u51-linux-x64.tar.gz --header "Cookie: oraclelicense=a" http://download.oracle.com/otn-pub/java/jdk/7u51-b13/server-jre-7u51-linux-x64.tar.gz

RUN echo "c5a034f4222bac326101799bcb20509c  /tmp/server-jre-7u51-linux-x64.tar.gz" | md5sum -c > /dev/null 2>&1 || echo "ERROR: MD5SUM MISMATCH"
RUN tar xzf /tmp/server-jre-7u51-linux-x64.tar.gz 
RUN mkdir -p /usr/lib/jvm/java-7-oracle 
RUN mv jdk1.7.0_51/jre /usr/lib/jvm/java-7-oracle/jre 
RUN rm -rf jdk1.7.0_51 && rm /tmp/server-jre-7u51-linux-x64.tar.gz
RUN chown root:root -R /usr/lib/jvm/java-7-oracle
RUN update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-7-oracle/jre/bin/java 1
RUN update-alternatives --set java /usr/lib/jvm/java-7-oracle/jre/bin/java

RUN wget -O /tmp/tomcat7.tar.gz http://apache.crihan.fr/dist/tomcat/tomcat-7/v7.0.54/bin/apache-tomcat-7.0.54.tar.gz
RUN (cd /opt && tar zxf /tmp/tomcat7.tar.gz)
RUN (mv /opt/apache-tomcat* /opt/tomcat)

ADD start.sh /usr/local/bin/run
RUN chmod a+x usr/local/bin/run

RUN sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/my.cnf

EXPOSE 8080

CMD ["/usr/local/bin/run"]