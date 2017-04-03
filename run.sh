#!/bin/bash

# temp. start mysql to do all the install stuff
/usr/bin/mysqld_safe > /dev/null 2>&1 &

# ensure mysql is running properly
sleep 20 


# install composer if needed
if [ ! -f /usr/local/bin/composer ]; then
    EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")

    if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
    then
        >&2 echo 'ERROR: Invalid installer signature'
        rm composer-setup.php
        exit 1
    fi

    php composer-setup.php --quiet
    mv composer.phar /usr/local/bin/composer
    RESULT=$?
    rm composer-setup.php
fi

# install pimcore if needed
if [ ! -d /var/www/pimcore ]; then
  # download & extract
  cd /var/www
  rm -r /var/www/*
  sudo -u www-data wget https://www.pimcore.org/download-5/pimcore-unstable.zip -O /tmp/pimcore.zip
  sudo -u www-data unzip /tmp/pimcore.zip -d /var/www/
  rm /tmp/pimcore.zip 

  echo "CREATE DATABASE project_database charset=utf8mb4;" | mysql
  echo "GRANT ALL PRIVILEGES ON *.* TO 'project_user'@'%' IDENTIFIED BY 'secretpassword' WITH GRANT OPTION;" | mysql

  # ??
  # sudo -u www-data /var/www/bin/console cache:clear
  # sudo -u www-data -- composer install

fi

# stop temp. mysql service
mysqladmin -uroot shutdown

exec supervisord -n
