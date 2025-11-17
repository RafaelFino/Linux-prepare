# Distribuições Testadas

Distribuições Linux suportadas e testadas.

## Principais

**Ubuntu 24.04**: Referência, GNOME, testes completos  
**Debian 13**: Debian puro, sem desktop, validação base

## Derivadas

**Xubuntu 24.04**: XFCE, testa detecção desktop leve  
**Linux Mint 22**: Cinnamon, repos próprios  
**Pop!_OS 22.04**: GNOME Cosmic, workarounds EZA/Docker/VSCode

## 🔍 Matriz de Compatibilidade

| Recurso | Ubuntu | Debian | Xubuntu | Mint | Pop!_OS |
|---------|--------|--------|---------|------|---------|
| Docker | ✅ | ✅ | ✅ | ✅ | ✅ (workaround) |
| Golang | ✅ | ✅ | ✅ | ✅ | ✅ |
| Python | ✅ | ✅ | ✅ | ✅ | ✅ |
| .NET | ✅ | ✅ | ✅ | ✅ | ✅ |
| JVM/Kotlin | ✅ | ✅ | ✅ | ✅ | ✅ |
| Zsh/Oh-My-Zsh | ✅ | ✅ | ✅ | ✅ | ✅ |
| EZA | ✅ | ✅ | ✅ | ✅ | ✅ (workaround) |
| Desktop Detection | ✅ GNOME | ❌ Server | ✅ XFCE | ✅ Cinnamon | ✅ GNOME Cosmic |
| VSCode | ✅ snap | ✅ snap | ✅ snap | ✅ snap | ✅ apt (workaround) |
| Chrome | ✅ | ✅ | ✅ | ✅ | ✅ |
| Fonts | ✅ | ✅ | ✅ | ✅ | ✅ |

## Testes

**run-all-tests.sh**: Todas distros + idempotência (~100min)  
**test-derivatives.sh**: Xubuntu + Mint + Pop!_OS (~45min)  
**quick-test.sh**: Ubuntu apenas (~15min)

## 📝 Notas de Implementação

### Xubuntu
- Dockerfile instala `xfce4-session` para simular ambiente
- Define `XDG_CURRENT_DESKTOP=XFCE` para detecção
- Não instala desktop completo (economia de espaço)
- Valida que detecção de desktop funciona

### Linux Mint
- Usa imagem oficial `linuxmintd/mint22-amd64`
- Testa compatibilidade com repositórios do Mint
- Valida que todos os componentes instalam corretamente
- Garante que derivados funcionam sem modificações

## 🎯 Quando Executar Cada Teste

### Sempre Execute (CI/CD)
- `run-all-tests.sh` - Antes de cada release
- Validação completa de todas as distribuições

### Execute Quando Modificar
- **Desktop detection**: Teste Xubuntu
- **Repositórios/pacotes**: Teste Mint
- **Core functionality**: Teste Ubuntu + Debian

### Teste Manual
- Raspberry Pi OS (ARM)
- Outras variantes (Kubuntu, Lubuntu, etc.)

## 🚀 Adicionando Novas Distribuições

Para adicionar uma nova distribuição aos testes:

1. Criar `Dockerfile.{distro}-{version}` em `tests/docker/`
2. Adicionar ao `tests/run-all-tests.sh`
3. Atualizar tabela no `README.md`
4. Documentar diferenças neste arquivo
5. Executar testes completos




## Pop!_OS Workarounds

**EZA**: cargo install to /usr/local/bin → fallback exa  
**Docker**: Remove conflitos → repos Pop!_OS  
**VSCode**: Repo Microsoft → apt install

**Note**: Binários instalados em `/usr/local/bin` (acesso global)
