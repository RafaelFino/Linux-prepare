# Contribuindo para Configuração de Ambiente de Desenvolvimento Linux

Obrigado pelo seu interesse em contribuir! Este documento fornece diretrizes para contribuir com este projeto.

## 🤝 Como Contribuir

### Reportando Problemas

- Use GitHub Issues para reportar bugs ou sugerir funcionalidades
- Pesquise issues existentes antes de criar uma nova
- Forneça informações detalhadas:
  - Distribuição e versão
  - Passos para reproduzir
  - Comportamento esperado vs comportamento real
  - Mensagens de erro ou logs

### Enviando Mudanças

1. **Faça um fork do repositório**
2. **Crie uma branch de funcionalidade**
   ```bash
   git checkout -b feature/nome-da-sua-funcionalidade
   ```
3. **Faça suas mudanças**
4. **Teste suas mudanças**
   - Teste em múltiplas distribuições se possível
   - Garanta idempotência (script pode executar múltiplas vezes)
   - Execute testes de validação
5. **Faça commit das suas mudanças**
   ```bash
   git commit -m "Add: descrição das suas mudanças"
   ```
6. **Faça push para seu fork**
   ```bash
   git push origin feature/nome-da-sua-funcionalidade
   ```
7. **Abra um Pull Request**

## 📝 Diretrizes de Código

### Shell Scripts

- Use shebang `#!/usr/bin/env bash`
- Habilite modo estrito: `set -euo pipefail`
- Use nomes de variáveis significativos
- Adicione comentários para lógica complexa
- Siga o estilo de código existente
- Use funções para código reutilizável
- Implemente verificações de idempotência

### Ansible

- Siga as melhores práticas do Ansible
- Use sintaxe YAML corretamente (indentação de 2 espaços)
- Torne roles idempotentes
- Documente variáveis em defaults/main.yml
- Use tags apropriadamente
- Teste playbooks antes de enviar

### Documentação

- Atualize README.md para novas funcionalidades
- Adicione exemplos para novas funcionalidades
- Mantenha a documentação clara e concisa
- Use formatação markdown apropriada

## 🧪 Testes

### Testes Manuais

Teste suas mudanças em:
- Ubuntu 24.04 (recomendado)
- Debian 13 (recomendado)
- Xubuntu 24.04 (para detecção de desktop)
- Linux Mint 22 (para compatibilidade com derivados)
- Outras distribuições se aplicável

### Testes Automatizados

#### Testes de Scripts

```bash
# Executar todos os testes de scripts
./tests/run-all-tests.sh

# Teste rápido (apenas Ubuntu)
./tests/quick-test.sh

# Testar apenas derivados
./tests/test-derivatives.sh

# Testar distribuição específica
docker build -f tests/docker/Dockerfile.ubuntu-24.04 -t test .
docker run --rm test /tmp/validate.sh
```

#### Testes Ansible

```bash
# Executar todos os testes Ansible
./tests/ansible/run-ansible-tests.sh

# Teste rápido (apenas Ubuntu)
./tests/ansible/quick-test.sh

# Testar apenas derivados
./tests/ansible/test-derivatives.sh

# Testar playbook específico
./tests/ansible/run-ansible-tests.sh --playbook server.yml

# Testar role específica
./tests/ansible/run-ansible-tests.sh --role docker
```

📖 **Para documentação completa de testes Ansible**, veja [tests/ansible/README.md](tests/ansible/README.md)

### Checklist de Validação

#### Para Mudanças em Scripts

- [ ] Script executa sem erros
- [ ] Todos os componentes instalam corretamente
- [ ] Script é idempotente (pode executar múltiplas vezes)
- [ ] Logging é claro e informativo
- [ ] Documentação está atualizada
- [ ] Testes de script passam (`./tests/run-all-tests.sh`)

#### Para Mudanças em Ansible

- [ ] Playbook/role executa sem erros
- [ ] Todos os componentes instalam corretamente
- [ ] Playbook/role é idempotente
- [ ] Sintaxe YAML está correta
- [ ] ansible-lint passa
- [ ] Variáveis estão documentadas
- [ ] Documentação está atualizada
- [ ] Testes Ansible passam (`./tests/ansible/run-ansible-tests.sh`)

#### Para Ambos

- [ ] Testado em múltiplas distribuições
- [ ] Detecção de desktop funciona corretamente (se aplicável)
- [ ] Sem mudanças que quebram funcionalidade existente
- [ ] Mensagens de commit são claras e descritivas

## 🎯 Áreas para Contribuição

### Alta Prioridade

- Suporte para distribuições adicionais (Fedora, Arch, etc.)
- Linguagens de programação adicionais
- Otimizações de performance
- Melhor tratamento de erros
- Testes mais abrangentes

### Média Prioridade

- Emuladores de terminal adicionais
- Mais temas e plugins de shell
- Otimizações específicas para provedores de nuvem
- Exemplos de integração CI/CD

### Baixa Prioridade

- Aplicações desktop adicionais
- Configurações customizadas
- Gerenciadores de pacotes alternativos

## 📋 Template de Pull Request

```markdown
## Descrição
Breve descrição das mudanças

## Tipo de Mudança
- [ ] Correção de bug
- [ ] Nova funcionalidade
- [ ] Atualização de documentação
- [ ] Melhoria de performance
- [ ] Refatoração de código

## Testes
- [ ] Testado no Ubuntu 24.04
- [ ] Testado no Debian 13
- [ ] Testado no Xubuntu 24.04 (se mudanças de desktop)
- [ ] Testado no Linux Mint 22 (se mudanças de derivados)
- [ ] Testado idempotência
- [ ] Testes automatizados passam

## Checklist
- [ ] Código segue o estilo do projeto
- [ ] Documentação atualizada
- [ ] Testes adicionados/atualizados
- [ ] Commits são claros e descritivos
```

## 🔍 Processo de Revisão de Código

1. Mantenedor revisa o PR
2. Feedback fornecido se necessário
3. Mudanças solicitadas ou aprovadas
4. PR mesclado após aprovação

## 📜 Licença

Ao contribuir, você concorda que suas contribuições serão licenciadas sob a Licença MIT.

## 💬 Dúvidas?

- Abra uma issue para perguntas
- Marque mantenedores para assuntos urgentes
- Seja respeitoso e paciente

Obrigado por contribuir! 🎉
