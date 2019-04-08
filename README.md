Inspired by the docker image of [lucidprogrammer](https://github.com/lucidprogrammer/apache-php7-composer-pgsql-mysql) 
some packages and the ubuntu version were updated.

Additionally the Microsoft driver for MSSQL was added. See for more information following links:
 
 - https://docs.microsoft.com/en-us/sql/connect/php/installation-tutorial-linux-mac?view=sql-server-2017#installing-the-drivers-on-ubuntu-1604-1710-and-1804
 - https://www.microsoft.com/en-us/sql-server/developer-get-started/php/ubuntu/


# Ubuntu & PHP Versions
 - ubuntu 18.04
 - php 7.3

## Starting
On a Mac you may start the container like

```
docker container run \
   --name dtPHP7 \
   --mount type=bind,source="$(pwd)/src/",target=/var/www/html/ \
   -p 8080:80 \
   devtechi/ubuntu-apache-php7-composer-pgsql-mysql-mssql:latest
```