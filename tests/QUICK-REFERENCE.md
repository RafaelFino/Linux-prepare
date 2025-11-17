# Guia Rápido de Testes

## 🚀 Comandos Rápidos

### Executar Todos os Testes
```bash
./tests/run-all-tests.sh
```
⏱️ Tempo: ~100 minutos | 🎯 Testa: Ubuntu, Debian, Xubuntu, Mint, Pop!_OS, Idempotência

### Testar Apenas Derivados
```bash
./tests/test-derivatives.sh
```
⏱️ Tempo: ~45 minutos | 🎯 Testa: Xubuntu, Mint, Pop!_OS

### Teste Rápido (Ubuntu apenas)
```bash
./tests/quick-test.sh
```
⏱️ Tempo: ~15 minutos | 🎯 Testa: Ubuntu 24.04

## 📋 Testes Individuais

```bash
# Ubuntu 24.04
docker build -f tests/docker/Dockerfile.ubuntu-24.04 -t test-ubuntu .
docker run --rm test-ubuntu /tmp/validate.sh

# Debian 13
docker build -f tests/docker/Dockerfile.debian-13 -t test-debian .
docker run --rm test-debian /tmp/validate.sh

# Xubuntu 24.04
docker build -f tests/docker/Dockerfile.xubuntu-24.04 -t test-xubuntu .
docker run --rm test-xubuntu /tmp/validate.sh

# Linux Mint 22
docker build -f tests/docker/Dockerfile.mint-22 -t test-mint .
docker run --rm test-mint /tmp/validate.sh
```

## 🔍 Verificar Resultados

### Sucesso ✅
```
============================================
  Summary
============================================
Passed: 30
Failed: 0

All tests passed!
```

### Falha ❌
```
✗ eza: eza is NOT installed
...
Passed: 25
Failed: 5

Some tests failed!
```

## 📚 Documentação Completa

- **[TESTING.md](TESTING.md)** - Guia completo de testes
- **[DISTRIBUTIONS.md](DISTRIBUTIONS.md)** - Info sobre distribuições
- **[TEST-MATRIX.md](TEST-MATRIX.md)** - Matriz de testes detalhada

## 🐛 Troubleshooting

### Docker não está rodando
```bash
sudo systemctl start docker
```

### Sem espaço em disco
```bash
docker system prune -a
```

### Teste falhou
1. Verifique os logs do Docker
2. Execute teste individual
3. Verifique conectividade de rede
4. Limpe cache do Docker

## 💡 Dicas

- Execute `run-all-tests.sh` antes de commits importantes
- Use `test-derivatives.sh` para validação rápida de derivados
- Teste individual para debug específico
- Mantenha Docker atualizado
