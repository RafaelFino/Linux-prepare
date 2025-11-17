# Checklist do Contribuidor

## ✅ Antes de Fazer um Commit

### 1. Código Modificado?
- [ ] Executei `./tests/quick-test.sh` e passou
- [ ] Código está formatado corretamente
- [ ] Sem erros de sintaxe
- [ ] Comentários atualizados

### 2. Mudança em Desktop?
- [ ] Executei `./tests/test-derivatives.sh` e passou
- [ ] Testei detecção de XFCE (Xubuntu)
- [ ] Testei detecção de Cinnamon (Mint)

### 3. Mudança Significativa?
- [ ] Executei `./tests/run-all-tests.sh` e passou
- [ ] Todos os 5 cenários passaram
- [ ] Idempotência validada

## ✅ Antes de Abrir Pull Request

### Testes
- [ ] `./tests/run-all-tests.sh` passou completamente
- [ ] Testei em VM real (opcional mas recomendado)
- [ ] Sem warnings ou erros nos logs

### Documentação
- [ ] README.md atualizado (se necessário)
- [ ] CHANGELOG.md atualizado
- [ ] Comentários no código atualizados
- [ ] Exemplos funcionando

### Código
- [ ] Sem código comentado desnecessário
- [ ] Sem TODOs pendentes
- [ ] Variáveis com nomes descritivos
- [ ] Funções documentadas

### Git
- [ ] Mensagem de commit clara e descritiva
- [ ] Branch atualizado com main/master
- [ ] Sem conflitos

## ✅ Antes de Release

### Testes Completos
- [ ] `./tests/run-all-tests.sh` passou
- [ ] Testado em Ubuntu 24.04 real
- [ ] Testado em Debian 13 real (se possível)
- [ ] Testado em Xubuntu, Mint ou Pop!_OS real (se possível)

### Documentação
- [ ] CHANGELOG.md atualizado com versão
- [ ] README.md reflete todas as mudanças
- [ ] Exemplos testados e funcionando
- [ ] Links da documentação funcionando

### Validação
- [ ] Versão atualizada em arquivos relevantes
- [ ] Tag git criada
- [ ] Release notes preparadas

## 📋 Checklist por Tipo de Mudança

### 🐛 Bug Fix
- [ ] Bug reproduzido
- [ ] Correção implementada
- [ ] Teste adicionado para prevenir regressão
- [ ] `./tests/quick-test.sh` passou
- [ ] Documentado no CHANGELOG

### ✨ Nova Feature
- [ ] Feature implementada
- [ ] Testes adicionados
- [ ] `./tests/run-all-tests.sh` passou
- [ ] Documentação atualizada
- [ ] Exemplos adicionados

### 📚 Documentação
- [ ] Texto revisado
- [ ] Links verificados
- [ ] Exemplos testados
- [ ] Formatação correta

### 🎨 Mudança de UI/Desktop
- [ ] `./tests/test-derivatives.sh` passou
- [ ] Testado em ambiente desktop real
- [ ] Screenshots atualizados (se aplicável)
- [ ] Documentação atualizada

### 🔧 Refatoração
- [ ] Funcionalidade mantida
- [ ] `./tests/run-all-tests.sh` passou
- [ ] Performance não degradou
- [ ] Código mais limpo/legível

## 🚨 Red Flags (Não Faça!)

- ❌ Commit sem testar
- ❌ PR sem executar run-all-tests.sh
- ❌ Mudança sem atualizar documentação
- ❌ Código comentado no commit
- ❌ TODOs não resolvidos
- ❌ Mensagens de commit vagas ("fix", "update")
- ❌ Quebrar idempotência
- ❌ Hardcoded values sem justificativa

## 💡 Boas Práticas

### Commits
```bash
# Bom ✅
git commit -m "feat: add support for Fedora 39"
git commit -m "fix: resolve Docker detection on Mint"
git commit -m "docs: update testing guide"

# Ruim ❌
git commit -m "update"
git commit -m "fix stuff"
git commit -m "changes"
```

### Testes
```bash
# Durante desenvolvimento
./tests/quick-test.sh

# Antes de commit importante
./tests/run-all-tests.sh

# Debug de problema
docker build -f tests/docker/Dockerfile.ubuntu-24.04 -t test .
docker run -it test /bin/bash
```

### Documentação
- Sempre atualize CHANGELOG.md
- Mantenha README.md sincronizado
- Adicione exemplos práticos
- Use linguagem clara e objetiva

## 🎯 Fluxo Ideal

```
1. Criar branch
   └─> git checkout -b feature/minha-feature

2. Desenvolver
   └─> Fazer mudanças
   └─> ./tests/quick-test.sh (validação rápida)

3. Finalizar
   └─> ./tests/run-all-tests.sh (validação completa)
   └─> Atualizar documentação
   └─> Atualizar CHANGELOG.md

4. Commit
   └─> git add .
   └─> git commit -m "feat: descrição clara"

5. Push
   └─> git push origin feature/minha-feature

6. Pull Request
   └─> Descrever mudanças
   └─> Referenciar issues
   └─> Aguardar review
```

## 📞 Dúvidas?

- Consulte [WHICH-TEST.md](WHICH-TEST.md) para decidir qual teste executar
- Veja [TESTING.md](TESTING.md) para guia completo de testes
- Leia [CONTRIBUTING.md](../CONTRIBUTING.md) para guidelines gerais

## 🎉 Obrigado por Contribuir!

Sua contribuição ajuda a tornar este projeto melhor para todos! 🚀
