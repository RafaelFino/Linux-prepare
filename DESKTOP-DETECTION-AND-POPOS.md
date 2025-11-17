# Detecção de Desktop & Suporte ao Pop!_OS

## O Que Mudou

### Documentação
- Quick Start no topo do README
- Seção Desktop Components (auto-detecção + flags manuais)
- Cenários de uso simplificados
- Pop!_OS adicionado às distribuições suportadas

### Recursos do Script
- Flag `--desktop` para forçar instalação
- Flag `--skip-desktop` para pular instalação
- Auto-detecção de Pop!_OS
- Workarounds para EZA, Docker, VSCode no Pop!_OS
- Auto-instalação de snap e cargo quando necessário

### Testes
- Dockerfile do Pop!_OS adicionado
- test-derivatives.sh inclui Pop!_OS
- test-popos.sh para testes específicos

## Uso Rápido

```bash
# Auto-detecta (padrão)
sudo ./scripts/prepare.sh

# Força instalação desktop
sudo ./scripts/prepare.sh --desktop

# Pula instalação desktop
sudo ./scripts/prepare.sh --skip-desktop
```

## Workarounds do Pop!_OS

**EZA**: Instala cargo → cargo install em /usr/local/bin (global) → fallback exa  
**Docker**: Usa repositórios do Pop!_OS  
**VSCode**: Usa apt ao invés de snap  
**Snap**: Auto-instala snapd quando necessário em outras distros

**Nota**: Binários do cargo instalados em `/usr/local/bin` para acesso de todos os usuários

## Testes

```bash
./tests/test-popos.sh              # Apenas Pop!_OS (~15min)
./tests/test-derivatives.sh        # Todos os derivados (~45min)
./tests/run-all-tests.sh           # Completo (~100min)
```

## Arquivos Modificados

**Docs**: README.md, CHANGELOG.md, tests/DISTRIBUTIONS.md  
**Script**: scripts/prepare.sh  
**Testes**: Dockerfiles, scripts de teste, test-config.yml
