#!/bin/bash
set -e

echo "═══════════════════════════════════════════════"
echo "  VisionFlow API — Setup do Codespaces"
echo "═══════════════════════════════════════════════"

# ─── 1. Instalar cliente PostgreSQL ─────────────
echo ""
echo "▸ Instalando cliente PostgreSQL..."
sudo apt-get update -qq
sudo apt-get install -y -qq postgresql-client wget

# ─── 2. Instalar Flyway CLI ─────────────────────
echo ""
echo "▸ Instalando Flyway CLI..."
FLYWAY_VERSION="10.20.1"
cd /tmp
wget -q "https://download.red-gate.com/maven/release/com/redgate/flyway/flyway-commandline/${FLYWAY_VERSION}/flyway-commandline-${FLYWAY_VERSION}-linux-x64.tar.gz"
tar -xzf "flyway-commandline-${FLYWAY_VERSION}-linux-x64.tar.gz"
sudo ln -sf "/tmp/flyway-${FLYWAY_VERSION}/flyway" /usr/local/bin/flyway
cd /workspaces/visionflow-api
echo "  Flyway instalado: $(flyway -v 2>&1 | head -1)"

# ─── 3. Criar .env (se não existir) ─────────────
echo ""
echo "▸ Configurando .env..."
if [ ! -f .env ]; then
    cp .env.example .env
    # Substitui a senha pelo valor real do compose
    sed -i "s|DB_PASSWORD=trocar_pela_senha_real|DB_PASSWORD=epare|" .env
    # Gera JWT_SECRET aleatório
    JWT=$(openssl rand -base64 48 | tr -d '\n')
    sed -i "s|JWT_SECRET=trocar_por_uma_string_longa_e_aleatoria|JWT_SECRET=${JWT}|" .env
    echo "  .env criado com senha e JWT aleatórios"
else
    echo "  .env já existe, mantendo"
fi

# ─── 4. Esperar Postgres ────────────────────────
echo ""
echo "▸ Aguardando PostgreSQL..."
until pg_isready -h postgres -U epare -d epare_forca_de_vendas -q; do
    echo "  ...aguardando"
    sleep 2
done
echo "  PostgreSQL pronto!"

# ─── 5. Rodar migrations ────────────────────────
echo ""
echo "▸ Rodando migrations..."
flyway \
    -url="jdbc:postgresql://postgres:5432/epare_forca_de_vendas" \
    -user="epare" \
    -password="epare" \
    -locations="filesystem:./db/migrations" \
    -baselineOnMigrate=true \
    -baselineVersion=0 \
    migrate

# ─── 6. Pronto ──────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════"
echo "  ✅ Codespace pronto!"
echo ""
echo "  PostgreSQL: localhost:5432"
echo "  API:        rode: go run ./cmd/api"
echo "              acesse: http://localhost:8080/health"
echo "═══════════════════════════════════════════════"