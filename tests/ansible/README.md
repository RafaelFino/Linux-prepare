# Ansible Testing Framework

Este diretório contém a infraestrutura completa de testes para os playbooks e roles Ansible do projeto.

## 📋 Visão Geral

O framework de testes Ansible valida que todos os playbooks e roles funcionam corretamente em múltiplas distribuições Linux, garantindo:

- ✅ Sintaxe correta de YAML e Ansible
- ✅ Instalação de todos os componentes
- ✅ Idempotência (execução múltipla segura)
- ✅ Compatibilidade entre distribuições
- ✅ Detecção correta de ambientes desktop

## 🚀 Início Rápido

### Executar Todos os Testes
```bash
./tests/ansible/run-ansible-tests.sh
```

### Teste Rápido (Ubuntu apenas)
```bash
./tests/ansible/quick-test.sh
```

### Testar Apenas Derivados
```bash
./tests/ansible/test-derivatives.sh
```

## 📁 Estrutura

```
tests/ansible/
├── README.md                      # Este arquivo
├── run-ansible-tests.sh          # Runner principal de testes
├── quick-test.sh                 # Teste rápido (Ubuntu)
├── test-derivatives.sh           # Teste de derivados (Xubuntu, Mint)
├── config/
│   └── test-config.yml           # Configuração de testes
├── docker/
│   ├── Dockerfile.ubuntu-24.04   # Container Ubuntu
│   ├── Dockerfile.debian-13      # Container Debian
│   ├── Dockerfile.xubuntu-24.04  # Container Xubuntu
│   └── Dockerfile.mint-22        # Container Mint
├── scripts/
│   ├── syntax-check.sh           # Validação de sintaxe
│   ├── test-role.sh              # Teste de roles individuais
│   ├── idempotency-check.sh      # Verificação de idempotência
│   ├── validate-ansible.sh       # Validação de componentes
│   └── generate-report.sh        # Geração de relatórios
├── fixtures/
│   ├── inventory/
│   │   └── test-hosts            # Inventário de teste
│   └── vars/
│       └── test-vars.yml         # Variáveis de teste
└── results/
    └── <timestamp>/              # Resultados dos testes
```

## 🎯 Distribuições Testadas

| Distribuição | Versão | Desktop | Objetivo |
|--------------|--------|---------|----------|
| Ubuntu | 24.04 | GNOME | Distribuição base |
| Debian | 13 | Nenhum | Compatibilidade Debian puro |
| Xubuntu | 24.04 | XFCE | Detecção XFCE |
| Linux Mint | 22 | Cinnamon | Derivados com repos próprios |

## 🧪 Tipos de Testes

### 1. Validação de Sintaxe
Valida YAML, sintaxe Ansible e regras do ansible-lint.

```bash
./tests/ansible/scripts/syntax-check.sh

# Verificar playbook específico
./tests/ansible/scripts/syntax-check.sh --playbook site.yml

# Verificar role específica
./tests/ansible/scripts/syntax-check.sh --role docker
```

### 2. Testes de Roles
Testa roles individuais em isolamento.

```bash
# Testar role específica
./tests/ansible/scripts/test-role.sh docker ubuntu-24.04

# Testar em todas as distribuições
./tests/ansible/scripts/test-role.sh docker --all-distros
```

### 3. Testes de Integração
Executa playbooks completos em containers Docker.

```bash
# Testar distribuição específica
./tests/ansible/run-ansible-tests.sh --distro ubuntu-24.04

# Testar playbook específico
./tests/ansible/run-ansible-tests.sh --playbook server.yml
```

### 4. Verificação de Idempotência
Executa playbooks duas vezes e verifica que nada muda na segunda execução.

```bash
./tests/ansible/scripts/idempotency-check.sh site.yml ubuntu-24.04
```

## 📊 Cobertura de Testes

Os testes validam os mesmos componentes que os testes de scripts:

### Comandos Base
- git, zsh, vim, curl, wget
- htop, btop, jq, fzf, eza, micro

### Ferramentas CLI Modernas
- bat/batcat, httpie, yq, glances
- gh, tig, screen, k9s
- dust, tldr, neofetch (opcionais)

### Ferramentas de Build
- cmake, gcc, make

### Clientes de Banco de Dados
- psql, redis-cli

### Segurança & Rede
- openssl, ssh, netcat

### Linguagens de Programação
- Docker, Golang, Python3, pip3, .NET

### Configuração de Shell
- Oh-My-Zsh, Oh-My-Bash
- Arquivos .zshrc, .bashrc
- Vim runtime
- Aliases (ls, lt)
- Variáveis de ambiente (EDITOR, VISUAL)

### Componentes Desktop (quando aplicável)
- VSCode, Google Chrome
- Terminator, Alacritty
- Fontes (Nerd Fonts, Powerline)

## ⏱️ Tempo de Execução

| Tipo de Teste | Duração Estimada |
|---------------|------------------|
| Validação de sintaxe | ~30 segundos |
| Teste de role individual | ~5-10 minutos |
| Teste de distribuição | ~15 minutos |
| Suite completa | ~80 minutos |
| Teste rápido | ~15 minutos |
| Teste de derivados | ~30 minutos |

## 🔧 Requisitos

- **Docker**: Instalado e rodando
- **Ansible**: 2.9 ou superior
- **Python 3**: 3.8 ou superior
- **Espaço em disco**: ~10GB
- **Conexão de internet**: Para downloads de pacotes

### Instalação de Dependências

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y docker.io ansible python3 python3-pip

# Iniciar Docker
sudo systemctl start docker
sudo systemctl enable docker

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER
newgrp docker

# Instalar ansible-lint (opcional mas recomendado)
pip3 install ansible-lint
```

## 📝 Uso Avançado

### Opções do Test Runner

```bash
# Ajuda
./tests/ansible/run-ansible-tests.sh --help

# Testar distribuição específica
./tests/ansible/run-ansible-tests.sh --distro ubuntu-24.04

# Testar playbook específico
./tests/ansible/run-ansible-tests.sh --playbook server.yml

# Testar role específica
./tests/ansible/run-ansible-tests.sh --role docker

# Modo rápido (Ubuntu apenas, sem idempotência)
./tests/ansible/run-ansible-tests.sh --quick

# Apenas derivados (Xubuntu e Mint)
./tests/ansible/run-ansible-tests.sh --derivatives

# Pular validação de sintaxe
./tests/ansible/run-ansible-tests.sh --skip-syntax

# Pular testes de idempotência
./tests/ansible/run-ansible-tests.sh --skip-idempotency
```

### Gerar Relatório de Testes

```bash
# Gerar relatório dos últimos resultados
./tests/ansible/scripts/generate-report.sh tests/ansible/results/<timestamp>
```

## 🐛 Troubleshooting

### Docker não está rodando
```bash
sudo systemctl start docker
sudo systemctl status docker
```

### Permissão negada ao executar Docker
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Ansible não encontrado
```bash
sudo apt install ansible
# ou
pip3 install ansible
```

### Falha ao construir imagem Docker
```bash
# Limpar imagens antigas
docker system prune -a

# Verificar espaço em disco
df -h
```

### Container não inicia
```bash
# Ver logs do container
docker logs <container_name>

# Verificar containers em execução
docker ps -a

# Remover containers antigos
docker rm $(docker ps -aq)
```

### Testes falhando consistentemente
```bash
# Executar com modo verbose
./tests/ansible/run-ansible-tests.sh --distro ubuntu-24.04 -vvv

# Verificar logs em tests/ansible/results/<timestamp>/
cat tests/ansible/results/<timestamp>/*.log
```

## 🔍 Validação Manual

Para validar manualmente um container:

```bash
# Construir imagem
docker build -f tests/ansible/docker/Dockerfile.ubuntu-24.04 \
  -t ansible-test-ubuntu .

# Executar container
docker run -d --name test-container ansible-test-ubuntu

# Copiar ansible para container
docker cp ansible test-container:/tmp/

# Executar playbook
docker exec test-container bash -c \
  "cd /tmp/ansible && ansible-playbook site.yml -i 'localhost,' -c local"

# Validar componentes
docker exec test-container /tmp/validate-ansible.sh

# Limpar
docker stop test-container
docker rm test-container
```

## 📈 Integração com CI/CD

### GitHub Actions

```yaml
name: Ansible Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install dependencies
        run: |
          sudo apt update
          sudo apt install -y ansible python3-pip
          pip3 install ansible-lint
      
      - name: Run Ansible tests
        run: ./tests/ansible/run-ansible-tests.sh
```

### GitLab CI

```yaml
ansible-tests:
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - apk add --no-cache ansible python3 py3-pip
    - pip3 install ansible-lint
  script:
    - ./tests/ansible/run-ansible-tests.sh
```

## 🤝 Contribuindo

Ao adicionar novos recursos Ansible:

1. **Execute os testes** antes de fazer commit
   ```bash
   ./tests/ansible/run-ansible-tests.sh
   ```

2. **Adicione testes** para novos componentes
   - Atualize `scripts/validate-ansible.sh`
   - Adicione validações específicas

3. **Teste em todas as distribuições**
   ```bash
   ./tests/ansible/run-ansible-tests.sh
   ```

4. **Atualize a documentação**
   - README.md (este arquivo)
   - ansible/README.md
   - Comentários no código

5. **Verifique idempotência**
   ```bash
   ./tests/ansible/scripts/idempotency-check.sh site.yml ubuntu-24.04
   ```

## 📚 Recursos Adicionais

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [ansible-lint Documentation](https://ansible-lint.readthedocs.io/)
- [Docker Documentation](https://docs.docker.com/)

## 🆚 Comparação com Testes de Scripts

| Aspecto | Testes de Scripts | Testes Ansible |
|---------|-------------------|----------------|
| Localização | `tests/` | `tests/ansible/` |
| Método | Bash scripts | Ansible playbooks |
| Validação | `validate.sh` | `validate-ansible.sh` |
| Distribuições | 4 (mesmas) | 4 (mesmas) |
| Componentes | 50+ | 50+ (mesmos) |
| Tempo | ~80 min | ~80 min |

Ambos os frameworks testam os mesmos componentes e distribuições, garantindo paridade de funcionalidades entre os métodos de instalação via script e via Ansible.

---

**Para mais informações sobre Ansible**, veja [ansible/README.md](../../ansible/README.md)
