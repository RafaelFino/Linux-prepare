# Guia de Testes

## 🚀 Como Executar os Testes

### Pré-requisitos

- Docker instalado e rodando
- Estar no diretório raiz do projeto

### Teste Completo (Recomendado)

```bash
# Certifique-se de estar no diretório raiz do projeto
cd /caminho/para/linux-prepare

# Execute todos os testes
./tests/run-all-tests.sh
```

**O que será testado:**
1. ✅ Ubuntu 22.04 - Instalação completa
2. ✅ Debian 12 - Instalação completa
3. ✅ Idempotência - Script executado 2x

**Tempo estimado:** 15-30 minutos (dependendo da conexão)

### Teste Individual

#### Ubuntu 22.04
```bash
# Do diretório raiz do projeto
docker build -f tests/docker/Dockerfile.ubuntu-22.04 -t test-ubuntu .
docker run --rm test-ubuntu /tmp/validate.sh
```

#### Debian 12
```bash
# Do diretório raiz do projeto
docker build -f tests/docker/Dockerfile.debian-12 -t test-debian .
docker run --rm test-debian /tmp/validate.sh
```

### Teste Interativo (Para Debug)

```bash
# Criar container sem executar validação
docker run -it --rm ubuntu:22.04 bash

# Dentro do container:
apt update
apt install -y sudo curl wget git ca-certificates gnupg

# Criar usuário de teste
useradd -m -s /bin/bash testuser
echo "testuser:testuser" | chpasswd
usermod -aG sudo testuser
echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copiar e executar script (você precisará montar o volume)
# Ou clonar o repositório dentro do container
```

### Teste com Volume Montado

```bash
# Montar diretório local no container
docker run -it --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  ubuntu:22.04 bash

# Dentro do container:
apt update
apt install -y sudo
./scripts/prepare.sh --skip-desktop
./tests/scripts/validate.sh
```

## 🔍 Interpretando os Resultados

### Sucesso ✅

```
============================================
  Validation Tests
============================================

--- Base Commands ---
✓ Git: git is installed
✓ Zsh: zsh is installed
✓ eza: eza is installed
...

============================================
  Summary
============================================
Passed: 30
Failed: 0

All tests passed!
```

### Falha ❌

```
--- Base Commands ---
✗ eza: eza is NOT installed
...

============================================
  Summary
============================================
Passed: 25
Failed: 5

Some tests failed!
```

## 🐛 Troubleshooting

### Erro: "scripts/prepare.sh: No such file or directory"

**Causa:** Executando do diretório errado

**Solução:**
```bash
# Navegue para o diretório raiz do projeto
cd /caminho/para/linux-prepare

# Verifique se o arquivo existe
ls -la scripts/prepare.sh

# Execute os testes
./tests/run-all-tests.sh
```

### Erro: "Package 'eza' has no installation candidate"

**Causa:** Repositório do eza não foi adicionado

**Solução:** Já corrigido no script! O script agora adiciona o repositório automaticamente.

### Erro: "Cannot connect to Docker daemon"

**Causa:** Docker não está rodando

**Solução:**
```bash
# Iniciar Docker
sudo systemctl start docker

# Verificar status
sudo systemctl status docker

# Adicionar seu usuário ao grupo docker (opcional)
sudo usermod -aG docker $USER
# Faça logout e login novamente
```

### Erro: "No space left on device"

**Causa:** Espaço em disco insuficiente

**Solução:**
```bash
# Limpar imagens Docker antigas
docker system prune -a

# Verificar espaço
df -h
```

### Build muito lento

**Causa:** Download de pacotes

**Dicas:**
- Use cache do Docker (não use --no-cache)
- Verifique sua conexão de internet
- Considere usar um mirror apt mais próximo

## 📊 Testes Específicos

### Testar apenas instalação do Docker

```bash
docker run -it --rm ubuntu:22.04 bash -c "
  apt update && apt install -y sudo curl wget git ca-certificates gnupg &&
  useradd -m testuser &&
  echo 'testuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers &&
  curl -o /tmp/prepare.sh https://raw.githubusercontent.com/RafaelFino/Linux-prepare/main/scripts/prepare.sh &&
  chmod +x /tmp/prepare.sh &&
  /tmp/prepare.sh --skip-go --skip-python --skip-kotlin --skip-jvm --skip-dotnet --skip-desktop &&
  docker --version
"
```

### Testar apenas instalação do Golang

```bash
docker run -it --rm ubuntu:22.04 bash -c "
  apt update && apt install -y sudo curl wget git ca-certificates gnupg &&
  useradd -m testuser &&
  echo 'testuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers &&
  curl -o /tmp/prepare.sh https://raw.githubusercontent.com/RafaelFino/Linux-prepare/main/scripts/prepare.sh &&
  chmod +x /tmp/prepare.sh &&
  /tmp/prepare.sh --skip-docker --skip-python --skip-kotlin --skip-jvm --skip-dotnet --skip-desktop &&
  /usr/local/go/bin/go version
"
```

## 📝 Checklist de Validação Manual

Após executar o script, verifique:

- [ ] Docker instalado: `docker --version`
- [ ] Docker Compose instalado: `docker compose version`
- [ ] Golang instalado: `go version` ou `/usr/local/go/bin/go version`
- [ ] Python instalado: `python3 --version`
- [ ] .NET instalado: `dotnet --version`
- [ ] Zsh instalado: `zsh --version`
- [ ] Oh-My-Zsh instalado: `ls -la ~/.oh-my-zsh`
- [ ] eza instalado: `eza --version`
- [ ] micro instalado: `micro --version`
- [ ] Aliases configurados: `grep "alias ls=" ~/.zshrc`
- [ ] Shell padrão é zsh: `echo $SHELL`
- [ ] Usuário no grupo docker: `groups | grep docker`
- [ ] Usuário no grupo sudo: `groups | grep sudo`

## 🎯 Próximos Passos

Após os testes passarem:

1. ✅ Testes automatizados passaram
2. 🧪 Teste em uma VM limpa (opcional mas recomendado)
3. 🚀 Use em produção com confiança

## 💡 Dicas

- **Sempre teste em container/VM primeiro** antes de usar em produção
- **Mantenha logs** dos testes para referência
- **Reporte problemas** no GitHub Issues com logs completos
- **Contribua** com melhorias nos testes!
