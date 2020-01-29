FROM 	ubuntu:18.04
ARG     VERSION=6.12
LABEL 	version=$VERSION
LABEL 	description="Laravel "$VERSION
LABEL 	maintainer="2daw3@plaiaundi.net"

ARG DEBIAN_FRONTEND=noninteractive  
ARG PROJECT=/var/www/laravel
ARG PHP=php7.4

# TOOLS & APACHE
RUN apt update -y && apt upgrade -y && \
    apt install -y software-properties-common && \
    add-apt-repository ppa:ondrej/php && \
    apt update && apt upgrade -y && \
    apt install -y git curl apache2

# PHP
RUN apt install -y $PHP $PHP-mysql libapache2-mod-$PHP \
        $PHP-json $PHP-curl $PHP-dev $PHP-gd $PHP-mbstring \
        $PHP-zip $PHP-xml && \
    apt install -y php-bcmath php7.1-mcrypt && \
    apt autoremove -y && \
    apt clean && rm -r /var/lib/apt/lists/*

# NODE 
ENV NODE_VERSION=12.13.1
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"

# COMPOSER & LARAVEL
RUN /usr/bin/curl -sS https://getcomposer.org/installer |/usr/bin/php && \
    /bin/mv composer.phar /usr/local/bin/composer && \
    /usr/local/bin/composer create-project --prefer-dist laravel/laravel $PROJECT $VERSION && \
    /bin/chown www-data:www-data -R $PROJECT/storage $PROJECT/bootstrap/cache

# APACHE
# RUN cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/999-default.conf && \
#     echo '\
#     <VirtualHost *:80> \n\
#         ServerAdmin webmaster@localhost \n\
#         DocumentRoot /var/www/laravel/public \n\
#         \n\
#         <Directory "/var/www/laravel/public"> \n\
#             AllowOverride All \n\
#         </Directory> \n\
#     </VirtualHost> \n\
#     '> /etc/apache2/sites-available/000-default.conf
COPY 000-default.conf /etc/apache2/sites-available/000-default.conf

ENV APACHE_RUN_USER 	www-data
ENV APACHE_RUN_GROUP 	www-data
ENV APACHE_LOG_DIR 	    /var/log/apache2

EXPOSE 80

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
