# Testar Pop!_OS - Guia Rápido

## Executar Testes

```bash
# Apenas Pop!_OS
./tests/test-popos.sh

# Todos os derivados
./tests/test-derivatives.sh

# Tudo
./tests/run-all-tests.sh
```

## Teste Manual

```bash
# Construir container
docker build -f tests/docker/Dockerfile.popos-22.04 -t test-popos .

# Executar validação
docker run --rm test-popos /tmp/validate.sh

# Verificar componentes específicos
docker run --rm test-popos bash -c "which eza || which exa"
docker run --rm test-popos bash -c "docker --version"
docker run --rm test-popos bash -c "dpkg -l | grep code"
```

## O Que Verificar

- ✅ Pop!_OS detectado (`ID=pop` em /etc/os-release)
- ✅ EZA ou exa instalado
- ✅ Docker funcionando
- ✅ VSCode via apt (não snap)
- ✅ Todas as ferramentas base presentes

## Reportar Problemas

Incluir:
- Comando executado
- Mensagem de erro
- Últimas 20 linhas da saída
- Qual workaround falhou (EZA/Docker/VSCode)
