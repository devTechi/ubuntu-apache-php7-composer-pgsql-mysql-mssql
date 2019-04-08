FROM ubuntu:18.04

LABEL maintainer="devTechi <devT3chi@gmail.com>"

ENV PATH $PATH:/root/.composer/vendor/bin
ENV DOCUMENT_ROOT /var/www/html
ENV PORT 80
## for apt to be noninteractive
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

# add composer wrapper
ADD php_composer /usr/local/bin/composer
# add run script
ADD run /usr/local/bin/run

RUN apt-get update && \
  apt-get install -y software-properties-common && \
  add-apt-repository ppa:ondrej/php -y && \
  apt-get update && \
  ## see: https://stackoverflow.com/a/47909037
  apt-get install -y tzdata && \
  apt-get dist-upgrade -y && \
  apt-get upgrade -y && \
  \
  # php7.3-dev and others are just needed for building;
  # these packages need to be removed later (because of production, but it is needed for 'pecl'!)
  buildDeps=" \
  php7.3-dev \
  unixodbc-dev \
  libmcrypt-dev \
  " && \
  \
  apt-get install -y --allow-unauthenticated \
  apt-transport-https \
  ca-certificates \
  apache2 \
  mcrypt \
  libapache2-mod-php7.3 \
  libssl1.0.0 \
  php7.3 \
  php7.3-cli \
  php7.3-gd \
  php7.3-json \
  php7.3-ldap \
  php7.3-mbstring \
  php7.3-mysql \
  php7.3-pgsql \
  # php7.3-sqlite3 \
  php7.3-xml \
  php7.3-xsl \
  php7.3-zip \
  php7.3-curl \
  # php7.0-mcrypt \ ## depcrecated
  php-mbstring \
  php-pear \
  curl \
  --no-install-recommends && \
  \
  apt-get install -y --allow-unauthenticated \
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
  #Ubuntu 18.04
  curl https://packages.microsoft.com/config/ubuntu/18.04/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
  apt-get update && \
  # verify with
  # ldd /opt/microsoft/msodbcsql17/lib64/libmsodbcsql-17.3.so.1.1
  # ldconfig -p | grep libssl
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
  a2enmod php7.3 && \
  # add sqlsrv extension info to apache2-php.ini
  echo "extension=pdo_sqlsrv.so" >> /etc/php/7.3/apache2/conf.d/30-pdo_sqlsrv.ini && \
  echo "extension=sqlsrv.so" >> /etc/php/7.3/apache2/conf.d/20-sqlsrv.ini && \
  ############################
  # Cleaning up and change rights of copied/added files
  ############################
  chmod +x /usr/local/bin/composer && \
  chmod +x /usr/local/bin/run && \
  a2enmod rewrite && \
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps && \
  ## cleanup of files from setup
  rm -r /var/lib/apt/lists/* /tmp/*

# Apache config
ADD apache2.conf /etc/apache2/apache2.conf

WORKDIR /var/www/html

#EXPOSE 80

CMD ["/usr/local/bin/run"]

## to keep the image as small as possible try to use just ONE 'RUN' command