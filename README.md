# Laravel Docker
Ejemplo de Dockerfile para crear una imagen Laravel 6.12
https://github.com/srlopez/LaravelDocker/blob/master/Dockerfile

Enlazado a https://hub.docker.com/repository/docker/srlopez/laravel para poder usarla desde clase.

# PROCESO DE CREACION DE UNA IMAGEN CON LARAVEL Y APACHE INSTALADO PARA DESARROLLO

## A.- Creación de una imagen laravel 6.12

```
$ docker build -f Dockerfile -t laravel:6.12 .
$ docker inspect -f {{.Config.Labels.description}} laravel:6.12
```
Este paso te lo puedes saltar si no necesitas una imagen y utilizas la de DockerHub. En ese caso deberías bajartela y la puedes renombrar para hacer el nombre más corto:
```
$ docker pull srlopez/laravel:6.12
$ docker tag srlopez/laravel:6.12 laravel:6.12
```

## B.- Lanzamos el contenedor y probamos que funciona la web
Ejecución
```
$ docker run -d --rm -p 8888:80 --name l6 laravel:6.12
$ docker ps
```
Desde un Navegador vamos a localhost:8888.

Y acabamos parando el contenedor, que como lo hemos lanzado con --rm se eliminará de la memoria
```
$ docker stop l6
```

## C.- Nuevo proyecto Laravel
Mediante estos dos comandos ponemos la imagen a correr, y al tener montado el directorio local en /aqui, al crear un proyecto laravel quedará persistente en el directorio. Lanzamos la imagen con los volumenes montados, y entramos en ella con un ```exec``` para crear un nuevo proyecto
```
$ docker run -d --rm -v $(PWD):/aqui -p 8888:80 --name l6 laravel:6.12
$ docker exec -it l6 bash
   # cd /app
   # composer create-project --prefer-dist laravel/laravel src
```

## D.- Edición de los archivos desde el hosts
Modificamos las views, controllers,models, etc y lo que necesitemos, y mientras tanto podemos seguir ejecutando comandos en la shell del contenedor
```
   # exit
$ docker stop l6
```
Los pasos C y D, si sólo los hemos hecho para crear un proyecto, realmente los podemos hacer en uno sólo:
```
$ docker run -it --rm -v $(PWD):/aqui laravel:6.12 composer create-project --prefer-dist laravel/laravel src
```
Y ya tenemos el nuevo proyecto en ```src```

## E.- Todo OK?
Confirmamos que las modificaciones siguen funcionando 
Relanzamos la imagen de laravel y vinculamos el directorio local con un directorioen el que está el DocumentRoot de Apache
```
$ docker run -d --rm -v $(PWD)/src:/var/www/laravel -p 8888:80 --name l6 laravel:6.12
$ docker stop l6
```

# F.- En desarrollo
Lo podemos lanzar ejecutando bash en lugar del CMD prefijado, y publicamos la puerta de desarrollo y no la de Apache
```
$ docker run -it --rm -p 8000:8000 -p 8880:80 --name l6 -v $(PWD)/app:/var/www/laravel -w /var/www/laravel laravel:6.12 bash
   # php artisan tinker ....
   # php artisan serve --host 0.0.0.0
```

# G.- Creación de una imagen con el nuevo proyecto
O con otro que tú tengas ya creado. Mediante un Dockerfile con los comados para crear la imagen de nuestra nueva aplicación.

El Dockerfile podría ser:
```
    FROM laravel:6.12
    LABEL description="Mi Proyecto laravel"
    COPY src /var/www/laravel
    RUN /bin/chown www-data:www-data -R /var/www/laravel/storage /var/www/laravel/bootstrap/cache
```
En el que copiamos tu directorio ```src``` al directorio desde dondo Apache sirve el DocumentRoot.
Si tu proyecto hubiese estado en un Git, en lugar de COPY podría ser:
```
   ARG CACHEBUST=1
   RUN git clone https://tu_repositorio_git src
   RUN rm -rf /var/www/laravel && \
    mv /src/app /var/www/laravel && \
    rm -rf /src && \
    cd /var/www/laravel && \
    npm install && \
    composer install
```

Y la creamos mediante estos comandos:
```
docker build -f Dockerfile.app -t miApp:1.0 .
docker inspect -f {{.Config.Labels.description}} laraweb:1.0
```

# F. Antes de lanzarlo deberemos asegurarnos que hay una DB
O bien linkada, o bien lo componemos en un docker-compose

# G. y lanzamos nuestra app
```
docker run -d --rm -p 8880:80 --name l1 miApp:1.0
```
Y Navegador y a localhost:8880
```
docker stop l1
```

Enhora buena!
