# Guia de Distribuições Testadas

Este documento descreve as distribuições Linux testadas e suas características específicas.

## 📋 Distribuições Principais

### Ubuntu 24.04 LTS
- **Base**: Debian
- **Desktop**: GNOME (padrão)
- **Testes**: Instalação completa de todos os componentes
- **Uso**: Distribuição de referência para testes

### Debian 13
- **Base**: Debian puro
- **Desktop**: Vários (GNOME, KDE, XFCE, etc.)
- **Testes**: Instalação completa sem desktop
- **Uso**: Validação de compatibilidade com Debian puro

## 🎨 Distribuições Derivadas

### Xubuntu 24.04
- **Base**: Ubuntu 24.04
- **Desktop**: XFCE
- **Diferenças**:
  - Ambiente desktop mais leve
  - Mesmos repositórios do Ubuntu
  - Detecção automática de desktop XFCE
- **Testes**: 
  - Validação de detecção de ambiente XFCE
  - Instalação de componentes desktop
  - Configuração de terminal emulators
- **Por que testar**: Garantir que a detecção de desktop funciona com XFCE

### Linux Mint 22
- **Base**: Ubuntu 24.04 LTS
- **Desktop**: Cinnamon (padrão)
- **Diferenças**:
  - Repositórios próprios do Mint
  - Algumas ferramentas específicas do Mint
  - Interface Cinnamon
- **Testes**:
  - Compatibilidade com repositórios do Mint
  - Instalação completa de componentes
  - Detecção de ambiente Cinnamon
- **Por que testar**: Validar compatibilidade com derivados que têm repositórios próprios

## 🔍 Matriz de Compatibilidade

| Recurso | Ubuntu | Debian | Xubuntu | Mint |
|---------|--------|--------|---------|------|
| Docker | ✅ | ✅ | ✅ | ✅ |
| Golang | ✅ | ✅ | ✅ | ✅ |
| Python | ✅ | ✅ | ✅ | ✅ |
| .NET | ✅ | ✅ | ✅ | ✅ |
| JVM/Kotlin | ✅ | ✅ | ✅ | ✅ |
| Zsh/Oh-My-Zsh | ✅ | ✅ | ✅ | ✅ |
| Desktop Detection | ✅ GNOME | ❌ Server | ✅ XFCE | ✅ Cinnamon |
| VSCode | ✅ | ✅ | ✅ | ✅ |
| Chrome | ✅ | ✅ | ✅ | ✅ |
| Fonts | ✅ | ✅ | ✅ | ✅ |

## 🧪 Estratégia de Testes

### Testes Completos (run-all-tests.sh)
Executa testes em todas as distribuições:
1. Ubuntu 24.04 - Baseline
2. Debian 13 - Compatibilidade Debian puro
3. Xubuntu 24.04 - Desktop XFCE
4. Linux Mint 22 - Derivado com repositórios próprios
5. Idempotência - Execução dupla

### Testes de Derivados (test-derivatives.sh)
Executa apenas Xubuntu e Mint para validação rápida de derivados.

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

## 📚 Referências

- [Ubuntu Releases](https://wiki.ubuntu.com/Releases)
- [Debian Releases](https://www.debian.org/releases/)
- [Xubuntu](https://xubuntu.org/)
- [Linux Mint](https://linuxmint.com/)
