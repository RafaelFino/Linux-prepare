# Linux-prepare

Alguns scripts para preparar o ambiente para uso

# Script principal: `./scripts/prepare.sh`


| Argumento  | Descrição                                                                                       |
|------------|-------------------------------------------------------------------------------------------------|
| -u=USER    | Instala o ambiente. Permite múltiplos usuários, separados por vírgulas. Exemplo: -u=user1,user2 |
| -docker    | Instala o Docker e adiciona o(s) usuário(s) ao grupo docker.                                    |
| -go        | Instala o Golang.                                                                               |
| -jvm       | Instala o SDKMAN! e a versão padrão do Java (atualmente 21).                                    |
| -dotnet    | Instala o .NET SDK e Runtime.                                                                   |
| -desktop   | Instala aplicações e fontes para ambiente desktop (VSCode, Chrome, fontes Powerline e Nerd).    |
| -all       | Instala todas as opções acima.                                                                  |
| -h, --help | Mostra esta ajuda.                                                                              |

## Para preparar um servidor de desenvolvimento

```bash
cd scripts
sudo ./prepare.sh -u=developer -docker -go -jvm -dotnet
``` 

Onde:
- `developer` é o nome do usuário para o qual o ambiente será preparado.
- As opções `-docker`, `-go`, `-jvm` e `-dotnet` indicam quais componentes devem ser instalados.

## Para preparar uma estação de trabalho (notebook ou desktop)

```bash
cd scripts
sudo ./prepare.sh -u=developer -all
```

Onde:
- `developer` é o nome do usuário para o qual o ambiente será preparado.
- `-all` indica que todos os componentes devem ser instalados.

Ao tentar executar o script com a opção **desktop**, ao instalar novos interpretadores de terminal, como o Zsh, o script pode tentar instalar fontes adicionais ou temas que não estão disponíveis no sistema. Isso pode resultar em solicitações de instalação de pacotes adicionais ou em alterações na configuração do terminal. Leia com atenção a cada pedido e confirme de acordo com a orientação em tela.

**Importante:** O script é preparado para a execução para mais de um usuário ao mesmo tempo e irá instalar tudo também para o usuário root. Para instalar para multiplos usuários ao mesmo tempo, use o argumento `-u` com uma lista de usuários separados por vírgulas. Exemplo:
```bash
cd scripts
sudo ./prepare.sh -u=user1,user2 -docker -go -jvm -dotnet -desktop  
```
