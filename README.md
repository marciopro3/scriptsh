cat <<'EOF' > README.md
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

\`\`\`bash
git clone https://github.com/seu-usuario/seu-repositorio.git
cd seu-repositorio
chmod +x install.sh
./install.sh
\`\`\`

---

## 📁 Estrutura do Script

O arquivo \`install.sh\` é modular, com instalação sequencial e organizada para cada ferramenta. Ele realiza:

1. Atualizações do sistema
2. Instalação do MySQL com permissões de acesso remoto
3. Criação de bancos e usuários para GLPI, Zabbix e Nextcloud
4. Instalação de servidores web e PHP
5. Configuração do Apache em múltiplas portas
6. Instalação de Docker e Portainer
7. Instalação direta de UniFi Controller e Grafana

---

## 📷 Exemplo de Aplicação

Este script foi implantado na **empresa V3V**, com foco em:

- Gerenciar chamados de suporte com o GLPI
- Monitorar equipamentos e serviços com o Zabbix
- Gerenciar rede UniFi em diversos setores
- Compartilhar arquivos entre times com Nextcloud
- Criar dashboards analíticos com Grafana
- Gerenciar containers via Portainer

---

## 🤝 Contribuição

Sinta-se à vontade para sugerir melhorias:

1. Faça um fork deste repositório
2. Crie uma branch:
   \`\`\`bash
   git checkout -b feature-nova
   \`\`\`
3. Commit:
   \`\`\`bash
   git commit -m "Nova funcionalidade"
   \`\`\`
4. Push:
   \`\`\`bash
   git push origin feature-nova
   \`\`\`
5. Abra um Pull Request

---

## 📬 Suporte

Em caso de dúvidas ou sugestões, entre em contato:  
📧 **marciopro3@gmail.com**

---

## 📄 Licença

Este projeto está licenciado sob a Licença MIT. Consulte o arquivo \`LICENSE\`.

---

**Sinta-se à vontade para ajustar qualquer parte conforme necessário para melhor atender ao seu projeto específico! "Ajude o teu próximo sempre e a ajuda virá até você."
EOF
