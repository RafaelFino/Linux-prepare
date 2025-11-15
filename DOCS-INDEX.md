# Índice de Documentação do Projeto

## 📚 Guia de Navegação

Este projeto possui documentação extensa. Use este índice para encontrar rapidamente o que precisa.

---

## 🚀 Começando

| Documento | Descrição | Para Quem |
|-----------|-----------|-----------|
| **[README.md](README.md)** | Documentação principal do projeto | Todos |
| **[CHANGELOG.md](CHANGELOG.md)** | Histórico de mudanças | Todos |

---

## 🔧 Instalação e Uso

| Documento | Descrição | Para Quem |
|-----------|-----------|-----------|
| **[README.md](README.md)** | Guia de instalação completo | Usuários |
| **[scripts/prepare.sh](scripts/prepare.sh)** | Script principal (com help: `--help`) | Usuários |
| **[scripts/add-opt.sh](scripts/add-opt.sh)** | Ferramentas opcionais (com help: `--help`) | Usuários |

---

## 🆕 Novas Ferramentas

| Documento | Descrição | Para Quem |
|-----------|-----------|-----------|
| **[OPTIONAL-TOOLS.md](OPTIONAL-TOOLS.md)** | ⭐ Guia completo das 43 novas ferramentas | Todos |
| **[RECOMMENDED-ADDITIONS.md](RECOMMENDED-ADDITIONS.md)** | Histórico de recomendações (implementadas) | Interessados |

---

## 🧪 Testes

| Documento | Descrição | Para Quem |
|-----------|-----------|-----------|
| **[tests/WHICH-TEST.md](tests/WHICH-TEST.md)** | ⭐ Guia de decisão: qual teste executar? | Desenvolvedores |
| **[tests/QUICK-REFERENCE.md](tests/QUICK-REFERENCE.md)** | Comandos rápidos de teste | Desenvolvedores |
| **[tests/TESTING.md](tests/TESTING.md)** | Guia completo de testes | Desenvolvedores |
| **[tests/DISTRIBUTIONS.md](tests/DISTRIBUTIONS.md)** | Info sobre distribuições testadas | Desenvolvedores |
| **[tests/TEST-MATRIX.md](tests/TEST-MATRIX.md)** | Matriz de cobertura de testes | Desenvolvedores |
| **[tests/README.md](tests/README.md)** | Visão geral do diretório de testes | Desenvolvedores |

---

## 🤝 Contribuindo

| Documento | Descrição | Para Quem |
|-----------|-----------|-----------|
| **[CONTRIBUTING.md](CONTRIBUTING.md)** | Guia de contribuição | Contribuidores |
| **[tests/CONTRIBUTOR-CHECKLIST.md](tests/CONTRIBUTOR-CHECKLIST.md)** | Checklist antes de commit/PR | Contribuidores |

---

## 📋 Especificações (Specs)

| Documento | Descrição | Para Quem |
|-----------|-----------|-----------|
| **[.kiro/specs/.../requirements.md](.kiro/specs/linux-dev-environment-setup/requirements.md)** | Requisitos do sistema | Desenvolvedores |
| **[.kiro/specs/.../design.md](.kiro/specs/linux-dev-environment-setup/design.md)** | Design e arquitetura | Desenvolvedores |
| **[.kiro/specs/.../tasks.md](.kiro/specs/linux-dev-environment-setup/tasks.md)** | Lista de tarefas | Desenvolvedores |

---

## 📊 Resumos e Implementações

| Documento | Descrição | Para Quem |
|-----------|-----------|-----------|
| **[IMPLEMENTATION-SUMMARY.md](IMPLEMENTATION-SUMMARY.md)** | Resumo da implementação de testes | Desenvolvedores |
| **[OPTIONAL-TOOLS.md](OPTIONAL-TOOLS.md)** | Resumo das novas ferramentas | Todos |

---

## 🎯 Guias Rápidos por Cenário

### "Quero instalar o ambiente"
1. Leia: [README.md](README.md) - Seção "Quick Start"
2. Execute: `sudo ./scripts/prepare.sh`
3. Opcional: `sudo ./scripts/add-opt.sh --help`

### "Quero saber quais ferramentas estão disponíveis"
1. Leia: [OPTIONAL-TOOLS.md](OPTIONAL-TOOLS.md)
2. Veja: [README.md](README.md) - Seção "Features"

### "Quero contribuir com o projeto"
1. Leia: [CONTRIBUTING.md](CONTRIBUTING.md)
2. Leia: [tests/CONTRIBUTOR-CHECKLIST.md](tests/CONTRIBUTOR-CHECKLIST.md)
3. Leia: [tests/WHICH-TEST.md](tests/WHICH-TEST.md)

### "Quero executar testes"
1. Leia: [tests/WHICH-TEST.md](tests/WHICH-TEST.md) - Decidir qual teste
2. Leia: [tests/QUICK-REFERENCE.md](tests/QUICK-REFERENCE.md) - Comandos
3. Execute: `./tests/run-all-tests.sh` ou outro teste

### "Quero entender a arquitetura"
1. Leia: [.kiro/specs/.../design.md](.kiro/specs/linux-dev-environment-setup/design.md)
2. Leia: [README.md](README.md) - Seção "Project Structure"

### "Quero ver o que mudou recentemente"
1. Leia: [CHANGELOG.md](CHANGELOG.md)
2. Leia: [OPTIONAL-TOOLS.md](OPTIONAL-TOOLS.md)

---

## 📁 Estrutura de Documentação

```
linux-prepare/
├── README.md                           # 📖 Documentação principal
├── CHANGELOG.md                        # 📝 Histórico de mudanças
├── CONTRIBUTING.md                     # 🤝 Guia de contribuição
├── DOCS-INDEX.md                       # 📚 Este arquivo
├── OPTIONAL-TOOLS.md                  # 🆕 Guia de novas ferramentas
├── RECOMMENDED-ADDITIONS.md           # 💡 Histórico de recomendações
├── IMPLEMENTATION-SUMMARY.md          # 📊 Resumo de implementação
│
├── scripts/
│   ├── prepare.sh                     # 🔧 Script principal
│   └── add-opt.sh                     # ➕ Ferramentas opcionais
│
├── tests/
│   ├── README.md                      # 📖 Visão geral de testes
│   ├── WHICH-TEST.md                  # 🎯 Guia de decisão
│   ├── QUICK-REFERENCE.md             # ⚡ Referência rápida
│   ├── TESTING.md                     # 📋 Guia completo
│   ├── DISTRIBUTIONS.md               # 🐧 Info sobre distros
│   ├── TEST-MATRIX.md                 # 📊 Matriz de testes
│   └── CONTRIBUTOR-CHECKLIST.md       # ✅ Checklist
│
└── .kiro/specs/linux-dev-environment-setup/
    ├── requirements.md                # 📋 Requisitos
    ├── design.md                      # 🎨 Design
    └── tasks.md                       # ✔️ Tarefas
```

---

## 🔍 Busca Rápida

### Por Tópico

**Instalação**: README.md, scripts/prepare.sh  
**Ferramentas**: OPTIONAL-TOOLS.md, README.md  
**Testes**: tests/WHICH-TEST.md, tests/QUICK-REFERENCE.md  
**Contribuição**: CONTRIBUTING.md, tests/CONTRIBUTOR-CHECKLIST.md  
**Histórico**: CHANGELOG.md, RECOMMENDED-ADDITIONS.md  
**Arquitetura**: .kiro/specs/.../design.md  

### Por Tipo de Usuário

**Usuário Final**: README.md, OPTIONAL-TOOLS.md  
**Desenvolvedor**: CONTRIBUTING.md, tests/WHICH-TEST.md, design.md  
**Contribuidor**: CONTRIBUTING.md, CONTRIBUTOR-CHECKLIST.md  
**Mantenedor**: Todos os documentos  

---

## 💡 Dicas

1. **Comece pelo README.md** - É o ponto de entrada principal
2. **Use WHICH-TEST.md** - Para decidir qual teste executar
3. **Consulte OPTIONAL-TOOLS.md** - Para ver todas as ferramentas
4. **Leia CONTRIBUTOR-CHECKLIST.md** - Antes de fazer commits

---

**Última Atualização**: 2024-11-15  
**Mantido por**: Rafael Fino
