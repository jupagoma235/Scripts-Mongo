########################################################################################################
#    * Version Sistema Operativo usado en pruebas : Ubuntu 18.04.06 Bionic                             #
#    * Version Mongo 4.2.1                                                                             # 
########################################################################################################

-> Se crean dos versiones del script, una en Batch y la otra con SHELL; ya que inicialmente se 
trabaja con la info recomendada y se encuentra que corresponde a Batch.

->Se encuentra que los dos lenguajes tienen diferencias en el reconocimiento de las variables, 
es asi que Batch permite la utilizacion de source para importar la info del archivo ini, mientras
que en SHELL se debe llamar desde la ruta "./"; asi mismo, en Batch se utilizan dobles "[[" para 
abrir los condicionales, mientras que en SHELL no.

-> Para ejecutar los scritps se debe tener permisos de superusuario "SU", de lo contrario se presentaran 
errores al intentar modificar el archivo de Key para mongo; sin embargo y aun con estos, se encuentra que 
el script hay que lanzarlo con sudo, ya que en ocaciones generar error al crear el usuario en la bd.

-> Se recomienda que al copiar el archivo config.ini se den nuevamente permisos de lectura en el mismo
ya que en varias ocaciones generaba error al leerlo por permisos.

-> Para realizar la depuracion correspondiente se utiliza -x antes de llamar el script.

Para ejecutar el archivo con Batch
Directorio: ./Realizado en bach con bash Instalar-mongo
Ejecución : sudo bash -x Instalar-mongodb.bat -f config.ini
Extensión : bat
Codificación : UTF8

Para ejecutar el archivo con SHELL
Directorio: Realizado en shell Instalar-mongodb
Ejecución : sudo sh -x Instalar-mongodb.sh -f config.ini
Extensión : sh
Codificación : ANSI
