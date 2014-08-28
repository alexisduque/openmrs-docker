#!/bin/bash

MYSQL_PASSWORD=mysql
DATABASE_NAME=openmrs
DATABASE_USER=openmrs
DB_USER_PASSWD=openmrs
ADMIN_USER=${ADMIN_USER:-admin}
ADMIN_PASS=${ADMIN_PASS:-tomcat}
MAX_UPLOAD_SIZE=${MAX_UPLOAD_SIZE:-52428800}
CATALINA_OPTS=${CATALINA_OPTS:-"-Xms128m -Xmx1024m -XX:PermSize=128m -XX:MaxPermSize=256m"}

export CATALINA_OPTS="${CATALINA_OPTS}"

if [ ! -e /etc/.initsuccess ]
then

echo "First start !"

cat << EOF > /opt/tomcat/conf/tomcat-users.xml
<?xml version='1.0' encoding='utf-8'?>
<tomcat-users>
<user username="${ADMIN_USER}" password="${ADMIN_PASS}" roles="admin-gui,manager-gui"/>
</tomcat-users>
EOF

if [ -f "/opt/tomcat/webapps/manager/WEB-INF/web.xml" ]
then
	sed -i "s#.*max-file-size.*#\t<max-file-size>${MAX_UPLOAD_SIZE}</max-file-size>#g" /opt/tomcat/webapps/manager/WEB-INF/web.xml
	sed -i "s#.*max-request-size.*#\t<max-request-size>${MAX_UPLOAD_SIZE}</max-request-size>#g" /opt/tomcat/webapps/manager/WEB-INF/web.xml
fi

echo "Setup  mysql ...."

chown -R mysql:mysql /var/lib/mysql
mysql_install_db --user mysql > /dev/null

/usr/bin/mysqld_safe & 
sleep 10s
mysqladmin -h 127.0.0.1 -u root password $MYSQL_PASSWORD || { echo 'Command failed' ; exit 1; }
mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE $DATABASE_NAME;"
mysql -uroot -p$MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON $DATABASE_NAME.* TO '$DATABASE_USER'@'localhost' IDENTIFIED BY '$DB_USER_PASSWD'; FLUSH PRIVILEGES;"
mysql -uroot -p$MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON $DATABASE_NAME.* TO '$DATABASE_USER'@'%' IDENTIFIED BY '$DB_USER_PASSWD'; FLUSH PRIVILEGES;"

echo "Stop mysqld"
killall mysqld
sleep 10s
touch /etc/.initsuccess
fi

echo "Launch Tomcat and mysql"

service mysql start
/bin/sh -e /opt/tomcat/bin/catalina.sh run
