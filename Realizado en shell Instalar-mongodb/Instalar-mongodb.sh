#!/bin/bash
set -e

# *Se hace debug con bash -x nombre del script

# *Se elimina la definicion de funcion ya que esta se llama ayuda
ayuda() {
    echo "Uso : $0 -f archivo_config
    Ejemplo:
    $0 -f config.ini"
}

# *Manejar los argumentos cuando se ingresa como parametro -f, busca el archivo y lo carga en la variable
while getopts ":f:" OPCION; do
    case ${OPCION} in
        f ) ARCHIVO_CONFIG=$OPTARG ;;		
        \? ) ayuda; exit 1 ; echo $OPCION;;
    esac
done

# *Verificar si se proporciona el archivo de configuración
if [ -z ${ARCHIVO_CONFIG} ]; then
    ayuda; exit 1
fi

# *Leer las configuraciones desde el archivo para extraer el valor de las variables
if [ -f ${ARCHIVO_CONFIG} ]; then
    ./${ARCHIVO_CONFIG}
	USER=$(grep "^user=" "$ARCHIVO_CONFIG" | awk -F'=' '{print $2}' | tr -d '[:space:]')
    PASSWORD=$(grep "^password=" "$ARCHIVO_CONFIG" | awk -F'=' '{print $2}' | tr -d '[:space:]')
    PORT=$(grep "^port=" "$ARCHIVO_CONFIG" | awk -F'=' '{print $2}' | tr -d '[:space:]')
else
    echo "Error: El archivo de configuración '${ARCHIVO_CONFIG}' no existe."
    exit 1
fi

# Establecer puerto por defecto si no se proporciona
if [ -z ${PUERTO_MONGOD} ]; then
    PUERTO_MONGOD=27017
fi

# Preparar el repositorio (apt-get) de MongoDB y añadir su clave apt
# Se cambia la dirección ya que la que trae el script por proporcionado genera error http 404 se toma la direccion de (https://www.techunits.com/topics/setup-guides/step-by-step-guide-to-install-mongodb-4-2-on-ubuntu-18-04-lts/)
# Se cambia la instalación de xenial a bionic.
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 4B7C549A058F8B6B
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb.list
sudo apt update

# Verificar si la versión de MongoDB ya está instalada
if [ -z "$(mongo --version 2> /dev/null | grep '4.2.1')" ]; then
    # Instalar paquetes MongoDB
    sudo apt-get -y update \
    && apt-get install -y \
    mongodb-org=4.2.1 \
    mongodb-org-server=4.2.1 \
    mongodb-org-shell=4.2.1 \
    mongodb-org-mongos=4.2.1 \
    mongodb-org-tools=4.2.1 \
    && rm -rf /var/lib/apt/lists/* \
    && pkill -u mongodb || true \
    && pkill -f mongod || true \
    && rm -rf /var/lib/mongodb
fi

# Crear las carpetas de logs y datos con sus permisos
[ -d "/datos/bd" ] || mkdir -p -m 755 "/datos/bd"
[ -d "/datos/log" ] || mkdir -p -m 755 "/datos/log"

# Establecer el dueño y el grupo de las carpetas db y log
chown mongodb /datos/log /datos/bd
chgrp mongodb /datos/log /datos/bd

# Crear el archivo de configuración de MongoDB con el puerto solicitado
cat <<MONGOD_CONF > /etc/mongod.conf
# /etc/mongod.conf
systemLog:
  destination: file
  path: /datos/log/mongod.log
  logAppend: true
storage:
  dbPath: /datos/bd
  engine: wiredTiger
  journal:
    enabled: true
net:
  port: ${PUERTO_MONGOD}
security:
  authorization: enabled
MONGOD_CONF

# Iniciar el servicio de mongod
sudo systemctl start mongod

# Comprobar si el servicio de mongod ha arrancado correctamente, esto se hace mediante un ciclo que lanza la validacion al sistema cada segundo hasta que reciba una respuesta donde MONGO_PID no este vacio.
MONGO_PID=$(pgrep -f mongod)
while [ -z "${MONGO_PID}" ]; do
    sleep 1
    MONGO_PID=$(pgrep -f mongod)
done
#Validacion de que variables tienen los valores correctos
echo "Usuario: ${USER}"
echo "Contraseña: ${PASSWORD}"
# Crear usuario con la password proporcionada como parámetro
# Se cambia la variable ya que llama a USUARIO y es USER
sudo mongo admin << CREACION_DE_USUARIO
db.createUser({
  user: "${USER}",
  pwd: "${PASSWORD}",
  roles: [{
    role: "root",
    db: "admin"
  }, {
    role: "restore",
    db: "admin"
  }]
})
CREACION_DE_USUARIO

logger "El usuario ${USUARIO} ha sido creado con éxito!"
exit 0
