# VisionFlow API

API Go para o sistema **VisionFlow** — plataforma SaaS multi-tenant para
força de vendas, com suporte a **white label** e integração com ERP.

**Estado atual:**
- 🔵 Camada HTTP funcionando com **dados mockados**
- 🟢 Banco de dados PostgreSQL estruturado (62 tabelas + RLS)
- 🟡 Migração dos mocks para o banco **em andamento**

---

## 📋 Sumário

- [Visão geral](#visão-geral)
- [Stack](#stack)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Requisitos](#requisitos)
- [Como executar](#como-executar)
- [Endpoints](#endpoints)
- [Autenticação](#autenticação)
- [Banco de dados](#banco-de-dados)
  - [Estrutura](#estrutura)
  - [Flyway](#flyway)
  - [RLS (multi-tenant)](#rls-multi-tenant)
  - [Backup](#backup)
- [Documentação adicional](#documentação-adicional)
- [Troubleshooting](#troubleshooting)

---

## Visão geral

O VisionFlow é um SaaS para **força de vendas externa**. Estrutura em 3 níveis:

```
REVENDEDOR (white label — quem revende com marca própria)
    └── TENANT (cliente do revendedor — opera o sistema)
            └── EMPRESA (CNPJ do tenant — pode ter várias filiais)
                    └── CLIENTE / ITEM / PEDIDO / ... (dados operacionais)
```

**Isolamento multi-tenant** feito via **Row-Level Security (RLS)** do
PostgreSQL — mesmo que a API esqueça de filtrar, o banco filtra.

---

## Stack

| Camada | Tecnologia | Versão |
|--------|-----------|--------|
| Backend | Go | 1.24+ |
| Router | go-chi/chi | v5 |
| Auth | golang-jwt/jwt | v5 |
| Banco | PostgreSQL | 16 |
| Migrations | Flyway | 13.7.0 |
| Interface DB | pgAdmin 4 | 9.18+ |

---

## Estrutura do projeto

```
visionflow-api/
├── cmd/
│   └── api/                        # Entrypoint da API
│       └── main.go
├── internal/                       # (futuro) lógica interna
│   ├── config/                     # Configurações
│   ├── db/                         # Conexão com o banco
│   ├── handlers/                   # Handlers HTTP
│   └── middleware/                 # Middlewares (JWT, tenant, etc)
├── db/
│   ├── flyway.conf                 # Config Flyway (NÃO commitar)
│   ├── migrations/                 # Migrations versionadas
│   │   ├── V001__nucleo_saas.sql
│   │   ├── V002__cadastros_base.sql
│   │   ├── V003__cadastros_operacionais.sql
│   │   ├── V004__tabelas_filho.sql
│   │   └── V005__rls.sql
│   ├── seeds/                      # Dados de teste
│   └── scripts/                    # Automação
│       ├── reset_db.sh
│       └── backup.sh
├── docs/
│   └── infraestrutura/
│       ├── visionflow-api-cloudflare-tunnel-dominio.html
│       └── visionflow-api-postgresql-infraestrutura.html
├── tools/
│   └── flyway-13.7.0/              # Ferramenta (NÃO commitar)
├── .gitignore
├── go.mod
├── go.sum
└── README.md
```

---

## Requisitos

- **Go 1.24+**
- **PostgreSQL 16** (rodando localmente ou remoto)
- **Flyway 13.7.0** (em `tools/` ou global)
- **Internet** na primeira execução (baixar dependências Go)

---

## Como executar

### 1. Variáveis de ambiente

```bash
cp .env.example .env
```

Edite o `.env` e preencha:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=epare_forca_de_vendas
DB_USER=epare
DB_PASSWORD=<SUA_SENHA>
DB_SSLMODE=disable

SERVER_PORT=8080
JWT_SECRET=<STRING_ALEATORIA_32_CHARS>
JWT_EXPIRATION_HOURS=24
APP_ENV=development
```

Para gerar uma chave JWT forte:

```bash
openssl rand -base64 32
```

### 2. Aplicar migrations

```bash
flyway -configFiles=./db/flyway.conf info
flyway -configFiles=./db/flyway.conf migrate
```

### 3. Rodar a API

```bash
go mod tidy
go run ./cmd/api
```

Serviços disponíveis:

| Serviço | URL |
|---------|-----|
| API | http://localhost:8080 |
| Swagger UI | http://localhost:8080/swagger/index.html |
| OpenAPI Spec | http://localhost:8080/swagger.yaml |

---

## Endpoints

### Autenticação

- `POST /auth/login`
- `POST /auth/logout`

### Negócio

- `GET  /home/indicadores`
- `GET  /clientes`
- `GET  /clientes/{id}`
- `GET  /clientes/cnpj/{cnpj}`
- `GET  /pedidos`
- `POST /pedidos`
- `GET  /pedidos/{id}`
- `GET  /orcamentos`
- `GET  /agenda`
- `GET  /tarefas`
- `GET  /notificacoes`

### Shell (UI)

- `GET /shell/empresa`
- `GET /shell/notificacoes`

> 💡 A camada de serviço usa **mocks** nesta versão. O contrato HTTP foi
> separado da persistência para permitir a troca posterior por PostgreSQL.

---

## Autenticação

### Login mock (desenvolvimento)

```json
{
  "email": "admin@visionflow.app",
  "senha": "123456"
}
```

O login devolve um **JWT**. Endpoints protegidos aceitam:

```http
Authorization: Bearer <token>
```

---

## Banco de dados

### Estrutura

O banco segue o padrão multi-tenant com **62 tabelas**:

| Grupo | Quantidade | Exemplos |
|-------|-----------|----------|
| Núcleo SaaS | 6 | `revendedor`, `tenant`, `empresa`, `usuario` |
| Cadastros base | 18 | `unidade_medida`, `tipo_venda`, `forma_pagamento` |
| Operacionais | 7 | `item`, `cliente`, `pedido` |
| Filhos (N:N) | 31 | `cliente_representante`, `pedido_item` |

**Convenções:**

- PK composta: `(cod_tenant, cod_empresa, codigo)`
- Código externo: `codigo_erp` (único por tenant+empresa)
- Auditoria: `dt_inclusao`, `dt_alteracao`
- Status: `ativo BOOLEAN DEFAULT TRUE` (`NULL` = usa padrão)

### Flyway

O projeto usa **Flyway** para versionar o schema. Estado atual: **versão 5**.

**Comandos principais:**

```bash
# Ver status (sem aplicar nada)
flyway -configFiles=./db/flyway.conf info

# Aplicar migrations pendentes
flyway -configFiles=./db/flyway.conf migrate

# Validar (só verifica)
flyway -configFiles=./db/flyway.conf validate
```

**Criar nova migration:**

1. Nomeie como `V<versão>__<descrição>.sql` (dois underscores!)

   Exemplo: `V006__adiciona_campo_observacao_cliente.sql`

2. Escreva o SQL (ex: `ALTER TABLE cliente ADD COLUMN observacao TEXT;`)

3. Aplique:

   ```bash
   flyway -configFiles=./db/flyway.conf migrate
   ```

> 📖 Detalhes completos em [`db/README.md`](db/README.md)

### RLS (multi-tenant)

Todas as tabelas operacionais têm **Row-Level Security**. A API injeta o
contexto do tenant no início de cada transação:

```sql
BEGIN;
SET LOCAL app.cod_tenant = '2';
SET LOCAL app.cod_empresa = '1';   -- opcional
SELECT * FROM cliente;              -- só clientes do tenant 2
COMMIT;
```

**Regra de ouro:** sempre usar `SET LOCAL` (não `SET`) dentro de
transação, para não vazar contexto entre conexões do pool.

### Backup

**Manual:**

```bash
./db/scripts/backup.sh
```

Gera arquivos `.sql.gz` em `db/backups/`. Retenção: 30 dias.

**Automático:** configurado no `crontab` para rodar às 3h.

**Resetar banco do zero (desenvolvimento):**

```bash
./db/scripts/reset_db.sh
```

> ⚠️ Apaga **todos os dados**. Use apenas em dev.

---

## Documentação adicional

Manuais HTML completos em `docs/infraestrutura/`:

- **[Cloudflare Tunnel e Domínio](docs/infraestrutura/visionflow-api-cloudflare-tunnel-dominio.html)**
  — como expor a API publicamente com HTTPS

- **[PostgreSQL Multi-Tenant](docs/infraestrutura/visionflow-api-postgresql-infraestrutura.html)**
  — instalação, criação das tabelas, RLS, backup

Para abrir no navegador:

```bash
xdg-open docs/infraestrutura/visionflow-api-postgresql-infraestrutura.html
```

---

## Troubleshooting

### Erro: `password authentication failed`

Verifique se a senha no `.env` bate com a do usuário do banco:

```bash
psql -h localhost -U epare -d epare_forca_de_vendas -c "SELECT 1;"
```

### Erro: `relation "X" does not exist`

Migrations não foram aplicadas. Rode:

```bash
flyway -configFiles=./db/flyway.conf migrate
```

### Erro: `Found more than one migration with version X`

Dois arquivos têm a mesma versão. Renomeie um deles para a próxima versão.

### Erro: `Detected resolved migration not applied to database`

Você editou uma migration já aplicada. Crie uma **nova migration**
corrigindo, ou apague o banco e recrie (`reset_db.sh`).

### RLS não filtra

Você provavelmente está conectado como superuser (`postgres`), que
**ignora RLS**. Conecte com o usuário da API (`epare`).

### Porta 8080 ocupada

```bash
# Ver quem está usando
sudo lsof -i :8080

# Ou rodar em outra porta
SERVER_PORT=8081 go run ./cmd/api
```

---

## Próximos passos

- [ ] Migrar handlers de mock para PostgreSQL
- [ ] Implementar middleware de tenant (`SET LOCAL app.cod_tenant`)
- [ ] Adicionar testes de integração
- [ ] Deploy em produção (Cloudflare Tunnel)