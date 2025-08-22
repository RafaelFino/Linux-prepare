#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ============================================================
# Script: github-ssh-import.sh
# Descrição: Busca as chaves públicas de um usuário do GitHub
#            e adiciona ao ~/.ssh/authorized_keys do servidor.
# Uso: ./github-ssh-import.sh <github_username>
# ============================================================

# Funções utilitárias
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

error_exit() {
  echo "Erro: $*" >&2
  exit 1
}

# Validação de entrada
if [[ $# -ne 1 ]]; then
  error_exit "Uso: $0 <github_username>"
fi

GITHUB_USER="$1"
SSH_DIR="$HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"
TMP_KEYS="$(mktemp)"

# Busca as chaves do GitHub
log "Buscando chaves públicas para o usuário: $GITHUB_USER"
if ! curl -fsSL "https://github.com/${GITHUB_USER}.keys" -o "$TMP_KEYS"; then
  error_exit "Não foi possível buscar as chaves do GitHub"
fi

if [[ ! -s "$TMP_KEYS" ]]; then
  error_exit "Nenhuma chave encontrada para o usuário $GITHUB_USER"
fi

# Garante que a pasta ~/.ssh existe e tem as permissões corretas
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
touch "$AUTHORIZED_KEYS"
chmod 600 "$AUTHORIZED_KEYS"

# Adiciona as chaves, evitando duplicadas
log "Adicionando chaves ao $AUTHORIZED_KEYS"
while IFS= read -r key; do
  if grep -qxF "$key" "$AUTHORIZED_KEYS"; then
    log "Chave já existente, ignorando."
  else
    echo "$key" >> "$AUTHORIZED_KEYS"
    log "Chave adicionada."
  fi
done < "$TMP_KEYS"

# Limpeza
rm -f "$TMP_KEYS"

log "Concluído! Agora o usuário $GITHUB_USER pode acessar via SSH."
