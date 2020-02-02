# Laravel Docker
Ejemplo de Dockerfile para crear una imagen Laravel 6.12

Dockerfile: https://github.com/srlopez/LaravelDocker/blob/master/Dockerfile

Enlazado a https://hub.docker.com/repository/docker/srlopez/laravel para poder usarla desde clase.

# IMAGEN DE LARAVEL+APACHE PARA USO EN DESARROLLO

## A.- Creación/Descarga de la imagen laravel 6.12
Copia el Dokerfile a tu directorio local y...
```
$ docker build -t laravel:6.12 .
$ docker inspect -f {{.Config.Labels.description}} laravel:6.12
```
Este paso te lo puedes saltar si no necesitas el Dockerfile, y utilizas la imagen de DockerHub. En ese caso deberías bajartela, la puedes renombrar para hacer el nombre más corto, y utilizarla con más comodidad:
```
$ docker pull srlopez/laravel:6.12
$ docker tag srlopez/laravel:6.12 laravel:6.12
```

## B.- Lanzamos el contenedor (run) y probamos que funciona la web
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

## C.- En MODO DESARROLLO: Creamos un nuevo proyecto Laravel
Mediante estos comandos ponemos la imagen a correr ```run``` con el directorio local montado en ```/aqui```. Al crear el proyecto laravel quedará persistente en el directorio. Entramos en el contenedor con un ```exec``` para crear el proyecto
```
$ docker run -d --rm -v $(PWD):/aqui -p 8888:80 --name l6 laravel:6.12
$ docker exec -it l6 bash
   # cd /app
   # composer create-project --prefer-dist laravel/laravel src
```

## D.- En MODO DESARROLLO: Edición de los archivos desde el hosts con tu editor favorito
Modificamos las views, controllers, models, etc y lo que necesitemos, y mientras tanto podemos seguir ejecutando comandos en la shell del contenedor desde el que lanzamos el ```bash```
```
   # exit
$ docker stop l6
```
Los 2 pasos anteriores, si sólo los hemos hecho para crear un proyecto, realmente los podemos hacer en uno sólo:
```
$ docker run -it --rm -v $(PWD):/aqui -w /aqui laravel:6.12 composer create-project --prefer-dist laravel/laravel src
```
Y ya tenemos el nuevo proyecto en ```src```

## E.- En MODO DESARROLLO: Todo OK?
Confirmamos que las modificaciones siguen funcionando.
Relanzamos la imagen de laravel y vinculamos el directorio local ```src```con un directorioen el que está el DocumentRoot de Apache que es ```/var/www/laravel``` como queda claro en el archivo de configuración ```000-default.conf```.
```
$ docker run -d --rm -v $(PWD)/src:/var/www/laravel -p 8888:80 --name l6 laravel:6.12
$ docker stop l6
```

## F.- En MODO DESARROLLO: Sobrescribimos CMD
Lo podemos lanzar ejecutando ```bash``` en lugar del CMD prefijado, y publicamos la puerta de desarrollo de Laravel, y la que usa Apache si lo queremos así. 
```
$ docker run -it --rm -p 8000:8000 -p 8880:80 --name l6 -v $(PWD)/app:/var/www/laravel -w /var/www/laravel laravel:6.12 bash
   # php artisan tinker ....
   # php artisan serve --host 0.0.0.0
```

## G.- Creación de una NUEVA IMAGEN con el nuevo proyecto
O con otro que tú tengas ya creado. Mediante un Dockerfile con los comados para crear la imagen de nuestra nueva aplicación.

El Dockerfile (Dockerfile.app) podría ser:
```
    FROM laravel:6.12
    LABEL description="mi proyecto laravel"
    COPY src /var/www/laravel
    RUN /bin/chown www-data:www-data -R /var/www/laravel/storage /var/www/laravel/bootstrap/cache
```
Con ```COPY src /var/www/laravel``` copiamos el directorio ```src``` al directorio desde donde Apache sirve el DocumentRoot.
Si tu proyecto hubiese estado en un Git, en lugar de la linea ```COPY``` podrías usar:
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
Una vez que tenemos el Dockerfile configurado.
Creamos la imagen mediante estos comandos:
```
docker build -f Dockerfile.app -t miApp:1.0 .
docker inspect -f {{.Config.Labels.description}} miApp:1.0
```

## H. AVISO: Antes de lanzarlo deberemos asegurarnos que hay una DB
O bien linkada, o bien lo componemos en un docker-compose.
Si no se te ocurre cómo, mira los ejemplos más abajo.

## I. Lanzamos nuestra app
```
docker run -d --rm -p 8880:80 --name l1 miApp:1.0
```
Lanzamos un navegador y a localhost:8880, y lo paramos.
```
docker stop l1
```

**¡Enhora buena!**

# === Ejemplos ===
## MYSQL
Pongo ejemplos con contraseña y **sin ella** para ```root```. Mientras aprendemos usaremos sin contraseña mysql 

Ej: Lanzar un contenedor mysql
```
docker run --name sql8 -e MYSQL_ROOT_PASSWORD=1234 -d  mysql:8.0
docker run --rm --name sql8 -e MYSQL_ALLOW_EMPTY_PASSWORD=yes -d mysql:8.0
```
Ej: Entrar en él y trabajar
```
docker exec -it sql8 bash
     # exit
```
o lanzar un comando específico
```
docker exec -it sql8 mysql -u root -p  -e "show databases;" 
docker exec -it sql8 mysql -u root -p

docker exec -it sql8 mysql -e "show databases;"
docker exec -it sql8 mysql 
```

Ej:Arrancar **otro contenedor** conectado al primero y ejecutar un comando contra el primero
```
docker run --link sql8 --rm -it mysql:8.0 mysql -h sql8 -u root -p -e "use mysql; show tables;"
```

### Persistencia de datos: USAMOS -v
- En directorio local
    con docker run: ```-v $(PWD)/dbdata:/var/lib/mysql```
- En volumen docker
```
docker create volume dbdata
```
   con docker run:   ```-v dbdata:/var/lib/mysql```
   
podemos ver que contenedor usa un determinado volumen
```
docker ps -a --filter volume=dbdata
```
Para ver ejemplos completos de persistencia sigue leyendo

## LARAVEL
- Lanzamos una db persistente (en docker/o no) y sin password
```
docker run --rm --name sql8 -e MYSQL_ALLOW_EMPTY_PASSWORD=yes -v $(PWD)/dbdata:/var/lib/mysql -d mysql:8.0
docker exec -it sql8 mysql -e "create database laravel;"
docker exec -it sql8 mysql -e "show databases;"
```

- Creamos un proyecto laravel en el directorio host local (Idem que lo que leíste antes).
Lanzando el comando de creación de proyecto desde una imagen por ej: srlopez/laravel:6.12
```
time docker run --rm -v $(PWD):/aqui -w /aqui -it srlopez/laravel:6.12 composer create-project --prefer-dist laravel/laravel src
```
- Editamos lo que nos interese por ejemplo en ```.env```
```
   DB_HOST=sql8
   DB_DATABASE=laravel
```
y tal vez deseemos eliminar la autenticación de Laravel en ```routes/api.php```. ¡¡¡Sólo como ejemplo!!!,  y devolver un JSON. La parte de programación de la API te toca a tí.
```
//Route::middleware('auth:api')->get('/user', function (Request $request) {
Route::get('/user', function (Request $request) {
        //return $request->user();
        return ['name' => 'api', 'email' => 'a escribir'];
});
```
- Lanzamos de nuevo la imagen, enlazada a la db para ejecutar comandos de desarrollo en este entorno (mira bien la linea de comandos).
No olvidamos publicar las puertas con las que vayamos a trabajar
```
docker run --rm --name lara6 --link sql8 -p 8000:8000 -v $(PWD)/src:/pl -w /pl -it srlopez/laravel:6.12 bash
```
y en la consola podemos trabajar
```
   php artisan migrate
   php artisan tinker
      $user = new App\User();
      $user->name = 'user1';
      $user->password = Hash::make('1234');
      $user->email = 'user1@email.com';
      $user->save();
      exit;
   php artisan route:list
   php artisan serve --host 0.0.0.0
```
En otra consola puedes jugar para ver cómo corren tus contenedores
```
docker exec -it sql8 mysql -e "use laravel; select id, name from users;"
docker ps -a
docker inspect sql8
```
## COMPOSE
para no tener que andar ejecuntando los comandos ```docker run```,  podemos componer un stack que nos agrupe las dos imágenes y podamos lanzarlas juntas:
**docker-compose.yaml**
```
version: '3.1'

services:

    api:
        image: srlopez/laravel:6.12
        container_name: api
        volumes:
            - ./src:/var/www/laravel
        working_dir: /var/www/laravel
        ports:
            - 8000:8000
        #modo desarrollo
        command: ["php","artisan", "serve", "--host=0.0.0.0"]
    
    db:
        image: mysql:8.0
        container_name: sql8
        environment:
            MYSQL_ALLOW_EMPTY_PASSWORD: "yes"
        volumes:
            - ./dbdata:/var/lib/mysql
        ports:
            - 3306:3306
```
Este archivo es el mínimo, se me ocurre que puedes añadir ```depends_on```, ```restart: always```, y/o eliminar ```container_name```, etc.



# Nota final
Este repositorio forma parte de un proyecto más grande localizado en

https://dev.azure.com/srlopez/appdocker
