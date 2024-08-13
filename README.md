# Script - Ferramentas para o setor de T.I.

Este repositório contém um script de automação para a instalação e configuração das principais ferramentas utilizadas no setor de TI em um servidor Ubuntu. As ferramentas incluídas são:

- GLPI
- UniFi Controller
- Zabbix
- Grafana
- MySQL
- Samba

## Pré-requisitos

Antes de executar o script, certifique-se de que você atendeu aos seguintes requisitos:

- **Ubuntu Server:** O script foi testado no Ubuntu Server 24.04 LTS.
- **Acesso root:** É necessário estar logado como root ou ter permissões de sudo.
- **Internet:** O servidor deve estar conectado à internet para baixar os pacotes necessários.
- **expect:** Certifique-se de que o expect está instalado para automatização das entradas interativas. Você pode instalá-lo com o comando:

```bash
apt-get install expect -y
```

## Ferramentas Instaladas

1. GLPI  
   GLPI é um software de gerenciamento de ativos e helpdesk de TI.

2. UniFi Controller**  
   O UniFi Controller é um software de gerenciamento para dispositivos UniFi.

3. Zabbix
   Zabbix é uma ferramenta de monitoramento de rede e servidores.

4. Grafana  
   Grafana é uma plataforma de análise e monitoramento open-source.

5. MySQL  
   MySQL é um sistema de gerenciamento de banco de dados relacional.

6. Samba  
   Samba é uma suíte de software que permite a interoperabilidade de arquivos e serviços de impressão entre sistemas operacionais Unix/Linux e Windows.

## Como Usar

Clone este repositório para o seu servidor:

```bash
git clone https://github.com/seu-usuario/seu-repositorio.git
cd seu-repositorio
```

Torne o script executável:

```bash
chmod +x install.sh
```

Execute o script:

```bash
./install.sh
```

Siga as instruções interativas, se houverem.

## Estrutura do Script

O script `install.sh` é organizado em seções para instalar cada ferramenta individualmente. Cada seção do script contém os passos necessários para a instalação e configuração da respectiva ferramenta.

## Suporte

Para questões, dúvidas ou problemas, por favor, abra um "Issue" neste repositório ou entre em contato através do e-mail: marciopro3@gmail.com.

## Contribuição

Sinta-se à vontade para contribuir com melhorias ou correções. Para contribuir, siga estes passos:

1. Faça um fork deste repositório.
2. Crie uma branch para suas alterações:

    ```bash
    git checkout -b minha-alteracao
    ```

3. Faça um commit com suas alterações:

    ```bash
    git commit -m "Descrição da minha alteração"
    ```

4. Envie suas alterações para o repositório remoto:

    ```bash
    git push origin minha-alteracao
    ```

5. Abra um Pull Request.

## Licença

Este projeto é licenciado sob a Licença MIT - veja o arquivo LICENSE para mais detalhes.

---

Sinta-se à vontade para ajustar qualquer parte conforme necessário para melhor atender ao seu projeto específico! "Ajude o teu próximo sempre e a ajuda virá até você."
