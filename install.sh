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

# Variáveis de controle de instalação
MYSQL_INSTALLED=0
APACHE_INSTALLED=0
ZABBIX_INSTALLED=0
GLPI_INSTALLED=0
UNIFI_INSTALLED=0
GRAFANA_INSTALLED=0
DOCKER_INSTALLED=0
NEXTCLOUD_INSTALLED=0
DUPLICATI_INSTALLED=0
CUPS_INSTALLED=0
KUMA_INSTALLED=0

# Cores para o menu
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Função para verificar se MySQL está acessível
check_mysql_access() {
    if mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Função para reconfigurar MySQL se necessário
reconfigure_mysql() {
    echo -e "${YELLOW}Problema de acesso ao MySQL detectado. Tentando reconfigurar...${NC}"
    
    # Parar MySQL
    systemctl stop mysql
    
    # Iniciar MySQL sem verificação de autenticação
    mysqld_safe --skip-grant-tables &
    sleep 5
    
    # Redefinir senha root
    mysql <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';
FLUSH PRIVILEGES;
EOF
    
    # Parar MySQL seguro e reiniciar normalmente
    pkill mysqld
    sleep 3
    systemctl start mysql
    
    # Verificar se funcionou
    if check_mysql_access; then
        echo -e "${GREEN}✅ MySQL reconfigurado com sucesso!${NC}"
        return 0
    else
        echo -e "${RED}❌ Falha ao reconfigurar MySQL${NC}"
        return 1
    fi
}

# Função para verificar se um serviço está instalado
check_service_installed() {
    local service_name="$1"
    case $service_name in
        mysql)
            [ $MYSQL_INSTALLED -eq 1 ] && return 0 || return 1
            ;;
        apache)
            [ $APACHE_INSTALLED -eq 1 ] && return 0 || return 1
            ;;
        zabbix)
            [ $ZABBIX_INSTALLED -eq 1 ] && return 0 || return 1
            ;;
        glpi)
            [ $GLPI_INSTALLED -eq 1 ] && return 0 || return 1
            ;;
        unifi)
            [ $UNIFI_INSTALLED -eq 1 ] && return 0 || return 1
            ;;
        grafana)
            [ $GRAFANA_INSTALLED -eq 1 ] && return 0 || return 1
            ;;
        docker)
            [ $DOCKER_INSTALLED -eq 1 ] && return 0 || return 1
            ;;
        nextcloud)
            [ $NEXTCLOUD_INSTALLED -eq 1 ] && return 0 || return 1
            ;;
        duplicati)
            [ $DUPLICATI_INSTALLED -eq 1 ] && return 0 || return 1
            ;;
        cups)
            [ $CUPS_INSTALLED -eq 1 ] && return 0 || return 1
            ;;
        kuma)
            [ $KUMA_INSTALLED -eq 1 ] && return 0 || return 1
            ;;
        *)
            return 1
            ;;
    esac
}

# Função para exibir menu principal
show_main_menu() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        MENU DE INSTALAÇÃO - SERVIDOR   ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}1.${NC} Instalar MySQL $(check_service_installed mysql && echo -e "${GREEN}[INSTALADO]${NC}" || echo -e "${RED}[NÃO INSTALADO]${NC}")"
    echo -e "${GREEN}2.${NC} Instalar Apache $(check_service_installed apache && echo -e "${GREEN}[INSTALADO]${NC}" || echo -e "${RED}[NÃO INSTALADO]${NC}")"
    echo -e "${GREEN}3.${NC} Instalar Zabbix $(check_service_installed zabbix && echo -e "${GREEN}[INSTALADO]${NC}" || echo -e "${RED}[NÃO INSTALADO]${NC}")"
    echo -e "${GREEN}4.${NC} Instalar GLPI $(check_service_installed glpi && echo -e "${GREEN}[INSTALADO]${NC}" || echo -e "${RED}[NÃO INSTALADO]${NC}")"
    echo -e "${GREEN}5.${NC} Instalar UniFi Controller $(check_service_installed unifi && echo -e "${GREEN}[INSTALADO]${NC}" || echo -e "${RED}[NÃO INSTALADO]${NC}")"
    echo -e "${GREEN}6.${NC} Instalar Grafana $(check_service_installed grafana && echo -e "${GREEN}[INSTALADO]${NC}" || echo -e "${RED}[NÃO INSTALADO]${NC}")"
    echo -e "${GREEN}7.${NC} Instalar Docker e Portainer $(check_service_installed docker && echo -e "${GREEN}[INSTALADO]${NC}" || echo -e "${RED}[NÃO INSTALADO]${NC}")"
    echo -e "${GREEN}8.${NC} Instalar Nextcloud $(check_service_installed nextcloud && echo -e "${GREEN}[INSTALADO]${NC}" || echo -e "${RED}[NÃO INSTALADO]${NC}")"
    echo -e "${GREEN}9.${NC} Instalar Duplicati $(check_service_installed duplicati && echo -e "${GREEN}[INSTALADO]${NC}" || echo -e "${RED}[NÃO INSTALADO]${NC}")"
    echo -e "${GREEN}10.${NC} Instalar CUPS $(check_service_installed cups && echo -e "${GREEN}[INSTALADO]${NC}" || echo -e "${RED}[NÃO INSTALADO]${NC}")"
    echo -e "${GREEN}11.${NC} Instalar Uptime Kuma $(check_service_installed kuma && echo -e "${GREEN}[INSTALADO]${NC}" || echo -e "${RED}[NÃO INSTALADO]${NC}")"
    echo -e "${GREEN}12.${NC} Instalar TUDO"
    echo -e "${GREEN}13.${NC} Mostrar status dos serviços"
    echo -e "${GREEN}14.${NC} Reparar MySQL"
    echo -e "${GREEN}0.${NC} Sair"
    echo -e "${BLUE}========================================${NC}"
}

# Função para exibir submenu de confirmação
confirm_installation() {
    local service_name="$1"
    echo -e "${YELLOW}Deseja instalar $service_name? (s/N)${NC}"
    read -r response
    case $response in
        [sS][iI][mM]|[sS]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Função para verificar dependências
check_dependencies() {
    local service="$1"
    local missing_deps=()
    
    case $service in
        zabbix|glpi|nextcloud)
            if ! check_service_installed mysql || ! check_mysql_access; then
                missing_deps+=("MySQL (acessível)")
            fi
            if ! check_service_installed apache; then
                missing_deps+=("Apache")
            fi
            ;;
    esac
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}Erro: $service requer as seguintes dependências:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo -e "  - $dep"
        done
        echo -e "${YELLOW}Por favor, instale as dependências primeiro.${NC}"
        return 1
    fi
    
    return 0
}

# Função para mostrar status dos serviços
show_services_status() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        STATUS DOS SERVIÇOS INSTALADOS  ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "MySQL: $(check_service_installed mysql && check_mysql_access && echo -e "${GREEN}INSTALADO E ACESSÍVEL${NC}" || echo -e "${RED}NÃO INSTALADO/INACESSÍVEL${NC}")"
    echo -e "Apache: $(check_service_installed apache && echo -e "${GREEN}INSTALADO${NC}" || echo -e "${RED}NÃO INSTALADO${NC}")"
    echo -e "Zabbix: $(check_service_installed zabbix && echo -e "${GREEN}INSTALADO${NC}" || echo -e "${RED}NÃO INSTALADO${NC}")"
    echo -e "GLPI: $(check_service_installed glpi && echo -e "${GREEN}INSTALADO${NC}" || echo -e "${RED}NÃO INSTALADO${NC}")"
    echo -e "UniFi: $(check_service_installed unifi && echo -e "${GREEN}INSTALADO${NC}" || echo -e "${RED}NÃO INSTALADO${NC}")"
    echo -e "Grafana: $(check_service_installed grafana && echo -e "${GREEN}INSTALADO${NC}" || echo -e "${RED}NÃO INSTALADO${NC}")"
    echo -e "Docker: $(check_service_installed docker && echo -e "${GREEN}INSTALADO${NC}" || echo -e "${RED}NÃO INSTALADO${NC}")"
    echo -e "Nextcloud: $(check_service_installed nextcloud && echo -e "${GREEN}INSTALADO${NC}" || echo -e "${RED}NÃO INSTALADO${NC}")"
    echo -e "Duplicati: $(check_service_installed duplicati && echo -e "${GREEN}INSTALADO${NC}" || echo -e "${RED}NÃO INSTALADO${NC}")"
    echo -e "CUPS: $(check_service_installed cups && echo -e "${GREEN}INSTALADO${NC}" || echo -e "${RED}NÃO INSTALADO${NC}")"
    echo -e "Uptime Kuma: $(check_service_installed kuma && echo -e "${GREEN}INSTALADO${NC}" || echo -e "${RED}NÃO INSTALADO${NC}")"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${YELLOW}Pressione Enter para voltar ao menu principal...${NC}"
    read -r
}

# Função para instalar e configurar MySQL
install_mysql() {
    if confirm_installation "MySQL"; then
        echo "Instalando e configurando MySQL..." | tee -a "$LOG_FILE"
        
        # Instalar MySQL
        DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
        
        # Parar MySQL para reconfigurar
        systemctl stop mysql
        
        # Configurar bind-address para acesso externo (opcional)
        echo -e "[mysqld]\nbind-address = 0.0.0.0" > /etc/mysql/conf.d/custom.cnf
        
        # Iniciar MySQL
        systemctl start mysql
        
        # Configurar senha root apenas na primeira vez (sem senha inicial)
        mysql --user=root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
        
        # Verificar se a configuração foi bem sucedida
        if check_mysql_access; then
            # Limpar usuários e banco de teste
            mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DELETE FROM mysql.user WHERE User='';"
            mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
            mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS test;"
            mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"
            
            MYSQL_INSTALLED=1
            echo -e "${GREEN}✅ MySQL instalado com sucesso!${NC}"
        else
            echo -e "${RED}❌ Falha na configuração do MySQL. Use a opção 14 para reparar.${NC}"
        fi
        
        sleep 2
    fi
}

# Função para reparar MySQL
repair_mysql() {
    echo -e "${YELLOW}Reparando instalação do MySQL...${NC}"
    
    if reconfigure_mysql; then
        MYSQL_INSTALLED=1
        echo -e "${GREEN}✅ MySQL reparado com sucesso!${NC}"
    else
        echo -e "${RED}❌ Falha ao reparar MySQL. Tente reinstalar manualmente.${NC}"
    fi
    
    sleep 2
}

# Função para instalar Apache
install_apache() {
    if confirm_installation "Apache"; then
        echo "Instalando Apache..." | tee -a "$LOG_FILE"
        apt-get install -y apache2
        systemctl enable apache2
        systemctl start apache2
        
        # Configurar firewall
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw allow 8888/tcp
        ufw allow 8081/tcp
        
        APACHE_INSTALLED=1
        echo -e "${GREEN}✅ Apache instalado com sucesso!${NC}"
        sleep 2
    fi
}

# Função para instalar Zabbix
install_zabbix() {
    if ! check_dependencies "Zabbix"; then
        sleep 2
        return 1
    fi
    
    if confirm_installation "Zabbix"; then
        echo "Instalando Zabbix..." | tee -a "$LOG_FILE"
        
        wget -q -O "$TEMPDIR/zabbix.deb" \
            https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu24.04_all.deb
        dpkg -i "$TEMPDIR/zabbix.deb"
        apt-get update
        
        if ! apt-get install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf \
            zabbix-sql-scripts zabbix-agent wget gzip; then
            echo "Falha na instalação dos pacotes do Zabbix" | tee -a "$LOG_FILE"
            exit 1
        fi

        SQL_SCRIPT_PATH=$(dpkg -L zabbix-sql-scripts | grep 'server.sql.gz$' | head -1)
        if [ -z "$SQL_SCRIPT_PATH" ]; then
            SQL_SCRIPT_PATH="/usr/share/doc/zabbix-sql-scripts/mysql/server.sql.gz"
            [ ! -f "$SQL_SCRIPT_PATH" ] && { echo "Erro: Schema do Zabbix não encontrado"; exit 1; }
        fi

        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS zabbix; CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"

        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DROP USER IF EXISTS 'zabbix'@'localhost';"
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DROP USER IF EXISTS 'zabbix'@'127.0.0.1';"
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '$MYSQL_COMMON_PASSWORD';"
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER 'zabbix'@'127.0.0.1' IDENTIFIED BY '$MYSQL_COMMON_PASSWORD';"
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';"
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'127.0.0.1';"
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SET GLOBAL log_bin_trust_function_creators = 1;"

        zcat "$SQL_SCRIPT_PATH" | mysql --default-character-set=utf8mb4 -uzabbix -p"$MYSQL_COMMON_PASSWORD" zabbix
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SET GLOBAL log_bin_trust_function_creators = 0;"

        sed -i "s/# DBPassword=/DBPassword=$MYSQL_COMMON_PASSWORD/" /etc/zabbix/zabbix_server.conf
        sed -i "s/# DBConnectTimeout=5/DBConnectTimeout=10/" /etc/zabbix/zabbix_server.conf

        systemctl restart apache2
        systemctl restart zabbix-server zabbix-agent
        systemctl enable zabbix-server zabbix-agent apache2
        
        ZABBIX_INSTALLED=1
        echo -e "${GREEN}✅ Zabbix instalado com sucesso!${NC}"
        sleep 2
    fi
}

# Função para instalar GLPI
install_glpi() {
    if ! check_dependencies "GLPI"; then
        sleep 2
        return 1
    fi
    
    if confirm_installation "GLPI"; then
        echo "Instalando GLPI..." | tee -a "$LOG_FILE"
        
        apt-get install -y php libapache2-mod-php php-mysql php-curl php-ldap \
            php-imap php-apcu php-gd php-xml php-mbstring php-xmlrpc php-cas \
            php-intl php-zip php-bz2
        
        wget -q -O "$TEMPDIR/glpi.tgz" \
            https://github.com/glpi-project/glpi/releases/download/$GLPI_VERSION/glpi-$GLPI_VERSION.tgz
        tar -xzf "$TEMPDIR/glpi.tgz" -C /var/www/html/
        chown -R www-data:www-data /var/www/html/glpi
        chmod -R 755 /var/www/html/glpi
        
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE glpi CHARACTER SET utf8 COLLATE utf8_general_ci;"
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER 'glpi'@'localhost' IDENTIFIED BY '$MYSQL_COMMON_PASSWORD';"
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON glpi.* TO 'glpi'@'localhost';"
        
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
        
        GLPI_INSTALLED=1
        echo -e "${GREEN}✅ GLPI instalado com sucesso! Acesse via http://seu-ip:8888${NC}"
        sleep 2
    fi
}

# Função para instalar UniFi Controller
install_unifi() {
    if confirm_installation "UniFi Controller"; then
        echo "Instalando UniFi Controller..." | tee -a "$LOG_FILE"
        wget -q -O "$TEMPDIR/unifi-install.sh" \
            https://get.glennr.nl/unifi/install/unifi-$UNIFI_VERSION.sh
        yes y | bash "$TEMPDIR/unifi-install.sh"
        
        UNIFI_INSTALLED=1
        echo -e "${GREEN}✅ UniFi Controller instalado com sucesso! Acesse via https://seu-ip:8443${NC}"
        sleep 2
    fi
}

# Função para instalar Grafana
install_grafana() {
    if confirm_installation "Grafana"; then
        echo "Instalando Grafana $GRAFANA_VERSION..." | tee -a "$LOG_FILE"
        
        apt-get install -y adduser libfontconfig1 musl
        
        wget -q -O "$TEMPDIR/grafana_${GRAFANA_VERSION}.deb" \
            "https://dl.grafana.com/oss/release/grafana_${GRAFANA_VERSION}_amd64.deb" || {
            echo "Falha ao baixar Grafana" | tee -a "$LOG_FILE"
            exit 1
        }
        
        dpkg -i "$TEMPDIR/grafana_${GRAFANA_VERSION}.deb" || apt-get -f install -y
        
        systemctl daemon-reload
        systemctl enable grafana-server
        systemctl start grafana-server
        
        GRAFANA_INSTALLED=1
        echo -e "${GREEN}✅ Grafana instalado com sucesso! Acesse via http://seu-ip:3000${NC}"
        sleep 2
    fi
}

# Função para instalar Docker e Portainer
install_docker_portainer() {
    if confirm_installation "Docker e Portainer"; then
        echo "Instalando Docker e Portainer..." | tee -a "$LOG_FILE"
        
        apt-get install -y ca-certificates curl gnupg lsb-release
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
            https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
            tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
        docker volume create portainer_data
        docker run -d -p 9000:9000 -p 9443:9443 \
            --name portainer \
            --restart=always \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v portainer_data:/data \
            portainer/portainer-ce:$PORTTAINER_VERSION
        
        DOCKER_INSTALLED=1
        echo -e "${GREEN}✅ Docker e Portainer instalados com sucesso! Acesse via https://seu-ip:9443${NC}"
        sleep 2
    fi
}

# Função para instalar Nextcloud
install_nextcloud() {
    if ! check_dependencies "Nextcloud"; then
        sleep 2
        return 1
    fi
    
    if confirm_installation "Nextcloud"; then
        echo "Instalando Nextcloud..." | tee -a "$LOG_FILE"
        
        apt-get install -y php php-gd php-curl php-zip php-xml php-mbstring \
            php-bz2 php-intl php-bcmath php-imagick php-gmp php-apcu unzip
        
        wget -q -O "$TEMPDIR/nextcloud.zip" \
            https://download.nextcloud.com/server/releases/$NEXTCLOUD_VERSION.zip
        unzip "$TEMPDIR/nextcloud.zip" -d /var/www/html/
        chown -R www-data:www-data /var/www/html/nextcloud
        chmod -R 755 /var/www/html/nextcloud
        
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY '$MYSQL_COMMON_PASSWORD';"
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost';"
        
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
        
        NEXTCLOUD_INSTALLED=1
        echo -e "${GREEN}✅ Nextcloud instalado com sucesso! Acesse via http://seu-ip:8081${NC}"
        sleep 2
    fi
}

# Função para instalar Duplicati
install_duplicati() {
    if confirm_installation "Duplicati"; then
        echo "Instalando Duplicati..." | tee -a "$LOG_FILE"
        wget -q -O "$TEMPDIR/duplicati.deb" \
            https://updates.duplicati.com/beta/duplicati_2.0.7.1-1_all.deb
        dpkg -i "$TEMPDIR/duplicati.deb" || apt-get -f install -y
        
        cat > /etc/systemd/system/duplicati.service <<EOF
[Unit]
Description=Duplicati Backup Service
After=network.target

[Service]
ExecStart=/usr/bin/mono /usr/lib/duplicati/Duplicati.Server.exe --webservice-port=8200
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

        systemctl daemon-reload
        systemctl enable duplicati
        systemctl start duplicati
        
        DUPLICATI_INSTALLED=1
        echo -e "${GREEN}✅ Duplicati instalado com sucesso! Acesse via http://seu-ip:8200${NC}"
        sleep 2
    fi
}

# Função para instalar CUPS (servidor de impressão)
install_cups() {
    if confirm_installation "CUPS (Servidor de Impressão)"; then
        echo "Instalando CUPS..." | tee -a "$LOG_FILE"
        apt-get install -y cups
        
        # Permitir acesso remoto
        sed -i 's/^Listen localhost:631/Port 631/' /etc/cups/cupsd.conf
        sed -i 's/^\(.*<Location \/>\)/\1\n  Allow all/' /etc/cups/cupsd.conf
        sed -i 's/^\(.*<Location \/admin>\)/\1\n  Allow all/' /etc/cups/cupsd.conf

        systemctl restart cups
        systemctl enable cups

        # Configurar firewall
        ufw allow 631/tcp
        
        CUPS_INSTALLED=1
        echo -e "${GREEN}✅ CUPS instalado com sucesso! Acesse via http://seu-ip:631${NC}"
        sleep 2
    fi
}

# Função para instalar Uptime Kuma
install_kuma() {
    if confirm_installation "Uptime Kuma"; then
        echo "Instalando Uptime Kuma (monitoramento) (versão compilada)..." | tee -a "$LOG_FILE"

        # Criar diretório de instalação
        mkdir -p /opt/uptime-kuma
        cd /opt/uptime-kuma || exit 1

        # Baixar versão oficial do GitHub
        echo "Baixando Uptime Kuma versão 1.23.16..." | tee -a "$LOG_FILE"
        curl -L https://github.com/louislam/uptime-kuma/releases/download/1.23.16/dist.tar.gz -o dist.tar.gz

        # Extrair e remover arquivo baixado
        tar -xvzf dist.tar.gz
        rm -f dist.tar.gz

        # Configurar Apache para servir os arquivos na porta 3001
        apt-get install -y apache2
        ufw allow 3001/tcp

        cat > /etc/apache2/sites-available/uptime-kuma.conf <<EOF
Listen 3001
<VirtualHost *:3001>
    DocumentRoot /opt/uptime-kuma/dist
    <Directory /opt/uptime-kuma/dist>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/uptime-kuma_error.log
    CustomLog \${APACHE_LOG_DIR}/uptime-kuma_access.log combined
</VirtualHost>
EOF

        a2ensite uptime-kuma.conf
        systemctl reload apache2
        systemctl enable apache2

        KUMA_INSTALLED=1
        echo -e "${GREEN}✅ Uptime Kuma instalado com sucesso! Acesse via http://seu-ip:3001${NC}"
        sleep 2
    fi
}

# Função para instalar tudo
install_all() {
    if confirm_installation "TODOS os serviços"; then
        echo "Instalando todos os serviços..." | tee -a "$LOG_FILE"
        
        # Atualizar sistema primeiro
        echo "Atualizando sistema..." | tee -a "$LOG_FILE"
        apt-get update
        apt-get upgrade -y
        
        install_mysql
        install_apache
        install_zabbix
        install_glpi
        install_unifi
        install_grafana
        install_docker_portainer
        install_nextcloud
        install_duplicati
        install_cups
        install_kuma
        
        # Limpeza final
        cleanup
        
        echo -e "${GREEN}✅ Todos os serviços instalados com sucesso!${NC}"
        echo "Acessos:"
        echo " - GLPI: http://seu-ip:8888"
        echo " - Nextcloud: http://seu-ip:8081"
        echo " - Portainer: https://seu-ip:9443"
        echo " - UniFi: https://seu-ip:8443"
        echo " - Grafana: http://seu-ip:3000"
        echo " - Duplicati: http://seu-ip:8200"
        echo " - CUPS: http://seu-ip:631"
        echo " - Uptime Kuma: http://seu-ip:3001"
        sleep 5
    fi
}

# Menu principal interativo
while true; do
    show_main_menu
    echo -e "${YELLOW}Escolha uma opção:${NC}"
    read -r choice
    
    case $choice in
        1) install_mysql ;;
        2) install_apache ;;
        3) install_zabbix ;;
        4) install_glpi ;;
        5) install_unifi ;;
        6) install_grafana ;;
        7) install_docker_portainer ;;
        8) install_nextcloud ;;
        9) install_duplicati ;;
        10) install_cups ;;
        11) install_kuma ;;
        12) install_all ;;
        13) show_services_status ;;
        14) repair_mysql ;;
        0) 
            echo "Saindo..."
            cleanup
            exit 0
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            sleep 2
            ;;
    esac
    
    echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
    read -r
done
