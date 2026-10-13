-- ============================================================
-- PARTE 1 v2 — NÚCLEO SaaS MULTI-TENANT + WHITE LABEL
-- Banco: epare_forca_de_vendas
-- PostgreSQL 16
-- ============================================================
-- Estrutura:
--   REVENDEDOR      → software house que revende (white label)
--   TENANT          → cliente do revendedor (quem opera o sistema)
--   EMPRESA         → CNPJ do tenant (1..N por tenant)
--   USUARIO         → login do app
--   USUARIO_EMPRESA → N:N (usuário acessa várias empresas)
--   LOG_AUDITORIA   → rastreio de ações
-- ============================================================

BEGIN;

-- ============================================================
-- 1. REVENDEDOR — software house white label
-- ============================================================
CREATE TABLE revendedor (
    cod_revendedor      SERIAL          PRIMARY KEY,
    slug                VARCHAR(50)     NOT NULL,
    nome                VARCHAR(200)    NOT NULL,
    cnpj                VARCHAR(18),
    email_contato       VARCHAR(200),
    telefone            VARCHAR(20),
    -- White label
    marca_nome          VARCHAR(100),
    marca_logo_url      VARCHAR(500),
    marca_cor_primaria  VARCHAR(7),
    marca_cor_secundaria VARCHAR(7),
    marca_favicon_url   VARCHAR(500),
    -- Domínio
    dominio_customizado VARCHAR(200),
    -- Comercial
    plano               VARCHAR(50)     DEFAULT 'basico',
    percentual_comissao NUMERIC(5,2)    DEFAULT 0,
    limite_tenants      INTEGER         DEFAULT 10,
    -- Status
    ativo               BOOLEAN         DEFAULT TRUE,
    dt_inclusao         TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao        TIMESTAMPTZ     DEFAULT NOW(),
    observacoes         TEXT,
    CONSTRAINT ck_revendedor_slug CHECK (slug ~ '^[a-z0-9][a-z0-9-]{1,48}[a-z0-9]$')
);
CREATE UNIQUE INDEX uk_revendedor_slug ON revendedor (slug);
CREATE UNIQUE INDEX uk_revendedor_cnpj ON revendedor (cnpj) WHERE cnpj IS NOT NULL;
CREATE UNIQUE INDEX uk_revendedor_dominio ON revendedor (dominio_customizado) WHERE dominio_customizado IS NOT NULL;
CREATE INDEX idx_revendedor_ativo ON revendedor (ativo) WHERE ativo = TRUE;

COMMENT ON TABLE  revendedor IS 'Software house que revende o sistema com marca própria (white label)';
COMMENT ON COLUMN revendedor.slug IS 'Identificador amigável (ex: sistema-do-ze)';
COMMENT ON COLUMN revendedor.marca_nome IS 'Nome que o revendedor usa (ex: Sistema do Zé)';
COMMENT ON COLUMN revendedor.dominio_customizado IS 'Domínio próprio do revendedor (ex: app.sistemadoze.com.br)';
COMMENT ON COLUMN revendedor.percentual_comissao IS 'Percentual de comissão que você recebe do revendedor';


-- ============================================================
-- 2. TENANT — cliente do revendedor
-- ============================================================
CREATE TABLE tenant (
    cod_tenant          SERIAL          PRIMARY KEY,
    cod_revendedor      INTEGER         NOT NULL,
    slug                VARCHAR(50),
    nome                VARCHAR(200)    NOT NULL,
    cnpj                VARCHAR(18),
    email_contato       VARCHAR(200),
    telefone            VARCHAR(20),
    plano               VARCHAR(50)     DEFAULT 'basico',
    limite_empresas     INTEGER         DEFAULT 1,
    limite_usuarios     INTEGER         DEFAULT 5,
    ativo               BOOLEAN         DEFAULT TRUE,
    dt_inclusao         TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao        TIMESTAMPTZ     DEFAULT NOW(),
    dt_vencimento       DATE,
    observacoes         TEXT,
    CONSTRAINT fk_tenant_revendedor FOREIGN KEY (cod_revendedor)
        REFERENCES revendedor (cod_revendedor) ON DELETE RESTRICT
);
CREATE UNIQUE INDEX uk_tenant_slug ON tenant (slug) WHERE slug IS NOT NULL;
CREATE INDEX idx_tenant_revendedor ON tenant (cod_revendedor);
CREATE INDEX idx_tenant_ativo ON tenant (ativo) WHERE ativo = TRUE;

COMMENT ON TABLE  tenant IS 'Cliente do revendedor (quem opera o sistema no dia a dia)';
COMMENT ON COLUMN tenant.slug IS 'Opcional. Identificador amigável para URL (ex: distribuidora-joao)';
COMMENT ON COLUMN tenant.cod_revendedor IS 'A qual revendedor este tenant pertence';


-- ============================================================
-- 3. EMPRESA — CNPJ do tenant (1..N por tenant)
-- ============================================================
CREATE TABLE empresa (
    cod_tenant          INTEGER         NOT NULL,
    cod_empresa         INTEGER         NOT NULL,
    slug                VARCHAR(50),
    cnpj                VARCHAR(18)     NOT NULL,
    razao_social        VARCHAR(200)    NOT NULL,
    nome_fantasia       VARCHAR(200),
    inscricao_estadual  VARCHAR(20),
    email               VARCHAR(200),
    telefone            VARCHAR(20),
    cep                 VARCHAR(10),
    logradouro          VARCHAR(200),
    numero              VARCHAR(20),
    complemento         VARCHAR(100),
    bairro              VARCHAR(100),
    cidade              VARCHAR(100),
    estado              CHAR(2),
    ativo               BOOLEAN         DEFAULT TRUE,
    dt_inclusao         TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao        TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_empresa PRIMARY KEY (cod_tenant, cod_empresa),
    CONSTRAINT fk_empresa_tenant FOREIGN KEY (cod_tenant)
        REFERENCES tenant (cod_tenant) ON DELETE CASCADE,
    CONSTRAINT ck_empresa_estado CHECK (estado IS NULL OR LENGTH(estado) = 2)
);
CREATE UNIQUE INDEX uk_empresa_cnpj ON empresa (cod_tenant, cnpj);
CREATE UNIQUE INDEX uk_empresa_slug ON empresa (cod_tenant, slug) WHERE slug IS NOT NULL;
CREATE INDEX idx_empresa_tenant ON empresa (cod_tenant);
CREATE INDEX idx_empresa_ativo ON empresa (cod_tenant, ativo) WHERE ativo = TRUE;

COMMENT ON TABLE  empresa IS 'CNPJ pertencente a um tenant (1 tenant pode ter várias empresas)';
COMMENT ON COLUMN empresa.cod_empresa IS 'Código sequencial dentro do tenant (1, 2, 3...)';
COMMENT ON COLUMN empresa.slug IS 'Opcional. Identificador amigável dentro do tenant';


-- ============================================================
-- 4. USUARIO — login do app
-- ============================================================
CREATE TABLE usuario (
    cod_usuario     SERIAL          PRIMARY KEY,
    cod_tenant      INTEGER         NOT NULL,
    email           VARCHAR(200)    NOT NULL,
    senha_hash      VARCHAR(255)    NOT NULL,
    nome            VARCHAR(200)    NOT NULL,
    telefone        VARCHAR(20),
    cpf             VARCHAR(14),
    tipo            VARCHAR(20)     NOT NULL DEFAULT 'vendedor',
    ativo           BOOLEAN         DEFAULT TRUE,
    ultimo_acesso   TIMESTAMPTZ,
    dt_inclusao     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT fk_usuario_tenant FOREIGN KEY (cod_tenant)
        REFERENCES tenant (cod_tenant) ON DELETE CASCADE,
    CONSTRAINT ck_usuario_tipo CHECK (tipo IN ('admin', 'gerente', 'vendedor', 'supervisor'))
);
CREATE UNIQUE INDEX uk_usuario_email ON usuario (cod_tenant, email);
CREATE INDEX idx_usuario_tenant ON usuario (cod_tenant);
CREATE INDEX idx_usuario_ativo ON usuario (cod_tenant, ativo) WHERE ativo = TRUE;

COMMENT ON TABLE  usuario IS 'Usuário do app (login por email + senha)';
COMMENT ON COLUMN usuario.tipo IS 'admin=administra tenant, gerente=vê tudo, vendedor=opera, supervisor=equipe';


-- ============================================================
-- 5. USUARIO_EMPRESA — N:N usuário x empresa
-- ============================================================
CREATE TABLE usuario_empresa (
    cod_usuario     INTEGER         NOT NULL,
    cod_tenant      INTEGER         NOT NULL,
    cod_empresa     INTEGER         NOT NULL,
    empresa_padrao  BOOLEAN         DEFAULT FALSE,
    dt_inclusao     TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_usuario_empresa PRIMARY KEY (cod_usuario, cod_tenant, cod_empresa),
    CONSTRAINT fk_ue_usuario FOREIGN KEY (cod_usuario)
        REFERENCES usuario (cod_usuario) ON DELETE CASCADE,
    CONSTRAINT fk_ue_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_ue_usuario ON usuario_empresa (cod_usuario);
CREATE INDEX idx_ue_empresa ON usuario_empresa (cod_tenant, cod_empresa);

COMMENT ON TABLE  usuario_empresa IS 'Quais empresas cada usuário pode acessar (N:N)';
COMMENT ON COLUMN usuario_empresa.empresa_padrao IS 'Empresa que abre por padrão ao fazer login';


-- ============================================================
-- 6. LOG_AUDITORIA — rastreio de ações
-- ============================================================
CREATE TABLE log_auditoria (
    cod_log         BIGSERIAL       PRIMARY KEY,
    cod_tenant      INTEGER,
    cod_empresa     INTEGER,
    cod_usuario     INTEGER,
    acao            VARCHAR(50)     NOT NULL,
    tabela          VARCHAR(100),
    registro_id     VARCHAR(100),
    dados_antes     JSONB,
    dados_depois    JSONB,
    ip              INET,
    user_agent      VARCHAR(500),
    dt_evento       TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT fk_log_tenant FOREIGN KEY (cod_tenant)
        REFERENCES tenant (cod_tenant) ON DELETE SET NULL
);
CREATE INDEX idx_log_tenant ON log_auditoria (cod_tenant, dt_evento DESC);
CREATE INDEX idx_log_usuario ON log_auditoria (cod_usuario, dt_evento DESC);
CREATE INDEX idx_log_tabela ON log_auditoria (tabela, registro_id);
CREATE INDEX idx_log_acao ON log_auditoria (acao, dt_evento DESC);

COMMENT ON TABLE  log_auditoria IS 'Log de auditoria (quem fez o quê, quando, em qual registro)';
COMMENT ON COLUMN log_auditoria.dados_antes IS 'Estado do registro antes da alteração (JSON)';
COMMENT ON COLUMN log_auditoria.dados_depois IS 'Estado do registro depois da alteração (JSON)';


-- ============================================================
-- 7. FUNÇÃO E TRIGGERS: atualiza dt_alteracao automaticamente
-- ============================================================
CREATE OR REPLACE FUNCTION fn_atualiza_dt_alteracao()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_alteracao := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_revendedor_dt_alteracao BEFORE UPDATE ON revendedor
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_tenant_dt_alteracao BEFORE UPDATE ON tenant
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_empresa_dt_alteracao BEFORE UPDATE ON empresa
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_usuario_dt_alteracao BEFORE UPDATE ON usuario
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();


-- ============================================================
-- 8. DADOS DE TESTE
-- ============================================================
INSERT INTO revendedor (slug, nome, cnpj, marca_nome, marca_cor_primaria, ativo)
VALUES ('epare', 'Epare Sistemas', '00.000.000/0001-00', 'Epare', '#0066CC', TRUE);

INSERT INTO tenant (cod_revendedor, slug, nome, cnpj, plano, limite_empresas, limite_usuarios, ativo)
VALUES (1, 'epare-demo', 'Epare Demonstração', '00.000.000/0001-00', 'pro', 5, 20, TRUE);

INSERT INTO empresa (cod_tenant, cod_empresa, slug, cnpj, razao_social, nome_fantasia, cidade, estado, ativo)
VALUES (1, 1, 'matriz', '11.111.111/0001-11', 'Empresa Teste LTDA', 'Empresa Teste', 'São Paulo', 'SP', TRUE);

INSERT INTO usuario (cod_tenant, email, senha_hash, nome, tipo, ativo)
VALUES (1, 'admin@epare.com.br', '$2b$12$EXEMPLO_HASH', 'Administrador', 'admin', TRUE);

INSERT INTO usuario_empresa (cod_usuario, cod_tenant, cod_empresa, empresa_padrao)
VALUES (1, 1, 1, TRUE);

COMMIT;

-- ============================================================
-- FIM DA PARTE 1 v2
-- ============================================================
-- Para validar:
--   \dt
--   SELECT * FROM revendedor;
--   SELECT * FROM tenant;
--   SELECT * FROM empresa;
--   SELECT * FROM usuario;
-- ============================================================
