# VisionFlow API

API Go para o sistema **VisionFlow** — plataforma SaaS multi-tenant para
força de vendas, com suporte a **white label** e integração com ERP.

**Estado atual:**
- As 40 operações do OpenAPI têm rotas e handlers registrados; as pendências de
  regra/semântica estão listadas em “Limitações e validação” e no relatório.
- CEP e CNPJ usam serviços externos (ViaCEP e BrasilAPI).
- Auth, catálogo, clientes, agenda, tarefas, Home, shell e notificações já têm
  módulos em `internal/features`; pedidos/orçamentos ainda estão no service
  compartilhado.
- `go test ./...`, `go build ./...` e `go vet ./...` passaram em 2026-10-15.
  Testes de integração com PostgreSQL ainda não foram executados; a migration
  V011 (`pgcrypto`) está pendente no banco de desenvolvimento. O inventário por
  operação está em [`docs/api-operation-inventory.md`](docs/api-operation-inventory.md).

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
No Compose atual, `epare` é superuser e ignora RLS; esse ambiente não comprova
isolamento até a aplicação usar um papel PostgreSQL não privilegiado.

---

## Stack

| Camada | Tecnologia | Versão |
|--------|-----------|--------|
| Backend | Go | 1.25+ |
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
│   └── api/
│       └── main.go                 # Entrypoint da API
├── internal/
│   ├── httpapi/                    # Handlers, rotas, middleware, swagger
│   │   ├── handler.go
│   │   ├── handler_test.go
│   │   ├── middleware.go
│   │   ├── routes.go
│   │   └── swagger.go
│   ├── features/                   # Domínios já migrados
│   │   ├── auth/                   # Login e repository de usuários
│   │   ├── catalogo/               # Consultas read-only dos catálogos
│   │   ├── cliente/                # Clientes, endereços, títulos e CEP/CNPJ
│   │   ├── agenda/                 # Compromissos
│   │   ├── tarefa/                 # Tarefas do usuário
│   │   ├── home/                   # Indicadores
│   │   ├── shell/                  # Empresa e usuário da sessão
│   │   └── notificacao/            # Listagem e contador
│   ├── db/                         # Pool, sessões RLS e helpers pgx
│   ├── logger/                     # Logger estruturado
│   ├── models/                     # Structs de domínio
│   └── service/                    # Fachadas e domínios ainda não migrados
├── db/
│   ├── flyway.conf.example         # Template de config do Flyway
│   ├── README.md                   # Detalhes de banco
│   ├── migrations/                 # Migrations versionadas (V001 → V011)
│   │   ├── V001__nucleo_saas.sql
│   │   ├── V002__cadastros_base.sql
│   │   ├── V003__cadastros_operacionais.sql
│   │   ├── V004__tabelas_filho.sql
│   │   ├── V005__rls.sql
│   │   ├── V006__indices_unicos_seeds.sql
│   │   ├── V007__pedido_situacao_app.sql
│   │   ├── V008__notificacao.sql
│   │   ├── V009__agenda_tarefa.sql
│   │   ├── V010__empresa_regional.sql
│   │   └── V011__pgcrypto_password_validation.sql
│   ├── seeds/
│   │   └── demo_comercial/         # Dados de demonstração
│   └── scripts/                    # Automação
│       ├── reset_db.sh
│       └── backup.sh
├── docs/
│   └── infraestrutura/
│       ├── visionflow-api-cloudflare-tunnel-dominio.html
│       └── visionflow-api-postgresql-infraestrutura.html
├── tools/                          # Flyway (NÃO commitar — ver .gitignore)
├── .env.example
├── .gitignore
├── go.mod
├── go.sum
├── test-api.sh
└── README.md
```

---

## Requisitos

- **Go 1.25+** (versão declarada em `go.mod`)
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
DB_HOST=<HOST_DO_POSTGRES>
DB_PORT=5432
DB_NAME=epare_forca_de_vendas
DB_USER=epare
DB_PASSWORD=<SUA_SENHA>
DB_SSLMODE=disable

PORT=8080
JWT_SECRET=<STRING_ALEATORIA_32_CHARS>
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173
```

`DB_HOST`, `DB_PORT`, `DB_SSLMODE` e as demais configurações são lidas do
ambiente ou do `.env`; não é necessário usar `localhost` em ambientes remotos.

Os tokens de login expiram em 8 horas, conforme o contrato OpenAPI. Embora
`JWT_EXPIRATION` seja carregada na configuração, o handler mantém o prazo fixo
de 8 horas do contrato.

Para gerar uma chave JWT forte:

```bash
openssl rand -base64 32
```

### 2. Configurar o Flyway

O binário do Flyway **não é versionado**. Baixe e coloque em `tools/`:

```bash
mkdir -p tools
cd tools
wget https://download.red-gate.com/maven/release/com/redgate/flyway/flyway-commandline/13.7.0/flyway-commandline-13.7.0-linux-x64.tar.gz
tar -xzf flyway-commandline-13.7.0-linux-x64.tar.gz
cd ..
```

> Alternativa: use um Flyway instalado globalmente (`which flyway`).

Depois, copie o template de configuração:

```bash
cp db/flyway.conf.example db/flyway.conf
# edite db/flyway.conf com a senha do banco
```

### 3. Aplicar migrations

```bash
flyway -configFiles=./db/flyway.conf info
flyway -configFiles=./db/flyway.conf migrate
```

> Se preferir usar o Flyway de `tools/`, ajuste o caminho:
> `./tools/flyway-13.7.0/flyway -configFiles=./db/flyway.conf migrate`

### 4. Rodar a API

```bash
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
- `GET/POST /clientes`
- `GET  /clientes/{id}`
- `PUT/DELETE /clientes/{id}`
- `GET  /clientes/cnpj/{cnpj}`
- `GET  /clientes/{id}/enderecos`
- `POST /clientes/{id}/enderecos`
- `DELETE /clientes/{id}/enderecos/{enderecoId}`
- `GET  /clientes/{id}/contas-receber`
- `GET  /cep/{cep}`
- `GET/POST /pedidos`
- `GET  /pedidos/{id}`
- `DELETE /pedidos/{id}`
- `GET  /orcamentos`, `/orcamentos/{id}`
- `GET  /empresas`, `/condicoes-pagamento`, `/formas-pagamento`
- `GET  /transportadoras`, `/tabelas-preco`, `/produtos`
- `GET/POST /agenda`, `GET/PUT /agenda/{id}`, `PATCH /agenda/{id}/concluir`
- `GET/POST /tarefas`, `GET/PUT /tarefas/{id}`, `PATCH /tarefas/{id}/concluir`
- `GET  /notificacoes`
- `GET  /notificacoes/nao-lidas/count`

### Shell (UI)

- `GET /shell/empresa`
- `GET /shell/notificacoes`

As rotas de negócio usam PostgreSQL com escopo de tenant/empresa via RLS.
O login valida o hash com `pgcrypto`; aplique `V011__pgcrypto_password_validation.sql`
antes de usar a autenticação. O Swagger UI serve uma cópia embutida de
`docs/openapi.yaml`.

### Testes e compilação

```bash
go test ./...
go build ./...
go vet ./...
```

Não há testes de integração com PostgreSQL configurados. A suíte atual cobre
helpers, autenticação/JSON HTTP e chamadas CEP/CNPJ mockadas; operações SQL de
validação de cliente estão cobertas sem banco; operações SQL de leitura e escrita
ainda precisam de testes em banco de teste isolado. Consulte
[`docs/api-operation-inventory.md`](docs/api-operation-inventory.md).

---

## Autenticação

### Login

```json
{
  "email": "usuario@empresa.com.br",
  "senha": "<senha cadastrada>"
}
```

O login consulta `usuario`, `usuario_empresa`, `empresa` e `tenant`, valida a
senha com `crypt` do PostgreSQL e devolve um JWT. Os endpoints protegidos
aceitam:

```http
Authorization: Bearer <token>
```

---

## Banco de dados

### Estrutura

O schema versionado segue o padrão multi-tenant e inclui tabelas operacionais,
notificações, agenda e tarefas. Consulte `docs/schema.sql` e as migrations para
a definição completa; a instalação observada no desenvolvimento estava no
baseline 5 + V006–V010, com V011 pendente.

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

O projeto usa **Flyway** para versionar o schema. O repositório contém migrations
V001–V011. O histórico do banco de desenvolvimento verificado em 2026-10-15
estava no baseline 5 + V006–V010; confirme `info` antes de migrar outro ambiente.

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

   Exemplo: `V007__adiciona_campo_observacao_cliente.sql`

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

### Erro: `file not found: db/flyway.conf`

Você não copiou o template. Rode:

```bash
cp db/flyway.conf.example db/flyway.conf
# edite com a senha
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

Superusers e papéis com `BYPASSRLS` ignoram RLS. No Compose atual, `epare` é
superuser; use um papel de aplicação com privilégios restritos antes de
considerar o isolamento multi-tenant validado.
