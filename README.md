# 🚀 Script de Instalação Automática - Infraestrutura Completa para TI

Este projeto oferece um script de automação robusto que instala e configura **as principais ferramentas utilizadas em departamentos de TI** e provedores de serviços, como no caso da empresa **V3V – Publicidade e Desenvolvimento de Software**.

🔧 Ideal para ambientes de desenvolvimento, monitoramento, suporte técnico e colaboração.

## 🛠️ Ferramentas Instaladas

| Ferramenta           | Descrição                                                                 |
|----------------------|---------------------------------------------------------------------------|
| **Zabbix**           | Monitoramento de infraestrutura e serviços em tempo real                  |
| **GLPI**             | Gerenciamento de chamados, ativos e inventário de TI                      |
| **UniFi Controller** | Gerenciamento centralizado de dispositivos UniFi                          |
| **Grafana**          | Visualização e análise de métricas com painéis interativos                |
| **Nextcloud**        | Nuvem privada para colaboração e compartilhamento de arquivos             |
| **MySQL**            | Banco de dados relacional utilizado por todos os sistemas acima           |
| **Apache2**          | Servidor web configurado para múltiplas portas                            |
| **Docker + Portainer** | Gerenciamento de containers com interface gráfica via navegador        |

---

## ✅ Pré-requisitos

Antes de executar o script, verifique:

- ✅ **Ubuntu Server 24.04 LTS** (ou compatível)
- ✅ **Acesso root ou sudo habilitado**
- ✅ **Conexão com a Internet**
- ✅ **Portas 8888, 8081 e 9443 liberadas no roteador (para acesso externo)**

---

## 🔐 Informações de Acesso Padrão

- **Senha do MySQL root:** `Admin123*`  
- **Senhas dos bancos (GLPI, Zabbix, Nextcloud):** `Admin123*`  
- **Portas configuradas:**  
  - GLPI: `http://<IP>:8888`  
  - Nextcloud: `http://<IP>:8081`  
  - Portainer: `https://<IP>:9443`  

---

## 💻 Como Executar

Clone este repositório no seu servidor Ubuntu:

```bash
git clone https://github.com/seu-usuario/seu-repositorio.git
cd seu-repositorio
chmod +x install.sh
./install.sh
