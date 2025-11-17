# Qual Teste Executar?

## 🤔 Guia de Decisão

```
┌─────────────────────────────────────────────────────────────┐
│              QUAL TESTE DEVO EXECUTAR?                       │
└─────────────────────────────────────────────────────────────┘

Você modificou...

📝 Documentação apenas?
   └─> Nenhum teste necessário

🔧 Código core (scripts/prepare.sh)?
   └─> ./tests/run-all-tests.sh (todos)

🎨 Detecção de desktop?
   └─> ./tests/test-derivatives.sh (Xubuntu + Mint + Pop!_OS)

📦 Instalação de pacotes?
   └─> ./tests/quick-test.sh (Ubuntu rápido)
       Se OK → ./tests/run-all-tests.sh

🐧 Suporte a distribuições?
   └─> ./tests/run-all-tests.sh (todos)

⚡ Validação rápida?
   └─> ./tests/quick-test.sh (15 min)

🚀 Antes de release?
   └─> ./tests/run-all-tests.sh (obrigatório)

🔍 Debug de problema específico?
   └─> Teste individual da distribuição
```

## 📊 Comparação de Testes

| Teste | Tempo | Distribuições | Quando Usar |
|-------|-------|---------------|-------------|
| **quick-test.sh** | ~15 min | Ubuntu 24.04 | Validação rápida, mudanças pequenas |
| **test-derivatives.sh** | ~45 min | Xubuntu, Mint, Pop!_OS | Mudanças em desktop detection ou derivados |
| **run-all-tests.sh** | ~80 min | Todas + Idempotência | Antes de commit importante, release |

## 🎯 Por Cenário

### Desenvolvimento Diário
```bash
# Mudança pequena
./tests/quick-test.sh

# Se passou, commit
git commit -m "feat: ..."
```

### Mudança em Desktop
```bash
# Testar detecção de desktop
./tests/test-derivatives.sh

# Se passou, testar tudo
./tests/run-all-tests.sh
```

### Antes de Pull Request
```bash
# Sempre executar tudo
./tests/run-all-tests.sh

# Todos passaram? PR!
git push origin feature-branch
```

### Antes de Release
```bash
# Obrigatório: todos os testes
./tests/run-all-tests.sh

# Validar manualmente em VM real
# Atualizar CHANGELOG.md
# Tag de versão
```

## 🐛 Debug de Falhas

### Teste Falhou?

```
1. Identifique qual distribuição falhou
   └─> Veja logs do Docker

2. Execute teste individual
   └─> docker build -f tests/docker/Dockerfile.{distro} ...

3. Entre no container para debug
   └─> docker run -it {image} /bin/bash

4. Execute comandos manualmente
   └─> /tmp/prepare.sh
   └─> /tmp/validate.sh

5. Corrija o problema

6. Re-execute teste completo
   └─> ./tests/run-all-tests.sh
```

## ⚡ Atalhos Úteis

```bash
# Teste rápido
alias qt='./tests/quick-test.sh'

# Teste derivados
alias td='./tests/test-derivatives.sh'

# Teste completo
alias at='./tests/run-all-tests.sh'

# Limpar Docker
alias dc='docker system prune -a'
```

## 📈 Fluxo Recomendado

```
Desenvolvimento
    ↓
quick-test.sh (15 min)
    ↓
    ├─> ✅ Passou → Commit
    └─> ❌ Falhou → Debug → Retry
    
Antes de PR
    ↓
run-all-tests.sh (80 min)
    ↓
    ├─> ✅ Passou → Push PR
    └─> ❌ Falhou → Fix → Retry
    
Antes de Release
    ↓
run-all-tests.sh (80 min)
    ↓
Teste manual em VM
    ↓
    ├─> ✅ Passou → Release
    └─> ❌ Falhou → Fix → Retry
```

## 💡 Dicas

- **Desenvolvimento**: Use quick-test para feedback rápido
- **Desktop**: Use test-derivatives para mudanças de UI
- **Release**: Sempre execute run-all-tests
- **CI/CD**: Configure run-all-tests no pipeline
- **Debug**: Use testes individuais para isolar problemas

## 🎓 Exemplos Práticos

### Exemplo 1: Adicionei novo pacote
```bash
# Teste rápido primeiro
./tests/quick-test.sh

# Se passou, teste tudo
./tests/run-all-tests.sh
```

### Exemplo 2: Mudei detecção de XFCE
```bash
# Teste derivados (inclui Xubuntu)
./tests/test-derivatives.sh

# Se passou, teste tudo
./tests/run-all-tests.sh
```

### Exemplo 3: Refatorei script principal
```bash
# Teste tudo imediatamente
./tests/run-all-tests.sh
```

### Exemplo 4: Atualizei documentação
```bash
# Nenhum teste necessário
# Apenas revise e commit
```

## 🚦 Semáforo de Decisão

🟢 **Verde (quick-test)**
- Mudanças pequenas
- Novo alias
- Ajuste de configuração
- Correção de typo em código

🟡 **Amarelo (test-derivatives)**
- Mudança em detecção de desktop
- Novo componente desktop
- Mudança em fontes
- Configuração de terminal

🔴 **Vermelho (run-all-tests)**
- Mudança em lógica core
- Novo componente principal
- Mudança em instalação
- Antes de release
- Antes de PR importante

## 📞 Ainda em Dúvida?

**Na dúvida, execute o teste mais completo!**

```bash
./tests/run-all-tests.sh
```

Melhor gastar 80 minutos testando do que descobrir um bug em produção! 🎯
