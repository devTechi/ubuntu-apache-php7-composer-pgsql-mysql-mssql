FROM ubuntu:16.04

LABEL maintainer="devTechi <devT3chi@gmail.com>"

ENV PATH $PATH:/root/.composer/vendor/bin
ENV DOCUMENT_ROOT /var/www/html
ENV PORT 80

# add composer wrapper
ADD php_composer /usr/local/bin/composer
# add run script
ADD run /usr/local/bin/run

RUN apt-get update && \
  apt-get install -y software-properties-common --no-install-recommends && \
  LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php && \
  apt-get update && \
  apt-get dist-upgrade -y && \
  apt-get upgrade -y && \
  \
  # php7.1-dev and others are just needed for building
  # these packages need to be removed later (because of production, but it is needed for 'pecl'!)
  buildDeps=" \
  php7.1-dev \
  unixodbc-dev \
  " && \
  \
  apt-get install -y \
  apt-transport-https \
  ca-certificates \
  apache2 \
  mcrypt \
  libapache2-mod-php7.1 \
  php7.1 \
  php7.1-cli \
  php7.1-gd \
  php7.1-json \
  php7.1-ldap \
  php7.1-mbstring \
  php7.1-mysql \
  php7.1-pgsql \
  # php7.1-sqlite3 \
  php7.1-xml \
  php7.1-xsl \
  php7.1-zip \
  php7.1-curl \
  php7.1-mcrypt \
  php-mbstring \
  php-pear \
  curl \
  --no-install-recommends && \
  \
  apt-get install -y \
  $buildDeps && \
  \
  # Next composer and global composer package, as their versions may change from time to time
  curl -sS https://getcomposer.org/installer | php && \
  mv composer.phar /usr/local/bin/composer.phar && \
  \
  ############################
  # Install dependencies for MSSQLServer (see: https://www.microsoft.com/en-us/sql-server/developer-get-started/php/ubuntu/)
  # see: SQL Server instructions here: https://docs.microsoft.com/en-us/sql/connect/php/installation-tutorial-linux-mac?view=sql-server-2017#installing-the-drivers-on-ubuntu-1604-1710-and-1804
  ############################
  curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
  #Ubuntu 16.04
  curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
  apt-get update && \
  ACCEPT_EULA=Y apt-get install -y mssql-tools msodbcsql17 && \
  \
  echo 'PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile && \
  echo 'PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc && \
  \
  # install the php driver and add extension info to ini files
  pecl install sqlsrv pdo_sqlsrv && \
  \
  echo extension=pdo_sqlsrv.so >> `php --ini | grep "Scan for additional .ini files" | sed -e "s|.*:\s*||"`/30-pdo_sqlsrv.ini && \
  echo extension=sqlsrv.so >> `php --ini | grep "Scan for additional .ini files" | sed -e "s|.*:\s*||"`/20-sqlsrv.ini && \
  # configure driver loading
  a2dismod mpm_event && \
  a2enmod mpm_prefork && \
  a2enmod php7.1 && \
  # add sqlsrv extension info to apache2/php.ini
  echo "extension=pdo_sqlsrv.so" >> /etc/php/7.1/apache2/conf.d/30-pdo_sqlsrv.ini && \
  echo "extension=sqlsrv.so" >> /etc/php/7.1/apache2/conf.d/20-sqlsrv.ini && \
  ############################
  # Cleaning up and change rights of copied/added files
  ############################
  chmod +x /usr/local/bin/composer && \
  chmod +x /usr/local/bin/run && \
  a2enmod rewrite && \
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps && \
  rm -r /var/lib/apt/lists/*

# Apache config
ADD apache2.conf /etc/apache2/apache2.conf

WORKDIR /var/www/html

#EXPOSE 80

CMD ["/usr/local/bin/run"]