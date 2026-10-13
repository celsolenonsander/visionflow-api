#!/bin/bash
# ============================================================
# apply_all.sh — Aplica todos os seeds do Demo Comercial
# ============================================================
# Uso:
#   ./db/seeds/demo_comercial/apply_all.sh
#
# Requisitos:
#   - PostgreSQL rodando
#   - .pgpass configurado (para não pedir senha)
#   - Tenant "distribuidora-sao-joao" ainda não existente
#     (ou já existente, pois os seeds são idempotentes)
# ============================================================

set -e

# Caminhos
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Configurações
DB_NAME="epare_forca_de_vendas"
DB_USER="epare"
DB_HOST="localhost"
DB_PORT="5432"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'  # sem cor

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║  🎬 Seed — Demo Comercial (Bebidas)       ║"
echo "║     Distribuidora São João                ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Verifica conexão
echo -e "${YELLOW}🔌 Testando conexão com o banco...${NC}"
if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${RED}❌ Não foi possível conectar no banco '$DB_NAME'${NC}"
    echo "   Verifique se o PostgreSQL está rodando e se o .pgpass está configurado."
    exit 1
fi
echo -e "${GREEN}✅ Conexão OK${NC}"
echo ""

# Aplica cada arquivo em ordem
ARQUIVOS=(
    "001_base.sql"
    "002_cadastros.sql"
    "003_clientes.sql"
    "004_produtos.sql"
    "005_pedidos.sql"
)

TOTAL=${#ARQUIVOS[@]}
ATUAL=0

for ARQUIVO in "${ARQUIVOS[@]}"; do
    ATUAL=$((ATUAL + 1))
    CAMINHO="$SCRIPT_DIR/$ARQUIVO"

    if [ ! -f "$CAMINHO" ]; then
        echo -e "${RED}❌ Arquivo não encontrado: $ARQUIVO${NC}"
        exit 1
    fi

    echo -e "${YELLOW}[$ATUAL/$TOTAL] 📦 Aplicando $ARQUIVO...${NC}"

    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
            -f "$CAMINHO" > /tmp/seed_$$.log 2>&1; then
        # Mostra apenas NOTICEs importantes
        grep -E "NOTICE|ERROR" /tmp/seed_$$.log | sed 's/^/    /' || true
        echo -e "${GREEN}    ✅ OK${NC}"
    else
        echo -e "${RED}    ❌ ERRO ao aplicar $ARQUIVO${NC}"
        cat /tmp/seed_$$.log
        rm -f /tmp/seed_$$.log
        exit 1
    fi
    echo ""
done

rm -f /tmp/seed_$$.log

# Resumo final
echo "╔════════════════════════════════════════════╗"
echo "║  ✅ Seed aplicado com sucesso!             ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "Para consultar os dados, use o padrão:"
echo ""
echo "  psql -h $DB_HOST -U $DB_USER -d $DB_NAME << 'EOF'"
echo "  BEGIN;"
echo "  SET LOCAL app.cod_tenant = '4';"
echo "  SET LOCAL app.cod_empresa = '1';"
echo "  SELECT COUNT(*) FROM cliente;"
echo "  COMMIT;"
echo "  EOF"
echo ""