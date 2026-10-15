#!/bin/bash

# ============================================================
# backup.sh — Backup seguro do banco PostgreSQL
# ============================================================

set -Eeuo pipefail

DB_NAME="epare_forca_de_vendas"
DB_USER="epare"
DB_HOST="localhost"
DB_PORT="5432"
RETENCAO_DIAS=30

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BACKUP_DIR="$PROJECT_ROOT/db/backups"

mkdir -p "$BACKUP_DIR"

DATA=$(date +%Y-%m-%d_%H-%M-%S)
ARQUIVO="$BACKUP_DIR/${DB_NAME}_${DATA}.sql.gz"
ARQUIVO_TEMP="${ARQUIVO}.tmp"

# Remove arquivos temporários se ocorrer algum erro.
limpar_temporario() {
    rm -f "$ARQUIVO_TEMP"
}

trap limpar_temporario EXIT

echo "[$(date)] Iniciando backup de $DB_NAME..."

# Garante que falhas do pg_dump ou do gzip sejam detectadas.
if ! pg_dump \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -U "$DB_USER" \
    "$DB_NAME" | gzip > "$ARQUIVO_TEMP"; then

    echo "[$(date)] ERRO: falha ao gerar o backup." >&2
    exit 1
fi

# Verifica se o arquivo compactado é válido.
if ! gzip -t "$ARQUIVO_TEMP"; then
    echo "[$(date)] ERRO: arquivo gzip inválido." >&2
    exit 1
fi

# Só publica o backup após a geração bem-sucedida.
mv "$ARQUIVO_TEMP" "$ARQUIVO"

TAMANHO=$(du -h "$ARQUIVO" | cut -f1)

echo "[$(date)] Backup concluído: $ARQUIVO ($TAMANHO)"

echo "[$(date)] Removendo backups com mais de $RETENCAO_DIAS dias..."

find "$BACKUP_DIR" \
    -maxdepth 1 \
    -type f \
    -name "*.sql.gz" \
    -mtime +"$RETENCAO_DIAS" \
    -print \
    -delete

echo ""
echo "Backups disponíveis:"
ls -lh "$BACKUP_DIR"