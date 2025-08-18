#!/bin/bash

# Configurações globais
set -e  
LOG_FILE="/var/log/install_services.log"
TEMPDIR="/tmp/install_services"

# Senhas 
MYSQL_ROOT_PASSWORD="Admin123*"
MYSQL_COMMON_PASSWORD="Admin123*"

# Versões dos pacotes 
GRAFANA_VERSION="12.1.1"
PORTTAINER_VERSION="latest"
UNIFI_VERSION="9.3.45"
NEXTCLOUD_VERSION="latest"
GLPI_VERSION="10.0.19"

# Criar diretório temporário
mkdir -p "$TEMPDIR"

# Limpeza final
cleanup() {
    echo "Limpando arquivos temporários..."
    rm -rf "$TEMPDIR"
    apt-get autoremove -y
    apt-get clean
}

# Registrar início da instalação
echo "Iniciando instalação em $(date)" | tee "$LOG_FILE"

# Função para instalar e configurar MySQL
install_mysql() {
    echo "Instalando e configurando MySQL..." | tee -a "$LOG_FILE"
    
    # Instalar MySQL 
    DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
    
    # Configurar acesso remoto e senha root
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';"
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DELETE FROM mysql.user WHERE User='';"
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS test;"
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"
    
    # Permitir acesso remoto
    sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
    
    # Reiniciar MySQL
    systemctl restart mysql
}

# Função para instalar Apache
install_apache() {
    echo "Instalando Apache..." | tee -a "$LOG_FILE"
    apt-get install -y apache2
    systemctl enable apache2
    systemctl start apache2
    
    # Configurar firewall
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 8888/tcp
    ufw allow 8081/tcp
}

# Função para instalar Zabbix
install_zabbix() {
    echo "Instalando Zabbix..." | tee -a "$LOG_FILE"
    
    # Adicionar repositório
    wget -q -O "$TEMPDIR/zabbix.deb" \
        https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu24.04_all.deb
    dpkg -i "$TEMPDIR/zabbix.deb"
    apt-get update
    
    # Instalar pacotes com verificação de erro
    if ! apt-get install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf \
        zabbix-sql-scripts zabbix-agent wget gzip; then
        echo "Falha na instalação dos pacotes do Zabbix" | tee -a "$LOG_FILE"
        exit 1
    fi

    # Verificar onde os scripts SQL foram instalados
    SQL_SCRIPT_PATH=$(dpkg -L zabbix-sql-scripts | grep 'server.sql.gz$' | head -1)
    
    if [ -z "$SQL_SCRIPT_PATH" ]; then
        echo "Arquivo server.sql.gz não encontrado nos pacotes instalados" | tee -a "$LOG_FILE"
        echo "Procurando em locais alternativos..." | tee -a "$LOG_FILE"
        # Tentativa alternativa
        SQL_SCRIPT_PATH="/usr/share/doc/zabbix-sql-scripts/mysql/server.sql.gz"
        
        if [ ! -f "$SQL_SCRIPT_PATH" ]; then
            echo "Erro: Arquivo server.sql.gz não encontrado em nenhum local padrão" | tee -a "$LOG_FILE"
            exit 1
        fi
    fi

    echo "Usando arquivo SQL em: $SQL_SCRIPT_PATH" | tee -a "$LOG_FILE"
    
    # Criar/recriar banco de dados
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS zabbix; CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"

    # Criar/recriar usuário
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DROP USER IF EXISTS 'zabbix'@'localhost';"
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '$MYSQL_COMMON_PASSWORD';"
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';"
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SET GLOBAL log_bin_trust_function_creators = 1;"

    # Importar schema com verificação de erro
    if ! zcat "$SQL_SCRIPT_PATH" | mysql --default-character-set=utf8mb4 -uzabbix -p"$MYSQL_COMMON_PASSWORD" zabbix; then
        echo "Falha ao importar schema para o banco de dados Zabbix" | tee -a "$LOG_FILE"
        exit 1
    fi

    # Reverter configuração de segurança
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SET GLOBAL log_bin_trust_function_creators = 0;"

    # Configurar senha no Zabbix server
    sed -i "s/# DBPassword=/DBPassword=$MYSQL_COMMON_PASSWORD/" /etc/zabbix/zabbix_server.conf

    # Configurar timeout no arquivo de configuração do Zabbix
    sed -i "s/# DBConnectTimeout=5/DBConnectTimeout=10/" /etc/zabbix/zabbix_server.conf

    # Reiniciar serviços com verificação
    systemctl restart apache2
    if ! systemctl restart zabbix-server zabbix-agent; then
        echo "Falha ao iniciar serviços do Zabbix. Verificando logs..." | tee -a "$LOG_FILE"
        journalctl -xeu zabbix-server.service | tail -n 30 | tee -a "$LOG_FILE"
        exit 1
    fi
    
    systemctl enable zabbix-server zabbix-agent apache2

    echo "Zabbix instalado e configurado com sucesso!" | tee -a "$LOG_FILE"
}

# Função para instalar GLPI
install_glpi() {
    echo "Instalando GLPI..." | tee -a "$LOG_FILE"
    
    # Instalar dependências
    apt-get install -y php libapache2-mod-php php-mysql php-curl php-ldap \
        php-imap php-apcu php-gd php-xml php-mbstring php-xmlrpc php-cas \
        php-intl php-zip php8.3-bz2
    
    # Baixar e extrair GLPI
    wget -q -O "$TEMPDIR/glpi.tgz" \
        https://github.com/glpi-project/glpi/releases/download/$GLPI_VERSION/glpi-$GLPI_VERSION.tgz
    tar -xzf "$TEMPDIR/glpi.tgz" -C /var/www/html/
    chown -R www-data:www-data /var/www/html/glpi
    chmod -R 755 /var/www/html/glpi
    
    # Criar banco de dados
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE glpi CHARACTER SET utf8 COLLATE utf8_general_ci;"
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER 'glpi'@'localhost' IDENTIFIED BY '$MYSQL_COMMON_PASSWORD';"
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON glpi.* TO 'glpi'@'localhost';"
    
    # Configurar virtual host
    cat > /etc/apache2/sites-available/glpi-8888.conf <<EOF
Listen 8888
<VirtualHost *:8888>
    DocumentRoot /var/www/html/glpi
    <Directory /var/www/html/glpi>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/glpi_error.log
    CustomLog \${APACHE_LOG_DIR}/glpi_access.log combined
</VirtualHost>
EOF
    
    a2ensite glpi-8888.conf
    a2enmod rewrite
    systemctl reload apache2
}

# Função para instalar UniFi Controller
install_unifi() {
    echo "Instalando UniFi Controller..." | tee -a "$LOG_FILE"
    wget -q -O "$TEMPDIR/unifi-install.sh" \
        https://get.glennr.nl/unifi/install/unifi-$UNIFI_VERSION.sh
    bash "$TEMPDIR/unifi-install.sh"
}

# Função para instalar Grafana
GRAFANA_VERSION="12.1.1"
install_grafana() {
    echo "Instalando Grafana $GRAFANA_VERSION..." | tee -a "$LOG_FILE"
    
    # Instalar dependências necessárias
    apt-get install -y adduser libfontconfig1 musl
    
    # Baixar o pacote específico para 12.1.1
    wget -q -O "$TEMPDIR/grafana_12.1.1.deb" \
        "https://dl.grafana.com/oss/release/grafana_12.1.1_amd64.deb" || {
        echo "Falha ao baixar o pacote do Grafana 12.1.1" | tee -a "$LOG_FILE"
        exit 1
    }
    
    # Instalação com verificação de erro
    if ! dpkg -i "$TEMPDIR/grafana_12.1.1.deb"; then
        apt-get -f install -y || {
            echo "Falha ao corrigir dependências do Grafana" | tee -a "$LOG_FILE"
            exit 1
        }
    fi
    
    # Configurar e iniciar serviço
    systemctl daemon-reload
    systemctl enable grafana-server
    if ! systemctl start grafana-server; then
        echo "Falha ao iniciar o Grafana Server. Verifique os logs:" | tee -a "$LOG_FILE"
        journalctl -u grafana-server -n 50 | tee -a "$LOG_FILE"
        exit 1
    fi
    
    echo "Grafana 12.1.1 instalado com sucesso!" | tee -a "$LOG_FILE"
}

# Função para instalar Docker e Portainer
install_docker_portainer() {
    echo "Instalando Docker e Portainer..." | tee -a "$LOG_FILE"
    
    # Instalar Docker
    apt-get install -y ca-certificates curl gnupg lsb-release
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Instalar Portainer
    docker volume create portainer_data
    docker run -d -p 9000:9000 -p 9443:9443 \
        --name portainer \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:$PORTTAINER_VERSION
}

# Função para instalar Nextcloud
install_nextcloud() {
    echo "Instalando Nextcloud..." | tee -a "$LOG_FILE"
    
    # Instalar dependências
    apt-get install -y php php-gd php-curl php-zip php-xml php-mbstring \
        php-bz2 php-intl php-bcmath php-imagick php-gmp php-apcu unzip
    
    # Baixar e extrair Nextcloud
    wget -q -O "$TEMPDIR/nextcloud.zip" \
        https://download.nextcloud.com/server/releases/$NEXTCLOUD_VERSION.zip
    unzip "$TEMPDIR/nextcloud.zip" -d /var/www/html/
    chown -R www-data:www-data /var/www/html/nextcloud
    chmod -R 755 /var/www/html/nextcloud
    
    # Criar banco de dados
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY '$MYSQL_COMMON_PASSWORD';"
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost';"
    
    # Configurar virtual host
    cat > /etc/apache2/sites-available/nextcloud-8081.conf <<EOF
Listen 8081
<VirtualHost *:8081>
    DocumentRoot /var/www/html/nextcloud
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
    
    a2ensite nextcloud-8081.conf
    a2enmod headers env dir mime setenvif
    systemctl reload apache2
}

# Função para instalar CUPS
install_cups() {
    echo "Instalando CUPS..." | tee -a "$LOG_FILE"
    apt-get install -y cups
    
    # Configurar acesso remoto
    sed -i 's/^Listen localhost:631/Port 631/' /etc/cups/cupsd.conf
    sed -i '/<Location \/>/,/<\/Location>/c\<Location />\n  Order allow,deny\n  Allow all\n</Location>' /etc/cups/cupsd.conf
    sed -i '/<Location \/admin>/,/<\/Location>/c\<Location /admin>\n  Order allow,deny\n  Allow all\n</Location>' /etc/cups/cupsd.conf
    sed -i '/<Location \/admin\/conf>/,/<\/Location>/c\<Location /admin/conf>\n  Order allow,deny\n  Allow all\n</Location>' /etc/cups/cupsd.conf
    
    # Adicionar usuário ao grupo lpadmin
    usermod -aG lpadmin $USER
    
    systemctl enable cups
    systemctl restart cups
}

# Função para instalar Duplicati
install_duplicati() {
    echo "Instalando Duplicati..." | tee -a "$LOG_FILE"
    wget -q -O "$TEMPDIR/duplicati.deb" \
        https://updates.duplicati.com/beta/duplicati_2.0.7.1-1_all.deb
    dpkg -i "$TEMPDIR/duplicati.deb" || apt-get -f install -y
    systemctl enable duplicati
    systemctl start duplicati
}

# Atualizar sistema
echo "Atualizando sistema..." | tee -a "$LOG_FILE"
apt-get update
apt-get upgrade -y

# Instalar componentes
install_mysql
install_apache
install_zabbix
install_glpi
install_unifi
install_grafana
install_docker_portainer
install_nextcloud
install_cups
install_duplicati

# Limpeza final
cleanup

echo "Instalação concluída com sucesso em $(date)" | tee -a "$LOG_FILE"
echo "Acessos:"
echo " - GLPI: http://seu-ip:8888"
echo " - Nextcloud: http://seu-ip:8081"
echo " - Portainer: https://seu-ip:9443"
echo " - UniFi: https://seu-ip:8443"
echo " - Grafana: http://seu-ip:3000"
echo " - Duplicati: http://seu-ip:8200"
echo " - CUPS: http://seu-ip:631"
