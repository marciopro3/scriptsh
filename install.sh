#!/bin/bash

# Senha fixa para ambiente de teste
MYSQL_ROOT_PASSWORD="Admin123*"
MYSQL_COMMON_PASSWORD="Admin123*"

# Atualizar repositórios e pacotes
echo "Atualizando lista de pacotes e sistema."
sudo apt update
sudo apt upgrade -y

# Instalar MySQL
echo "Instalando o MySQL."
sudo apt install mysql-server -y

# Configurar MySQL
echo "Configurando o MySQL."
sudo mysql_secure_installation

# Aceitar acesso remoto
echo "Permitindo acesso externo ao MySQL."
sudo sed -i 's/bind-address = 127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

# Instalar pacotes necessários
echo "Instalando pacotes necessários."
sudo apt install -y wget curl gnupg2 software-properties-common

# Instalar Apache
echo "Instalando o Apache."
sudo apt install apache2 -y

# Configurar firewall
echo "Configurando o firewall."
sudo ufw allow 8888/tcp
sudo ufw allow 8081/tcp

# Reiniciar o Apache
echo "Reiniciando o Apache."
sudo systemctl restart apache2
sudo systemctl enable apache2

# Adicionar repositório do Zabbix
echo "Adicionando repositório do Zabbix."
wget https://repo.zabbix.com/zabbix/7.2/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.2+ubuntu24.04_all.deb
sudo dpkg -i zabbix-release_latest_7.2+ubuntu24.04_all.deb
sudo apt update

# Instalar Zabbix
echo "Instalando Zabbix Server, Frontend e Agent."
sudo apt install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent -y

# Criar banco de dados do Zabbix
echo "Criando banco de dados do Zabbix."
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE zabbix CHARACTER SET utf8 COLLATE utf8_bin;"
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '$MYSQL_COMMON_PASSWORD';"
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';"
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SET GLOBAL log_bin_trust_function_creators = 1;"
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

# Importar schema
echo "Importando schema do Zabbix."
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p"$MYSQL_COMMON_PASSWORD" zabbix

# Reverter configuração de segurança após a importação
echo "Revertendo log_bin_trust_function_creators para 0 (boa prática de segurança)."
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SET GLOBAL log_bin_trust_function_creators = 0;"

# Configurar senha no Zabbix server
sudo sed -i "s/# DBPassword=/DBPassword=$MYSQL_COMMON_PASSWORD/" /etc/zabbix/zabbix_server.conf

# Iniciar serviços
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2

# Instalar GLPI
echo "Instalando GLPI."
sudo apt install -y apache2 php libapache2-mod-php php-mysql php-curl php-ldap php-imap php-apcu php-gd php-xml php-mbstring php-xmlrpc php-cas php-intl php-zip php8.3-bz2
wget https://github.com/glpi-project/glpi/releases/download/10.0.18/glpi-10.0.18.tgz  
tar -xvzf glpi-10.0.18.tgz  
sudo mv glpi /var/www/html/glpi
sudo chown -R www-data:www-data /var/www/html/glpi
sudo chmod -R 755 /var/www/html/glpi

# Criar banco de dados do GLPI
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE glpi CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER 'glpi'@'localhost' IDENTIFIED BY '$MYSQL_COMMON_PASSWORD';"
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON glpi.* TO 'glpi'@'localhost';"
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

# Configurar Apache para GLPI na porta 8888
echo "Configurando Apache para GLPI na porta 8888."
cat <<EOF | sudo tee /etc/apache2/sites-available/glpi-8888.conf
Listen 8888
<VirtualHost *:8888>
    ServerAdmin admin@sj.ddns.net
    DocumentRoot /var/www/html/glpi
    ServerName sj.ddns.net

    <Directory /var/www/html/glpi>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/glpi_error.log
    CustomLog \${APACHE_LOG_DIR}/glpi_access.log combined
</VirtualHost>
EOF

sudo a2ensite glpi-8888.conf
sudo a2enmod rewrite
sudo systemctl reload apache2

# Instalar UniFi Controller
echo "Instalando UniFi Controller."
sudo apt-get install -y ca-certificates curl
curl -sO https://get.glennr.nl/unifi/install/unifi-9.2.87.sh && bash unifi-9.2.87.sh

# Instalar Grafana
echo "Instalando Grafana."
sudo apt-get install -y adduser libfontconfig1 musl
wget https://dl.grafana.com/oss/release/grafana_12.0.2_amd64.deb
sudo dpkg -i grafana_12.0.2_amd64.deb
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

# Instalar Docker
echo "Instalando Docker."
sudo apt install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Instalar Portainer
echo "Instalando Portainer."
docker volume create portainer_data
docker run -d -p 9000:9000 -p 9443:9443 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

echo "Portainer disponível em: https://sj.ddns.net:9443"

# Instalar Nextcloud
echo "Instalando dependências do Nextcloud."
sudo apt install -y php php-gd php-curl php-zip php-xml php-mbstring php-bz2 php-intl php-bcmath php-imagick php-gmp php-apcu unzip

echo "Baixando Nextcloud."
cd /tmp
wget https://download.nextcloud.com/server/releases/latest.zip
unzip latest.zip
sudo mv nextcloud /var/www/html/nextcloud
sudo chown -R www-data:www-data /var/www/html/nextcloud
sudo chmod -R 755 /var/www/html/nextcloud

# Criar banco de dados do Nextcloud
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY '$MYSQL_COMMON_PASSWORD';"
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost';"
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

# Apache para Nextcloud na porta 8081
echo "Configurando Apache para Nextcloud na porta 8081."
cat <<EOF | sudo tee /etc/apache2/sites-available/nextcloud-8081.conf
Listen 8081
<VirtualHost *:8081>
    ServerAdmin admin@sj.ddns.net
    DocumentRoot /var/www/html/nextcloud
    ServerName sj.ddns.net

    <Directory /var/www/html/nextcloud>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog \${APACHE_LOG_DIR}/nextcloud_access.log combined
</VirtualHost>
EOF

sudo a2ensite nextcloud-8081.conf
sudo a2enmod headers env dir mime setenvif
sudo systemctl reload apache2
sudo systemctl restart apache2

# Fim
echo "Instalação concluída!"
echo "GLPI: http://sj.ddns.net:8888"
echo "Nextcloud: http://sj.ddns.net:8081"
echo "Portainer: https://sj.ddns.net:9443"
echo "Usuários MySQL criados com a senha padrão: Admin123*"
