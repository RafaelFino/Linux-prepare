# Distribuições Testadas

Distribuições Linux suportadas e testadas.

## Principais

**Ubuntu 24.04**: Referência, GNOME, testes completos  
**Debian 13**: Debian puro, sem desktop, validação base

## Derivadas

**Xubuntu 24.04**: XFCE, testa detecção desktop leve  
**Xubuntu 25.10**: XFCE, testa nova versão com seleção automática eza  
**Linux Mint 22**: Cinnamon, repos próprios  
**Pop!_OS 22.04**: GNOME Cosmic, workarounds EZA/Docker/VSCode

## 🔍 Matriz de Compatibilidade

| Recurso | Ubuntu | Debian | Xubuntu 24.04 | Xubuntu 25.10 | Mint | Pop!_OS |
|---------|--------|--------|---------------|---------------|------|---------|
| Docker | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (workaround) |
| Golang | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Python | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| .NET | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| JVM/Kotlin | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Zsh/Oh-My-Zsh | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| EZA/EXA | ✅ eza | ✅ eza | ✅ exa | ✅ eza | ✅ eza | ✅ (workaround) |
| Desktop Detection | ✅ GNOME | ❌ Server | ✅ XFCE | ✅ XFCE | ✅ Cinnamon | ✅ GNOME Cosmic |
| VSCode | ✅ snap | ✅ snap | ✅ snap | ✅ snap | ✅ snap | ✅ apt (workaround) |
| Chrome | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Fonts | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

## Testes

**run-all-tests.sh**: Todas distros + idempotência (~120min)  
**test-derivatives.sh**: Xubuntu 24.04 + Xubuntu 25.10 + Mint + Pop!_OS (~60min)  
**quick-test.sh**: Ubuntu apenas (~15min)

## 📝 Notas de Implementação

### Seleção Automática de Pacotes por Versão

O sistema agora detecta automaticamente a versão do Ubuntu/Xubuntu e seleciona o pacote apropriado:

| Distribuição | Versão | Pacote ls | Motivo |
|-------------|---------|-----------|--------|
| Ubuntu | 22.04 | `exa` | Disponível nos repositórios padrão |
| Ubuntu | 24.04+ | `eza` | Substituto moderno, mais recursos |
| Xubuntu | 24.04 | `exa` | Baseado no Ubuntu 22.04 |
| Xubuntu | 25.10 | `eza` | Baseado no Ubuntu 25.10 |
| Debian | 13+ | `eza` | Versão mais recente disponível |

**Fallback**: Se o pacote preferido não estiver disponível, o sistema tenta automaticamente a alternativa.

### Xubuntu 24.04
- Dockerfile instala `xfce4-session` para simular ambiente
- Define `XDG_CURRENT_DESKTOP=XFCE` para detecção
- Não instala desktop completo (economia de espaço)
- Valida que detecção de desktop funciona
- Usa pacote `exa` (baseado no Ubuntu 22.04)

### Xubuntu 25.10
- Dockerfile baseado no Ubuntu 25.10
- Mesma configuração XFCE que 24.04
- Usa pacote `eza` (versão mais recente)
- Testa detecção automática de versão
- Valida compatibilidade com repositórios Ubuntu 25.10

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
- **Desktop detection**: Teste Xubuntu 24.04 e 25.10
- **Version detection**: Teste Xubuntu 25.10 (eza) vs 24.04 (exa)
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
