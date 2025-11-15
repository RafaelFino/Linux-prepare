# Diretório de Testes

Este diretório contém toda a infraestrutura de testes automatizados do projeto.

## 📁 Estrutura

```
tests/
├── docker/                      # Dockerfiles para cada distribuição
│   ├── Dockerfile.ubuntu-24.04
│   ├── Dockerfile.debian-13
│   ├── Dockerfile.xubuntu-24.04
│   └── Dockerfile.mint-22
├── scripts/                     # Scripts de validação
│   └── validate.sh
├── run-all-tests.sh            # Executa todos os testes
├── test-derivatives.sh         # Testa apenas Xubuntu e Mint
├── quick-test.sh               # Teste rápido (Ubuntu)
├── TESTING.md                  # Guia completo de testes
├── DISTRIBUTIONS.md            # Info sobre distribuições
├── TEST-MATRIX.md              # Matriz detalhada de testes
└── QUICK-REFERENCE.md          # Referência rápida de comandos
```

## 🚀 Início Rápido

### Executar Todos os Testes
```bash
./tests/run-all-tests.sh
```

### Testar Apenas Derivados
```bash
./tests/test-derivatives.sh
```

### Teste Rápido
```bash
./tests/quick-test.sh
```

## 📚 Documentação

| Arquivo | Descrição |
|---------|-----------|
| **[WHICH-TEST.md](WHICH-TEST.md)** | 🎯 Guia de decisão: qual teste executar? |
| **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** | Comandos rápidos e troubleshooting |
| **[TESTING.md](TESTING.md)** | Guia completo de como executar testes |
| **[DISTRIBUTIONS.md](DISTRIBUTIONS.md)** | Detalhes sobre cada distribuição testada |
| **[TEST-MATRIX.md](TEST-MATRIX.md)** | Matriz completa de cobertura de testes |

## 🎯 Distribuições Testadas

- ✅ **Ubuntu 24.04** - Distribuição base
- ✅ **Debian 13** - Compatibilidade Debian puro
- ✅ **Xubuntu 24.04** - Desktop XFCE
- ✅ **Linux Mint 22** - Derivado com repositórios próprios
- ✅ **Idempotência** - Execução dupla

## ⏱️ Tempo de Execução

| Teste | Tempo Estimado |
|-------|----------------|
| Quick Test | ~15 minutos |
| Derivatives | ~30 minutos |
| Full Suite | ~80 minutos |

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
