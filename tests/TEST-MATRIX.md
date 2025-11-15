# Matriz de Testes

## 🎯 Visão Geral

Este projeto testa automaticamente em **5 cenários diferentes**:

```
┌─────────────────────────────────────────────────────────────┐
│                    PIPELINE DE TESTES                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1️⃣  Ubuntu 24.04        → Distribuição base               │
│  2️⃣  Debian 13           → Compatibilidade Debian puro     │
│  3️⃣  Xubuntu 24.04       → Desktop XFCE                    │
│  4️⃣  Linux Mint 22       → Derivado com repos próprios     │
│  5️⃣  Idempotência        → Execução dupla (Ubuntu)         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 📊 Matriz Detalhada

| # | Distribuição | Versão | Desktop | Objetivo | Tempo |
|---|--------------|--------|---------|----------|-------|
| 1 | Ubuntu | 24.04 | Auto-detect | Baseline completo | ~15min |
| 2 | Debian | 13 | Não | Compatibilidade Debian | ~12min |
| 3 | Xubuntu | 24.04 | XFCE | Detecção XFCE | ~16min |
| 4 | Linux Mint | 22 | Cinnamon | Derivados + repos | ~15min |
| 5 | Ubuntu | 24.04 | Auto-detect | Idempotência (2x) | ~25min |

**Tempo Total Estimado**: ~80 minutos

## 🧪 O Que Cada Teste Valida

### 1️⃣ Ubuntu 24.04
```yaml
Valida:
  - Instalação de todos os componentes
  - Docker + Docker Compose
  - Golang, Python, .NET, JVM, Kotlin
  - Zsh + Oh-My-Zsh
  - Detecção automática de desktop
  - Aliases e configurações
```

### 2️⃣ Debian 13
```yaml
Valida:
  - Compatibilidade com Debian puro
  - Instalação sem desktop
  - Repositórios Debian oficiais
  - Mesmos componentes do Ubuntu
```

### 3️⃣ Xubuntu 24.04
```yaml
Valida:
  - Detecção de ambiente XFCE
  - Instalação de componentes desktop
  - Terminal emulators (Terminator, Alacritty)
  - Fontes (Nerd Fonts, Powerline)
  - VSCode + Chrome
```

### 4️⃣ Linux Mint 22
```yaml
Valida:
  - Compatibilidade com derivados
  - Repositórios do Mint
  - Detecção de Cinnamon
  - Todos os componentes funcionais
```

### 5️⃣ Idempotência
```yaml
Valida:
  - Script pode rodar múltiplas vezes
  - Não quebra em segunda execução
  - Detecta componentes já instalados
  - Logs corretos (skip messages)
```

## 🚀 Como Executar

### Todos os Testes
```bash
./tests/run-all-tests.sh
```

### Apenas Derivados (Xubuntu + Mint)
```bash
./tests/test-derivatives.sh
```

### Teste Individual
```bash
# Ubuntu
docker build -f tests/docker/Dockerfile.ubuntu-24.04 -t test-ubuntu .
docker run --rm test-ubuntu /tmp/validate.sh

# Debian
docker build -f tests/docker/Dockerfile.debian-13 -t test-debian .
docker run --rm test-debian /tmp/validate.sh

# Xubuntu
docker build -f tests/docker/Dockerfile.xubuntu-24.04 -t test-xubuntu .
docker run --rm test-xubuntu /tmp/validate.sh

# Linux Mint
docker build -f tests/docker/Dockerfile.mint-22 -t test-mint .
docker run --rm test-mint /tmp/validate.sh
```

## ✅ Critérios de Sucesso

Cada teste deve:
- ✅ Completar sem erros
- ✅ Instalar todos os componentes esperados
- ✅ Validar comandos disponíveis
- ✅ Configurar usuários corretamente
- ✅ Aplicar aliases e configurações

## 📈 Cobertura de Testes

```
Componentes Testados:
├── Base Packages        ✅ 100%
├── Docker              ✅ 100%
├── Golang              ✅ 100%
├── Python              ✅ 100%
├── .NET                ✅ 100%
├── JVM/Kotlin          ✅ 100%
├── Zsh/Oh-My-Zsh       ✅ 100%
├── Terminal Tools      ✅ 100%
├── Desktop Detection   ✅ 100%
├── Desktop Apps        ✅ 100%
├── Fonts               ✅ 100%
└── Idempotency         ✅ 100%

Distribuições:
├── Ubuntu              ✅ Testado
├── Debian              ✅ Testado
├── Xubuntu             ✅ Testado
├── Linux Mint          ✅ Testado
└── Raspberry Pi OS     ⚠️  Manual
```

## 🔄 CI/CD Integration

### GitHub Actions (Exemplo)
```yaml
name: Test All Distributions

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run all tests
        run: ./tests/run-all-tests.sh
```

## 📝 Notas

- **Tempo**: Testes completos levam ~80 minutos
- **Espaço**: Requer ~10GB de espaço em disco
- **Docker**: Necessário Docker instalado e rodando
- **Internet**: Requer conexão estável para downloads

## 🎯 Próximos Passos

- [ ] Adicionar testes para Kubuntu
- [ ] Adicionar testes para Lubuntu  
- [ ] Testes de performance
- [ ] Testes de segurança
- [ ] Integração com GitHub Actions
