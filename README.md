# Projeto: EMPRESA LIVRE – Infraestrutura Completa e Gratuita para Pequenas Empresas

O **EMPRESA LIVRE** é um projeto open source que tem como objetivo **ajudar pequenas empresas e empreendedores** a terem acesso a uma infraestrutura de TI **robusta, segura e moderna** — sem depender de altos investimentos em softwares proprietários.

Com apenas **um script**, você instala ferramentas de **gestão, monitoramento, backup, colaboração e segurança** que antes só estavam ao alcance de grandes organizações.

O propósito é **democratizar o acesso à tecnologia** e oferecer autonomia para empresários que não têm familiaridade com o setor de TI.

---

## O que você terá instalado

| Ferramenta           | Para que serve                                                         |
|----------------------|------------------------------------------------------------------------|
| **GLPI**             | Gestão de chamados, inventário e ativos da empresa                     |
| **Zabbix**           | Monitoramento da infraestrutura e dos serviços em tempo real           |
| **UniFi Controller** | Controle centralizado da rede e dos dispositivos UniFi                 |
| **Grafana**          | Dashboards analíticos e visualização de métricas                       |
| **Nextcloud**        | Nuvem privada para arquivos e colaboração da equipe                    |
| **MySQL**            | Banco de dados relacional utilizado por GLPI, Zabbix e Nextcloud       |
| **Apache2**          | Servidor web configurado em múltiplas portas                           |
| **Docker + Portainer** | Gerenciamento de containers com interface gráfica no navegador      |
| **CUPS**             | Servidor de impressão em rede acessível via navegador                  |
| **Duplicati**        | Sistema de backup automatizado e acessível via interface web           |

---

## Para quem é este projeto?

- 📌 Pequenas empresas que não têm setor de TI estruturado  
- 📌 Escritórios e prestadores de serviços que precisam de mais organização  
- 📌 Empreendedores que querem reduzir custos com licenciamento de software  
- 📌 Profissionais de TI que desejam implantar soluções rápidas e confiáveis em clientes  

---

## Informações de Acesso Padrão

- **Senha do MySQL root:** `Admin123*`  
- **Senhas dos bancos (GLPI, Zabbix, Nextcloud):** `Admin123*`  

**Endereços e portas de acesso:**  
- GLPI → `http://<IP>:8888`  
- Nextcloud → `http://<IP>:8081`  
- Portainer → `https://<IP>:9443`  
- CUPS (impressão) → `http://<IP>:631`  
- Duplicati (backup) → `http://<IP>:8200`  

---

## 💻 Como Executar

Clone este repositório no seu servidor Ubuntu 24.04:

```bash
git clone https://github.com/seu-usuario/empresa-livre.git
cd empresa-livre
chmod +x install.sh
./install.sh
````

---

## O que o script faz

O arquivo `install.sh` realiza automaticamente:

1. Atualização do sistema
2. Instalação do MySQL + criação de bancos e usuários
3. Configuração de servidores web e PHP
4. Instalação e configuração de GLPI, Zabbix e Nextcloud
5. Configuração do Apache em múltiplas portas
6. Instalação de Docker e Portainer
7. Instalação do UniFi Controller e Grafana
8. Configuração de CUPS (servidor de impressão)
9. Instalação do Duplicati (backup)

---

## Como isso pode transformar sua empresa

* Controle total do seu ambiente de TI (monitoramento com Zabbix)
* Gestão eficiente de chamados e ativos (GLPI)
* Compartilhamento de arquivos seguro (Nextcloud)
* Rede gerenciada com centralização (UniFi)
* Métricas e dashboards claros para decisões (Grafana)
* Impressão em rede simplificada (CUPS)
* Backups automatizados para segurança (Duplicati)
* Containers prontos para novos serviços (Docker + Portainer)

---

## omo contribuir

O **EMPRESA LIVRE** é um projeto comunitário.
Se você é desenvolvedor, profissional de TI ou empresário que já utiliza essas ferramentas, pode colaborar:

1. Faça um fork do repositório
2. Crie uma branch:

   ```bash
   git checkout -b melhoria-nova
   ```
3. Commit:

   ```bash
   git commit -m "Adicionei nova funcionalidade"
   ```
4. Push:

   ```bash
   git push origin melhoria-nova
   ```
5. Abra um Pull Request

---

## Contato

Em caso de dúvidas ou sugestões, entre em contato:
**[marciopro3@gmail.com](mailto:marciopro3@gmail.com)**

---

## Licença

Este projeto está licenciado sob a Licença MIT.
**Livre para todos, feito para ajudar.**

---

**Sinta-se à vontade para ajustar qualquer parte conforme necessário para melhor atender ao seu projeto específico! "Ajude o teu próximo sempre e a ajuda virá até você."
