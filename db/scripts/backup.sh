#!/bin/bash
# ============================================================
# backup.sh — Backup do banco de dados
# ============================================================

set -e

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

echo "[$(date)] Iniciando backup de $DB_NAME..."

pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" | gzip > "$ARQUIVO"

TAMANHO=$(du -h "$ARQUIVO" | cut -f1)
echo "[$(date)] ✅ Backup concluído: $ARQUIVO ($TAMANHO)"

echo "[$(date)] Removendo backups com mais de $RETENCAO_DIAS dias..."
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENCAO_DIAS -print -delete

echo ""
echo "📁 Backups disponíveis:"
ls -lh "$BACKUP_DIR" | tail -n +2