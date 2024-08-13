#!/bin/bash

# Atualizar repositórios e pacotes
echo "Atualizando lista de pacotes e sistema."
sudo apt update
sudo apt upgrade -y

# Instalar MySQL
echo "Instalando o MYSQL."
sudo apt install mysql-server -y

# Configurar MySQL
echo "Configurando o MYSQL."
sudo mysql_secure_installation

# Aceitar acesso remoto
echo "Acesso externo no MYSQL."
sudo sed -i 's/bind-address = 127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

# Instalar pacotes necessários
echo "Instalando pacotes necessários."
sudo apt install -y wget curl gnupg2 software-properties-common

# Adicionar repositório do Zabbix
echo "Adicionando pacotes do ZABBIX."
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-2+ubuntu24.04_all.deb
sudo dpkg -i zabbix-release_7.0-2+ubuntu24.04_all.deb
sudo apt update

# Instalar Zabbix server, frontend e agent
echo "Instalando O ZABBIX server, front e agent."
sudo apt install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent -y

# Criar banco de dados do Zabbix
echo "Criando banco de dados do ZABBIX."
sudo mysql -uroot -p -e "CREATE DATABASE zabbix CHARACTER SET utf8 COLLATE utf8_bin;"
sudo mysql -uroot -p -e "CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'suasenha';"
sudo mysql -uroot -p -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';"
sudo mysql -uroot -p -e "set global log_bin_trust_function_creators = 1;"
sudo mysql -uroot -p -e "FLUSH PRIVILEGES;"

# Importar esquema inicial e dados
echo "Importando esquema inicial e dados."
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix

# Configurar o banco de dados no Zabbix server
echo "Configurar o banco de dados no Zabbix server."
sudo sed -i 's/# DBPassword=/DBPassword=suasenha/' /etc/zabbix/zabbix_server.conf

# Iniciar e habilitar Zabbix server e agent
echo "Iniciar e habilitar Zabbix server e agent."
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2

# Instalar GLPI
echo "Instalar GLPI."
sudo apt install apache2 php libapache2-mod-php php-mysql php-curl php-ldap php-imap php-apcu php-gd php-xml php-mbstring php-xmlrpc php-cas php-intl php-zip -y
wget https://github.com/glpi-project/glpi/releases/download/10.0.16/glpi-10.0.16.tgz
tar -xvzf glpi-10.0.16.tgz
sudo mv glpi /var/www/html/glpi
sudo chown -R www-data:www-data /var/www/html/glpi
sudo chmod -R 755 /var/www/html/glpi

# Criar banco de dados do GLPI
echo "Criar banco de dados do GLPI."
sudo mysql -uroot -p -e "CREATE DATABASE glpi CHARACTER SET utf8 COLLATE utf8_general_ci;"
sudo mysql -uroot -p -e "CREATE USER 'glpi'@'localhost' IDENTIFIED BY 'suasenha';"
sudo mysql -uroot -p -e "GRANT ALL PRIVILEGES ON glpi.* TO 'glpi'@'localhost';"
sudo mysql -uroot -p -e "FLUSH PRIVILEGES;"

# Configurar Apache para GLPI
echo "Configurar Apache para GLPI."
cat <<EOF | sudo tee /etc/apache2/sites-available/glpi.conf
<VirtualHost *:80>
    ServerAdmin admin@example.com
    DocumentRoot /var/www/html/glpi
    ServerName localhost

    <Directory /var/www/html/glpi>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/glpi_error.log
    CustomLog \${APACHE_LOG_DIR}/glpi_access.log combined
</VirtualHost>
EOF

sudo apt install php8.3-bz2
sudo a2ensite glpi
sudo systemctl reload apache2
sudo a2ensite glpi.conf
sudo a2enmod rewrite
sudo systemctl restart apache2

# Instalar UniFi Controller
echo "Instalar UniFi Controller."
apt-get update; apt-get install ca-certificates curl -y

curl -sO https://get.glennr.nl/unifi/install/unifi-8.3.32.sh && bash unifi-8.3.32.sh

# Instalação do Grafana
echo "Instalação do Grafana."
sudo apt-get install -y adduser libfontconfig1 musl
wget https://dl.grafana.com/oss/release/grafana_11.1.0_amd64.deb
sudo dpkg -i grafana_11.1.0_amd64.deb

# Ativando o serviço
echo "Ativando o Grafana."
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

# Instala o Samba
sudo apt install samba -y

# Cria o diretório para compartilhamento
sudo mkdir -p /srv/samba/shared
sudo chown nobody:nogroup /srv/samba/shared
sudo chmod 2775 /srv/samba/shared
sudo chown -R :sambashare /srv/samba/shared

# Verifica se o bloco já existe e adiciona se necessário
if ! grep -q "\[shared\]" /etc/samba/smb.conf; then
    cat <<EOL | sudo tee -a /etc/samba/smb.conf

[shared]
   path = /srv/samba/shared
   browseable = yes
   read only = no
   guest ok = yes
   force group = sambashare
   create mask = 0660
   directory mask = 2770
EOL
fi

# Reinicia o serviço do Samba
sudo systemctl restart smbd

echo "Instalação concluída. Configure cada serviço conforme necessário."
