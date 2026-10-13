#!/bin/bash
# ============================================================
# reset_db.sh — Recria o banco do zero e aplica as migrations
# ============================================================
# ATENÇÃO: apaga TODOS os dados. Use apenas em desenvolvimento!
# ============================================================

set -e

DB_NAME="epare_forca_de_vendas"
DB_USER="epare"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "⚠️  Vai APAGAR TODOS OS DADOS do banco '$DB_NAME'."
read -p "   Tem certeza? (s/N): " CONFIRMA
if [[ ! "$CONFIRMA" =~ ^[sS]$ ]]; then
    echo "Cancelado."
    exit 0
fi

echo ""
echo "🗑  Dropando banco..."
sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME;"

echo ""
echo "🆕 Criando banco..."
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"

echo ""
echo "🔧 Ajustando permissões..."
sudo -u postgres psql -d $DB_NAME -c "ALTER SCHEMA public OWNER TO $DB_USER;"
sudo -u postgres psql -d $DB_NAME -c "GRANT ALL ON SCHEMA public TO $DB_USER;"

echo ""
echo "📦 Aplicando migrations..."
cd "$PROJECT_ROOT"
flyway -configFiles=./db/flyway.conf migrate

echo ""
echo "✅ Banco recriado com sucesso!"