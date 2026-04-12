#!/usr/bin/env bash
# =============================================================================
# Script de Teste via Docker — prepare.sh
# =============================================================================
#
# Descrição : Constrói e executa um container Docker com ubuntu:latest para
#             testar o prepare.sh em um ambiente limpo e isolado.
#
# Uso       : ./test-in-docker.sh [FLAGS_DO_PREPARE]
#             Sem argumentos, executa com --full por padrão.
#
# Exemplos  : ./test-in-docker.sh              # executa com --full
#             ./test-in-docker.sh --base        # executa apenas grupo BASE
#             ./test-in-docker.sh --base --docker  # BASE + DOCKER
#
# Notas     : - Requer Docker instalado e acessível
#             - Limpa containers após execução (sem acumular órfãos)
#             - A imagem é reutilizada entre execuções (rebuild apenas se necessário)
#
# Requisitos: 16.1, 16.2, 16.3, 16.4, 16.5, 16.6
# =============================================================================

set -euo pipefail

# --- Configuração ---
IMAGE_NAME="prepare-test"
CONTAINER_NAME="prepare-test-run"

# Se nenhum argumento fornecido, usar --full por padrão
SCRIPT_FLAGS="${*:---full}"

# --- Limpeza prévia ---
# Remover container anterior (se existir) para evitar conflito de nomes
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

echo "=============================================="
echo "Teste do prepare.sh via Docker"
echo "=============================================="
echo "Imagem base : ubuntu:latest"
echo "Flags       : $SCRIPT_FLAGS"
echo "=============================================="

# --- Construir imagem ---
echo ""
echo "Construindo imagem Docker..."
docker build -t "$IMAGE_NAME" -f- . <<'DOCKERFILE'
FROM ubuntu:latest
RUN apt-get update && apt-get install -y sudo curl wget git
COPY prepare.sh /root/prepare.sh
RUN chmod +x /root/prepare.sh
DOCKERFILE

# --- Executar o script dentro do container ---
echo ""
echo "Executando prepare.sh com flags: $SCRIPT_FLAGS"
echo "----------------------------------------------"

EXIT_CODE=0
if docker run --name "$CONTAINER_NAME" "$IMAGE_NAME" \
    bash -c "/root/prepare.sh $SCRIPT_FLAGS"; then
    echo ""
    echo "=============================================="
    echo "=== RESULTADO: SUCESSO ==="
    echo "=============================================="
else
    EXIT_CODE=$?
    echo ""
    echo "=============================================="
    echo "=== RESULTADO: FALHA (exit code: $EXIT_CODE) ==="
    echo "=============================================="
fi

# --- Limpeza pós-execução ---
# Remover container para não acumular containers parados
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

exit $EXIT_CODE
 