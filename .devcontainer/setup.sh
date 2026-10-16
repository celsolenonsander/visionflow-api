#!/bin/bash
set -Eeuo pipefail

PROJECT_DIR="/workspaces/visionflow-api"
FLYWAY_VERSION="10.20.1"

echo "==============================================="
echo " VisionFlow API - Setup do Codespaces"
echo "==============================================="

cd "$PROJECT_DIR"

echo ""
echo ">>> Instalando dependências..."

sudo apt-get update -qq
sudo apt-get install -y -qq \
    postgresql-client \
    wget \
    openssl \
    ca-certificates \
    default-jre-headless

echo ""
echo ">>> Instalando Flyway..."

if ! command -v flyway >/dev/null 2>&1; then
    cd /tmp

    wget -q \
        "https://download.red-gate.com/maven/release/com/redgate/flyway/flyway-commandline/${FLYWAY_VERSION}/flyway-commandline-${FLYWAY_VERSION}-linux-x64.tar.gz" \
        -O flyway.tar.gz

    tar -xzf flyway.tar.gz

    sudo ln -sf \
        "/tmp/flyway-${FLYWAY_VERSION}/flyway" \
        /usr/local/bin/flyway
fi

cd "$PROJECT_DIR"

flyway -v

echo ""
echo ">>> Verificando arquivo .env..."

if [ ! -f .env ]; then
    cp .env.example .env
    JWT_SECRET="$(openssl rand -hex 32)"

    sed -i \
        "s|JWT_SECRET=trocar_por_uma_string_longa_e_aleatoria|JWT_SECRET=${JWT_SECRET}|" \
        .env

    echo "Arquivo .env criado."
else
    echo "Arquivo .env existente preservado."
fi

# Carrega as configurações sem exibir senhas.
set -a
source .env
set +a

: "${DB_USER:?DB_USER não definido no .env}"
: "${DB_PASSWORD:?DB_PASSWORD não definido no .env}"
: "${DB_NAME:?DB_NAME não definido no .env}"
: "${JWT_SECRET:?JWT_SECRET não definido no .env}"

# No Codespaces, o PostgreSQL é outro serviço do Compose.
DB_HOST="postgres"
DB_PORT="5432"

echo ""
echo ">>> Aguardando PostgreSQL..."

for tentativa in $(seq 1 60); do
    if PGPASSWORD="$DB_PASSWORD" pg_isready \
        -h "$DB_HOST" \
        -p "$DB_PORT" \
        -U "$DB_USER" \
        -d "$DB_NAME" \
        -q; then
        break
    fi

    if [ "$tentativa" -eq 60 ]; then
        echo "ERRO: PostgreSQL não ficou disponível após 120 segundos."
        exit 1
    fi

    sleep 2
done

echo "PostgreSQL disponível."

echo ""
echo ">>> Executando migrations..."

flyway \
    "-url=jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}" \
    "-user=${DB_USER}" \
    "-password=${DB_PASSWORD}" \
    "-locations=filesystem:${PROJECT_DIR}/db/migrations" \
    -baselineOnMigrate=true \
    -baselineVersion=0 \
    migrate

echo ""
echo "==============================================="
echo " VisionFlow API - Setup concluído!"
echo "==============================================="
echo ""
go version
echo "PostgreSQL: ${DB_HOST}:${DB_PORT}"
echo "Para iniciar a API: go run ./cmd/api"