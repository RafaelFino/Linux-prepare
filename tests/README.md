# Diretório de Testes

Este diretório contém toda a infraestrutura de testes automatizados do projeto.

## 📁 Estrutura

```
tests/
├── docker/                      # Dockerfiles para cada distribuição (scripts)
│   ├── Dockerfile.ubuntu-24.04
│   ├── Dockerfile.debian-13
│   ├── Dockerfile.xubuntu-24.04
│   └── Dockerfile.mint-22
├── scripts/                     # Scripts de validação
│   └── validate.sh
├── ansible/                     # Framework de testes Ansible
│   ├── README.md               # Documentação completa de testes Ansible
│   ├── run-ansible-tests.sh   # Runner principal de testes Ansible
│   ├── quick-test.sh           # Teste rápido Ansible (Ubuntu)
│   ├── test-derivatives.sh     # Testa derivados Ansible
│   ├── config/                 # Configuração de testes
│   ├── docker/                 # Dockerfiles para testes Ansible
│   ├── scripts/                # Scripts de teste Ansible
│   ├── fixtures/               # Inventários e variáveis de teste
│   └── results/                # Resultados dos testes
├── run-all-tests.sh            # Executa todos os testes de scripts
├── test-derivatives.sh         # Testa apenas Xubuntu, Mint e Pop!_OS (scripts)
├── quick-test.sh               # Teste rápido (Ubuntu, scripts)
├── TESTING.md                  # Guia completo de testes de scripts
├── DISTRIBUTIONS.md            # Info sobre distribuições
├── TEST-MATRIX.md              # Matriz detalhada de testes
└── QUICK-REFERENCE.md          # Referência rápida de comandos
```

## 🚀 Início Rápido

### Testes de Scripts (Bash)

```bash
# Executar todos os testes de scripts
./tests/run-all-tests.sh

# Testar apenas derivados
./tests/test-derivatives.sh

# Teste rápido
./tests/quick-test.sh
```

### Testes Ansible

```bash
# Executar todos os testes Ansible
./tests/ansible/run-ansible-tests.sh

# Teste rápido Ansible
./tests/ansible/quick-test.sh

# Testar derivados Ansible
./tests/ansible/test-derivatives.sh
```

📖 **Para documentação completa de testes Ansible**, veja [ansible/README.md](ansible/README.md)

## 📚 Documentação

### Testes de Scripts

| Arquivo | Descrição |
|---------|-----------|
| **[WHICH-TEST.md](WHICH-TEST.md)** | 🎯 Guia de decisão: qual teste executar? |
| **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** | Comandos rápidos e troubleshooting |
| **[TESTING.md](TESTING.md)** | Guia completo de como executar testes |
| **[DISTRIBUTIONS.md](DISTRIBUTIONS.md)** | Detalhes sobre cada distribuição testada |
| **[TEST-MATRIX.md](TEST-MATRIX.md)** | Matriz completa de cobertura de testes |

### Testes Ansible

| Arquivo | Descrição |
|---------|-----------|
| **[ansible/README.md](ansible/README.md)** | 📖 Documentação completa de testes Ansible |

## 🎯 Distribuições Testadas

- ✅ **Ubuntu 24.04** - Distribuição base
- ✅ **Debian 13** - Compatibilidade Debian puro
- ✅ **Xubuntu 24.04** - Desktop XFCE
- ✅ **Linux Mint 22** - Derivado com repositórios próprios
- ✅ **Idempotência** - Execução dupla

## ⏱️ Tempo de Execução

### Testes de Scripts

| Teste | Tempo Estimado |
|-------|----------------|
| Quick Test | ~15 minutos |
| Derivatives | ~30 minutos |
| Full Suite | ~80 minutos |

### Testes Ansible

| Teste | Tempo Estimado |
|-------|----------------|
| Quick Test | ~15 minutos |
| Derivatives | ~30 minutos |
| Full Suite | ~80 minutos |

**Nota**: Os testes de scripts e Ansible validam os mesmos componentes e distribuições.

## 🔧 Requisitos

- Docker instalado e rodando
- ~10GB de espaço em disco
- Conexão de internet estável
- Executar do diretório raiz do projeto

## 📊 Cobertura

Os testes validam:
- ✅ Instalação de todos os componentes
- ✅ Detecção de ambiente desktop
- ✅ Configuração de usuários
- ✅ Aliases e variáveis de ambiente
- ✅ Idempotência (execução múltipla)
- ✅ Compatibilidade entre distribuições

## 🐛 Troubleshooting

Veja [QUICK-REFERENCE.md](QUICK-REFERENCE.md) para soluções rápidas.

## 🤝 Contribuindo

Ao adicionar novos recursos:
1. Execute `run-all-tests.sh` antes de commit
2. Adicione testes para novos componentes
3. Atualize documentação relevante
4. Verifique que todos os testes passam

## 📝 Notas

- Testes são executados em containers Docker isolados
- Cada teste começa com imagem limpa
- Validação automática de componentes instalados
- Logs detalhados para debugging
