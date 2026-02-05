# Env Prepare
Prcisamos gerar um conjunto de scripts capazes de pegar uma instalação de linux baseada em Ubuntu e tornar plenamente funcional para alguns propósitos:
- Conjunto básico comum a todos
- Desktop com ambiente de desenvolvimento

Pacotes base:
- Zsh
- git
- curl
- wget
- jq
- batcat
- micro editor
- eza
- python3 + pip
- vim
- awesomevim
- oh-my-bash
- oh-my-zsh (deve ser o padrão)
- sqlite3
- telnet
- htop
- btop
- gpg 
- zip 
- unzip 
- apt-transport-https 
- zlib1g
- ca-certificates 
- gnupg
- httpie 
- gh
- cmake 
- build-essential
- netcat-openbsd 
- openssl 
- openssh-server

Itens extras:
- Docker (-docker)
- Golang (-golang)
- JVM sendo instalada a partir do SDKMAN (-jvm)
- Visual Studio Code (-vscode)
- Fontes para terminal: (-fonts) 
    Nerd Fonts
    Powerline Fonts
- Terminator (-terminator)
- dotnet

Esse script também deve ser capaz de criar usuários a partir de parametros informados na linha de comando e tudo deve ser instalado para todos os usuários

Sempre que possível, usar instaladores a partir de apt

Para os alias e paths, deve ser usado o arquivo .profile para cada usuário

Deve ser gerado um arquivo readme.md na raiz do projeto detalhando seu funcionamento e todas os parametros aceitos:
- Para a criação de usuários, deve-se usar o comando -u e separando os usuários por virgula, modelo: -u=user1,user2,userN
- Para os itens extras, cada um possui seu identificador de parametro

Tudo deve ser logado em tela, portanto se faz necessário que uma função de log comum e padronizada seja usada em todos os scripts. Todos os scripts devem ter tempo de execução, mensagem de inicio e término. Cada linha de log deve ter data, hora e um identificador explicando qual script está rodando. Cores devem ser usadas para exibir status do que acontece usando padrões de log: INFO, WARN, DEBUG e ERROR

Exemplo de log: 
[2026-02-05 15:52:37] [micro] [INFO] Installing...
...
[2026-02-05 15:52:37] [micro] [INFO] Successful in 13 seconds!


Cada item a ser instalado, deve ter o seu script, estes devem ser simples e objetivos, pouco verboso, visando a fácil manutenção e entendimento. 

Cada um desses scripts deve ser idempotente. 

A estrutura de arquivos deve ser:
\scripts
    prepare.sh
    \util
        log.sh
    \modules
        base.sh
        docker.sh
        golang.sh
        dotnet.sh
        jvm.sh
        fonts.sh
        terminator.sh
        vscode.sh

# Detalhes para cada instalador:
## eza
O binário é comum para todos, mas as configurações de alias são por usuário
Em .profile, caso não exista:
alias ls=\"eza -hHbmgalT -L 1 --time-style=long-iso --icons\"
alias lt=\"eza -hHbmgalT -L 4 --time-style=long-iso --icons\"

## awesome vim
O binário é comum para todos, mas as configurações de alias são por usuário
``` bash
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh
echo set nu >> ~/.vim_runtime/my_configs.vim
```

## micro editor
``` bash
curl https://getmic.ro | bash
sudo mv micro /usr/bin
```

## Oh my Bash
Por usuário
``` bash
curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh | bash
```

## Oh my Zsh
Por usuário
``` bash
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"agnoster\"/g' .zshrc
```

## Docker
``` bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh ./get-docker.sh
```
E para cada usuário:
``` bash
sudo usermod -aG docker $USER
```

## fonts
``` bash
git clone https://github.com/powerline/fonts.git
./fonts/install.sh
https://github.com/ryanoasis/nerd-fonts.git 
./nerd-fonts/install.sh
```



