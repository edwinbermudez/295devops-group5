#!/bin/bash

#Declaración de variables
DISTRO=$(lsb_release -ds)
USERID=$(id -u)
REPO="https://github.com/roxsross/bootcamp-devops-2023.git"
FOLDER="bootcamp-devops-2023"
RAMA="clase2-linux-bash"
APP="app-295devops-travel"
Config_Apache="/etc/apache2/mods-enabled/dir.conf"
Config_php="$FOLDER/$APP/config.php"

#Validation root user
if [[ "${USERID}" -ne "0" ]]; then
echo -e "\n${LRED} Debe ser usuario ROOT. ${NC}"
exit 1
fi 

#Paquetes para el servidor LAMP
paquetes=(
  curl  
  git
  php
  libapache2-mod-php
  php-mysql
  php-mbstring
  php-zip
  php-gd
  php-json
  php-curl
  tree
)

#Servicios MariaDB y Apache2
servicios=(
mariadb-server
apache2
)

#Definición de colores
LRED='\033[1;31m'
LGREEN='\033[1;32m'
LYELLOW='\033[1;33m'
LBLUE='\033[1;34m'
NC='\033[0m'

InstalarPaquetes() {
  local paquetes=("$@")
  for paquete in "${paquetes[@]}"; do
    dpkg -s "$paquete" &> /dev/null
    if [ $? -eq 0 ]; then
      sleep 1
      echo -e "\n${LBLUE}$paquete ya se encuentra instalado${NC}"
    else
      apt install "$paquete" -y 
      if [ $? -ne 0 ]; then
        echo -e "\n${LRED}Error la instalar $paquete${NC}"
        exit 1
      fi
    fi
  done
}

ValidacionServicios() {
  local servicios=("$@")
  for servicio in "${servicios[@]}"; do
    
    apt install -y "$servicio"
    if [ $? -eq 0 ]; then
      systemctl start "$servicio"
      systemctl enable "$servicio"
      case $servicio in
        mariadb-server)
          echo -e "${LGREEN} -------- Verificando el estado del servicio de MARIADB -------- ${NC}"
          mysql --version
          if systemctl is-active --quiet mariadb; then
            echo -e "${LBLUE}MariaDB esta operativa.${NC}"
          else
            echo -e "${LRED}MariaDB no esta operativa. ${NC}"
          fi
          ;;
        apache2)
          echo -e "${LGREEN} -------- Verificando el estado del servicio de APACHE -------- ${NC}"
          apache2 -v
          if systemctl is-active --quiet apache2; then
            echo -e "${LBLUE}Apache esta funcionando.${NC}"
          else
            echo -e "${LRED}Apache NO esta funcionando. ${NC}"
          fi
          ;;
      esac
      
    else
        echo -e "${LRED}Error en la instalación del $servicio.${NC}"
    fi
  done
}

#Clonar repositorio
ClonarRepo() {
  if [ -d "$FOLDER" ]; then
    echo -e "\n${LBLUE}La carpeta $FOLDER existe ...${NC}"
    cd $FOLDER
    git pull origin $RAMA
    cd ~
  else
    echo -e "${LBLUE} ---- Se esta clonando el repositorio $REPO. ---- ${NC}"
    git clone $REPO --single-branch --branch $RAMA
    git config --global user.email "ing_edwinbermudez@outlook.com"
    git config --global user.name "Edwin Bermúdez"
  fi
}

#Configuración del servicio Apache2
ConfiguracionApache() {
  echo -e "\n ${LBLUE} Validación de PHP.${NC}"
  php -v
  if [ -f "$Config_Apache" ]; then
    sed -i 's/DirectoryIndex.*/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/g' "$Config_Apache"
    echo -e "${LBLUE} Se ha actualizado el orden en el archivo $Config_Apache ${NC}"
    systemctl reload apache2
  else
    echo "\n${LRED} El archivo $Config_Apache no existe.${NC}"
  fi
}

#Configuración PHP
ConfigPHP() {
  pwd
  if [ -f "$Config_php" ]; then
    sed -i 's/$dbPassword = "";/&\n$dbPassword = "codepass";/' "$Config_php"
    echo -e "${LBLUE} La contraseña de la base de datos fue insertada en $Config_php ${NC}" 
    # Copiar contenido de la carpeta app-295devops-travel a ruta /var/www/html
    if [ -f "/var/www/html/index.html" ]; then
      mv /var/www/html/index.html /var/www/html/index.html.bkp
    fi
    cp -R $FOLDER/$APP/* /var/www/html/
    echo -e "${LBLUE} Se ha copiado los archivos a la ruta /var/www/html. ${NC}" 
    sudo systemctl reload apache2
  else
    echo -e "${LRED}El archivo $Config_php no existe. Por favor validar.${NC}"
    exit 
  fi
}

#Configuración de la base de datos
ConfiguracionDB() {
  if systemctl is-active --quiet mariadb; then
    echo -e "${LBLUE}MariaDB es funcionando.${NC}"
    if mysql -e "USE devopstravel;" 2>/dev/null; then
      echo -e "\n${LBLUE}La base de datos 'devopstravel' ya existe ...${NC}"
    else
      echo -e "\n${LBLUE}Configurando base de datos ...${NC}"
      mysql -e "
      CREATE DATABASE devopstravel;
      CREATE USER 'codeuser'@'localhost' IDENTIFIED BY 'codepass';
      GRANT ALL PRIVILEGES ON *.* TO 'codeuser'@'localhost';
      FLUSH PRIVILEGES;"
      mysql < $FOLDER/$APP/database/devopstravel.sql
    fi 
  else
    echo -e "${LRED}MariaDB NO esta funcionando.${NC}"
  fi
}
#Validación PHP
ValidarPHP() {
  HTTP_STATUS=$(curl -sSL -w "%{http_code}" http://localhost/index.php -o /dev/null)
  if [ "$HTTP_STATUS" == "200" ]; then
    echo -e "${LBLUE} La página está funcionando correctamente 295DevOpsTravel $HTTP_STATUS ${NC}"
  else
    echo -e "${LRED} Lamentamos el incoveniente pero la página no está funcionado en el momento. ${NC}"
  fi
}

NotificacionDiscord () {
    discord_key="https://discord.com/api/webhooks/1169002249939329156/7MOorDwzym-yBUs3gp0k5q7HyA42M5eYjfjpZgEwmAx1vVVcLgnlSh4TmtqZqCtbupov"
    # Verifica si se proporcionó el argumento del directorio del repositorio
    git clone https://github.com/edwinbermudez/295devops-group5.git
    cd 295devops-group5

    #if [ $# -ne 1 ]; then
    #    echo "Uso: $0 295devops-group5"
    #    exit 1
    #fi

    # Obtiene el nombre del repositorio
    REPO_NAME=$(basename $(git rev-parse --show-toplevel))
    # Obtiene la URL remota del repositorio
    REPO_URL=$(git remote get-url origin)
    WEB_URL="localhost"
    # Realiza una solicitud HTTP GET a la URL
    HTTP_STATUS=$(curl -Is "$WEB_URL" | head -n 1)

    #echo $REPO_NAME
    #echo $REPO_URL
    #echo $WEB_URL
    #echo $HTTP_STATUS

    #git config --global --add safe.directory $REPO_DIR

    if [[ "$HTTP_STATUS" == *"200 OK"* ]]; then
        # Obtén información del repositorio
        DEPLOYMENT_INFO2="Despliegue del repositorio $REPO_NAME: "
        DEPLOYMENT_INFO="La página web $WEB_URL está en línea."
        COMMIT="Commit: $(git rev-parse --short HEAD)"
        AUTHOR="Autor: $(git log -1 --pretty=format:'%an')"
        DESCRIPTION="Descripción: $(git log -1 --pretty=format:'%s')"
    else
      DEPLOYMENT_INFO="La página web $WEB_URL no está en línea."
    fi

    #echo $DEPLOYMENT_INFO2
    #echo $DEPLOYMENT_INFO
    #echo $COMMIT
    #echo $AUTHOR
    #echo $DESCRIPTION
    
    # Construye el mensaje
    MESSAGE="$DEPLOYMENT_INFO2\n$DEPLOYMENT_INFO\n$COMMIT\n$AUTHOR\n$REPO_URL\n$DESCRIPTION"

    echo "$MESSAGE"
    # Envía el mensaje a Discord utilizando la API de Discord
    curl -X POST -H "Content-Type: application/json" \
         -d '{
           "content": "'"${MESSAGE}"'"
         }' "$discord_key"

}
#--------------------------------------------------------------------------------------------------#
#Function Stage1 Instalación de paquetes nuevos y validación de los servicios y paquetes instalados  
Stage1() {
  echo -e "${LGREEN} -------------------- Actualizando paquetes existentes ----------------${NC}"
  sudo apt-get update -y
  echo -e "${LGREEN} -------------------- Instalando nuevos paquetes ----------------${NC}"
  InstalarPaquetes "${paquetes[@]}"
  
  echo -e "${LGREEN} -------------------- Validacion de los servicios --------------------${NC}"
  ValidacionServicios "${servicios[@]}"
}
Stage2() {
  echo -e "${LGREEN} -------------------- Clonación de Repositorio ----------------${NC}"
  ClonarRepo
  echo -e "${LGREEN} -------------------- Configuración del servidor Apache ----------------${NC}"
  ConfiguracionApache
  }
Stage3() {
  echo -e "${LGREEN} -------------------- Configuración de la página web----------------${NC}"
  ConfigPHP
  echo -e "${LGREEN} -------------------- Configuración de la base de datos MariaDB ----------------${NC}"
  ConfiguracionDB
  echo -e "${LGREEN} -------------------- Validación de la página Web ----------------${NC}"
  ValidarPHP
}
Stage4() {
  echo -e "${LGREEN} -------------------- Notificación al canal de Discord ----------------${NC}"
  NotificacionDiscord
}

#--------------- STAGES ------------------------#  

#Instalación
Stage1

#Build
Stage2

#Deploy
Stage3

#Notification
Stage4
