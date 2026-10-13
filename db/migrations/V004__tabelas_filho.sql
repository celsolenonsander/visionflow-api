-- ============================================================
-- PARTE 4 — TABELAS FILHO (relacionamentos N:N + dependentes)
-- Banco: epare_forca_de_vendas
-- PostgreSQL 16
-- ============================================================
-- Padrão:
--   PK:        (cod_tenant, cod_empresa, codigo)
--   FKs:       para empresa + para as tabelas pai (por codigo_erp)
--   Auditoria: dt_inclusao, dt_alteracao
-- ============================================================

BEGIN;

-- ============================================================
-- 1. CLIENTE_ENDERECO_ADICIONAL
-- ============================================================
CREATE TABLE cliente_endereco_adicional (
    cod_tenant                  INTEGER         NOT NULL,
    cod_empresa                 INTEGER         NOT NULL,
    codigo                      SERIAL          NOT NULL,
    codigo_erp_cliente          VARCHAR(20)     NOT NULL,
    nosso_codigo_endereco       VARCHAR(20),
    codigo_erp_endereco         VARCHAR(20)     NOT NULL,
    identificacao_endereco      VARCHAR(50),
    cep                         VARCHAR(10),
    tipo_logradouro             VARCHAR(50),
    logradouro                  VARCHAR(100),
    endereco                    VARCHAR(100),
    numero_endereco             VARCHAR(20),
    complemento_endereco        VARCHAR(100),
    bairro                      VARCHAR(100),
    cidade                      VARCHAR(100),
    estado                      CHAR(2),
    regiao                      VARCHAR(100),
    ponto_referencia            VARCHAR(200),
    restricoes_horarios         VARCHAR(200),
    tipo_endereco               CHAR(1),
    endereco_padrao             BOOLEAN         DEFAULT FALSE,
    dt_inclusao                 TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_cliente_endereco PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_cli_end_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE,
    CONSTRAINT ck_cli_end_tipo CHECK (tipo_endereco IN ('C','E','A') OR tipo_endereco IS NULL)
);
CREATE INDEX idx_cli_end_cliente ON cliente_endereco_adicional (cod_tenant, cod_empresa, codigo_erp_cliente);
COMMENT ON TABLE cliente_endereco_adicional IS 'Endereços adicionais do cliente (entrega, cobrança, NF)';
COMMENT ON COLUMN cliente_endereco_adicional.tipo_endereco IS 'C=Cobrança, E=Entrega, A=Ambos';


-- ============================================================
-- 2. CLIENTE_REPRESENTANTE
-- ============================================================
CREATE TABLE cliente_representante (
    cod_tenant                  INTEGER         NOT NULL,
    cod_empresa                 INTEGER         NOT NULL,
    codigo                      SERIAL          NOT NULL,
    codigo_erp_cliente          VARCHAR(20)     NOT NULL,
    codigo_erp_representante    VARCHAR(20)     NOT NULL,
    cnpj_cpf_representante      VARCHAR(20),
    dt_inclusao                 TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_cliente_representante PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_cli_rep_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_cli_rep_cliente ON cliente_representante (cod_tenant, cod_empresa, codigo_erp_cliente);
CREATE INDEX idx_cli_rep_representante ON cliente_representante (cod_tenant, cod_empresa, codigo_erp_representante);
COMMENT ON TABLE cliente_representante IS 'Vínculo cliente x representante (N:N)';


-- ============================================================
-- 3. CLIENTE_CONTATO
-- ============================================================
CREATE TABLE cliente_contato (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    codigo_erp_cliente              VARCHAR(20)     NOT NULL,
    identificacao_contato           VARCHAR(100),
    nome_apelido                    VARCHAR(100),
    sexo                            VARCHAR(3),
    data_nascimento                 DATE,
    departamento_trabalha           VARCHAR(100),
    cargo_funcao_exerce             VARCHAR(100),
    cpf                             VARCHAR(20),
    telefone                        VARCHAR(20),
    ramal                           VARCHAR(10),
    celular                         VARCHAR(20),
    radio                           VARCHAR(20),
    email                           VARCHAR(100),
    receber_email_pedido_venda      BOOLEAN         DEFAULT TRUE,
    receber_email_nota_fiscal_nfe   BOOLEAN         DEFAULT FALSE,
    receber_email_boleto            BOOLEAN         DEFAULT FALSE,
    receber_email_marketing         BOOLEAN         DEFAULT FALSE,
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_cliente_contato PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_cli_cont_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_cli_cont_cliente ON cliente_contato (cod_tenant, cod_empresa, codigo_erp_cliente);
COMMENT ON TABLE cliente_contato IS 'Contatos do cliente';


-- ============================================================
-- 4. CLIENTE_TABELA_PRECO
-- ============================================================
CREATE TABLE cliente_tabela_preco (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    codigo_erp_cliente              VARCHAR(20)     NOT NULL,
    codigo_erp_tabela_preco         VARCHAR(20)     NOT NULL,
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_cliente_tabela_preco PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_cli_tab_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_cli_tab_cliente ON cliente_tabela_preco (cod_tenant, cod_empresa, codigo_erp_cliente);
CREATE INDEX idx_cli_tab_tabela ON cliente_tabela_preco (cod_tenant, cod_empresa, codigo_erp_tabela_preco);
COMMENT ON TABLE cliente_tabela_preco IS 'Tabelas de preço vinculadas ao cliente (N:N)';


-- ============================================================
-- 5. CLIENTE_CONDICAO_PAGAMENTO
-- ============================================================
CREATE TABLE cliente_condicao_pagamento (
    cod_tenant                          INTEGER         NOT NULL,
    cod_empresa                         INTEGER         NOT NULL,
    codigo                              SERIAL          NOT NULL,
    codigo_erp_cliente                  VARCHAR(20)     NOT NULL,
    codigo_erp_condicao_pagamento       VARCHAR(20)     NOT NULL,
    dt_inclusao                         TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                        TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_cliente_cond_pag PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_cli_cond_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_cli_cond_cliente ON cliente_condicao_pagamento (cod_tenant, cod_empresa, codigo_erp_cliente);
CREATE INDEX idx_cli_cond_cond ON cliente_condicao_pagamento (cod_tenant, cod_empresa, codigo_erp_condicao_pagamento);
COMMENT ON TABLE cliente_condicao_pagamento IS 'Condições de pagamento permitidas ao cliente (N:N)';


-- ============================================================
-- 6. CLIENTE_FORMA_PAGAMENTO
-- ============================================================
CREATE TABLE cliente_forma_pagamento (
    cod_tenant                          INTEGER         NOT NULL,
    cod_empresa                         INTEGER         NOT NULL,
    codigo                              SERIAL          NOT NULL,
    codigo_erp_cliente                  VARCHAR(20)     NOT NULL,
    codigo_erp_forma_pagamento          VARCHAR(20)     NOT NULL,
    dt_inclusao                         TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                        TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_cliente_forma_pag PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_cli_forma_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_cli_forma_cliente ON cliente_forma_pagamento (cod_tenant, cod_empresa, codigo_erp_cliente);
CREATE INDEX idx_cli_forma_forma ON cliente_forma_pagamento (cod_tenant, cod_empresa, codigo_erp_forma_pagamento);
COMMENT ON TABLE cliente_forma_pagamento IS 'Formas de pagamento permitidas ao cliente (N:N)';


-- ============================================================
-- 7. CLIENTE_IMPOSTO
-- ============================================================
CREATE TABLE cliente_imposto (
    cod_tenant                              INTEGER         NOT NULL,
    cod_empresa                             INTEGER         NOT NULL,
    codigo                                  SERIAL          NOT NULL,
    codigo_erp_cliente                      VARCHAR(20)     NOT NULL,
    codigo_erp_classificacao_fiscal         VARCHAR(20),
    percentual_ipi                          NUMERIC(15,4)   DEFAULT 0,
    codigo_cst_origem                       VARCHAR(10),
    dt_inclusao                             TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                            TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_cliente_imposto PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_cli_imp_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_cli_imp_cliente ON cliente_imposto (cod_tenant, cod_empresa, codigo_erp_cliente);
COMMENT ON TABLE cliente_imposto IS 'Configuração fiscal específica do cliente';


-- ============================================================
-- 8. CLIENTE_CAMPO_ADICIONAL
-- ============================================================
CREATE TABLE cliente_campo_adicional (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    codigo_erp_cliente              VARCHAR(20)     NOT NULL,
    field                           VARCHAR(50)     NOT NULL,
    value                           VARCHAR(500),
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_cliente_campo_adic PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_cli_camp_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_cli_camp_cliente ON cliente_campo_adicional (cod_tenant, cod_empresa, codigo_erp_cliente);
COMMENT ON TABLE cliente_campo_adicional IS 'Campos adicionais personalizados do cliente';


-- ============================================================
-- 9. CLIENTE_ROTA_SIMPLES
-- ============================================================
CREATE TABLE cliente_rota_simples (
    cod_tenant                          INTEGER         NOT NULL,
    cod_empresa                         INTEGER         NOT NULL,
    codigo                              SERIAL          NOT NULL,
    codigo_erp_cliente                  VARCHAR(20)     NOT NULL,
    codigo_erp_rota_simples             VARCHAR(20)     NOT NULL,
    descricao_rota_simples              VARCHAR(100),
    sequenciamento_ou_horario           CHAR(1),
    sequencia_horario                   VARCHAR(20),
    dt_inclusao                         TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                        TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_cliente_rota PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_cli_rota_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE,
    CONSTRAINT ck_cli_rota_seq CHECK (sequenciamento_ou_horario IN ('S','H') OR sequenciamento_ou_horario IS NULL)
);
CREATE INDEX idx_cli_rota_cliente ON cliente_rota_simples (cod_tenant, cod_empresa, codigo_erp_cliente);
COMMENT ON TABLE cliente_rota_simples IS 'Rota de visita do cliente (sequência ou horário)';


-- ============================================================
-- 10. ITEM_IMPOSTO
-- ============================================================
CREATE TABLE item_imposto (
    cod_tenant                              INTEGER         NOT NULL,
    cod_empresa                             INTEGER         NOT NULL,
    codigo                                  SERIAL          NOT NULL,
    codigo_erp_item                         VARCHAR(20)     NOT NULL,
    codigo_erp_classificacao_fiscal         VARCHAR(20),
    percentual_ipi                          NUMERIC(15,4)   DEFAULT 0,
    codigo_cst_origem                       VARCHAR(10),
    dt_inclusao                             TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                            TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_item_imposto PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_item_imp_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_item_imp_item ON item_imposto (cod_tenant, cod_empresa, codigo_erp_item);
COMMENT ON TABLE item_imposto IS 'Configuração fiscal específica do item';


-- ============================================================
-- 11. ITEM_UNIDADE_NEGOCIO
-- ============================================================
CREATE TABLE item_unidade_negocio (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    codigo_erp_item                 VARCHAR(20)     NOT NULL,
    codigo_erp_unidade_negocio      VARCHAR(20)     NOT NULL,
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_item_und_neg PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_item_und_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_item_und_item ON item_unidade_negocio (cod_tenant, cod_empresa, codigo_erp_item);
CREATE INDEX idx_item_und_und ON item_unidade_negocio (cod_tenant, cod_empresa, codigo_erp_unidade_negocio);
COMMENT ON TABLE item_unidade_negocio IS 'Unidades de negócio onde o item está disponível (N:N)';


-- ============================================================
-- 12. ITEM_EMBALAGEM_VENDA
-- ============================================================
CREATE TABLE item_embalagem_venda (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    codigo_erp_item                 VARCHAR(20)     NOT NULL,
    codigo_erp_embalagem_venda      VARCHAR(20)     NOT NULL,
    tipo_calculo                    VARCHAR(10),
    fator_conversao                 NUMERIC(15,4),
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_item_emb_venda PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_item_emb_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_item_emb_item ON item_embalagem_venda (cod_tenant, cod_empresa, codigo_erp_item);
COMMENT ON TABLE item_embalagem_venda IS 'Embalagens de venda do item (N:N)';


-- ============================================================
-- 13. ITEM_CAMPO_ADICIONAL
-- ============================================================
CREATE TABLE item_campo_adicional (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    codigo_erp_item                 VARCHAR(20)     NOT NULL,
    field                           VARCHAR(50)     NOT NULL,
    descricao                       VARCHAR(100),
    value                           VARCHAR(500),
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_item_campo_adic PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_item_camp_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_item_camp_item ON item_campo_adicional (cod_tenant, cod_empresa, codigo_erp_item);
COMMENT ON TABLE item_campo_adicional IS 'Campos adicionais personalizados do item';


-- ============================================================
-- 14. REPRESENTANTE_TIPO_VENDA
-- ============================================================
CREATE TABLE representante_tipo_venda (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    codigo_erp_representante        VARCHAR(20)     NOT NULL,
    codigo_erp_tipo_venda           VARCHAR(20)     NOT NULL,
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_rep_tipo_venda PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_rep_tv_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_rep_tv_rep ON representante_tipo_venda (cod_tenant, cod_empresa, codigo_erp_representante);
COMMENT ON TABLE representante_tipo_venda IS 'Tipos de venda que o representante pode usar (N:N)';


-- ============================================================
-- 15. REPRESENTANTE_SUPERVISOR
-- ============================================================
CREATE TABLE representante_supervisor (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    codigo_erp_representante        VARCHAR(20)     NOT NULL,
    codigo_erp_supervisor           VARCHAR(20)     NOT NULL,
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_rep_supervisor PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_rep_sup_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_rep_sup_rep ON representante_supervisor (cod_tenant, cod_empresa, codigo_erp_representante);
COMMENT ON TABLE representante_supervisor IS 'Vínculo representante x supervisor (N:N)';


-- ============================================================
-- 16. TABELA_PRECO_REPRESENTANTE
-- ============================================================
CREATE TABLE tabela_preco_representante (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    codigo_erp_tabela_preco         VARCHAR(20)     NOT NULL,
    codigo_erp_representante        VARCHAR(20)     NOT NULL,
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_tab_preco_rep PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_tab_rep_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_tab_rep_tabela ON tabela_preco_representante (cod_tenant, cod_empresa, codigo_erp_tabela_preco);
COMMENT ON TABLE tabela_preco_representante IS 'Representantes que podem usar cada tabela de preço (N:N)';


-- ============================================================
-- 17. TABELA_PRECO_CONDICAO_PAGAMENTO
-- ============================================================
CREATE TABLE tabela_preco_condicao_pagamento (
    cod_tenant                          INTEGER         NOT NULL,
    cod_empresa                         INTEGER         NOT NULL,
    codigo                              SERIAL          NOT NULL,
    codigo_erp_tabela_preco             VARCHAR(20)     NOT NULL,
    codigo_erp_condicao_pagamento       VARCHAR(20)     NOT NULL,
    dt_inclusao                         TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                        TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_tab_cond_pag PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_tab_cond_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_tab_cond_tabela ON tabela_preco_condicao_pagamento (cod_tenant, cod_empresa, codigo_erp_tabela_preco);
COMMENT ON TABLE tabela_preco_condicao_pagamento IS 'Condições de pagamento permitidas por tabela (N:N)';


-- ============================================================
-- 18. TABELA_PRECO_TIPO_VENDA
-- ============================================================
CREATE TABLE tabela_preco_tipo_venda (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    codigo_erp_tabela_preco         VARCHAR(20)     NOT NULL,
    codigo_erp_tipo_venda           VARCHAR(20)     NOT NULL,
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_tab_tipo_venda PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_tab_tv_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_tab_tv_tabela ON tabela_preco_tipo_venda (cod_tenant, cod_empresa, codigo_erp_tabela_preco);
COMMENT ON TABLE tabela_preco_tipo_venda IS 'Tipos de venda permitidos por tabela (N:N)';


-- ============================================================
-- 19. TABELA_PRECO_CLIENTE
-- ============================================================
CREATE TABLE tabela_preco_cliente (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    codigo_erp_tabela_preco         VARCHAR(20)     NOT NULL,
    codigo_erp_cliente              VARCHAR(20)     NOT NULL,
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_tab_cliente PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_tab_cli_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_tab_cli_tabela ON tabela_preco_cliente (cod_tenant, cod_empresa, codigo_erp_tabela_preco);
COMMENT ON TABLE tabela_preco_cliente IS 'Clientes com acesso exclusivo a tabela (N:N)';


-- ============================================================
-- 20. TABELA_PRECO_GRUPO_CLIENTE
-- ============================================================
CREATE TABLE tabela_preco_grupo_cliente (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    codigo_erp_tabela_preco         VARCHAR(20)     NOT NULL,
    codigo_erp_grupo_cliente        VARCHAR(20)     NOT NULL,
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_tab_grupo_cli PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_tab_gc_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_tab_gc_tabela ON tabela_preco_grupo_cliente (cod_tenant, cod_empresa, codigo_erp_tabela_preco);
COMMENT ON TABLE tabela_preco_grupo_cliente IS 'Grupos de cliente com acesso a tabela (N:N)';


-- ============================================================
-- 21. TABELA_PRECO_UNIDADE_NEGOCIO
-- ============================================================
CREATE TABLE tabela_preco_unidade_negocio (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    codigo_erp_tabela_preco         VARCHAR(20)     NOT NULL,
    codigo_erp_unidade_negocio      VARCHAR(20)     NOT NULL,
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_tab_und_neg PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_tab_un_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_tab_un_tabela ON tabela_preco_unidade_negocio (cod_tenant, cod_empresa, codigo_erp_tabela_preco);
COMMENT ON TABLE tabela_preco_unidade_negocio IS 'Unidades de negócio onde a tabela está disponível (N:N)';


-- ============================================================
-- 22. CONDICAO_PAGAMENTO_FORMA
-- ============================================================
CREATE TABLE condicao_pagamento_forma (
    cod_tenant                          INTEGER         NOT NULL,
    cod_empresa                         INTEGER         NOT NULL,
    codigo                              SERIAL          NOT NULL,
    codigo_erp_condicao_pagamento       VARCHAR(20)     NOT NULL,
    codigo_erp_forma_pagamento          VARCHAR(20)     NOT NULL,
    dt_inclusao                         TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                        TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_cond_forma PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_cond_forma_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_cond_forma_cond ON condicao_pagamento_forma (cod_tenant, cod_empresa, codigo_erp_condicao_pagamento);
COMMENT ON TABLE condicao_pagamento_forma IS 'Formas de pagamento da condição (N:N)';


-- ============================================================
-- 23. CONDICAO_PAGAMENTO_UNIDADE
-- ============================================================
CREATE TABLE condicao_pagamento_unidade (
    cod_tenant                          INTEGER         NOT NULL,
    cod_empresa                         INTEGER         NOT NULL,
    codigo                              SERIAL          NOT NULL,
    codigo_erp_condicao_pagamento       VARCHAR(20)     NOT NULL,
    codigo_erp_unidade_negocio          VARCHAR(20)     NOT NULL,
    dt_inclusao                         TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                        TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_cond_und PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_cond_und_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_cond_und_cond ON condicao_pagamento_unidade (cod_tenant, cod_empresa, codigo_erp_condicao_pagamento);
COMMENT ON TABLE condicao_pagamento_unidade IS 'Unidades de negócio da condição (N:N)';


-- ============================================================
-- 24. CONDICAO_PAGAMENTO_PARCELA
-- ============================================================
CREATE TABLE condicao_pagamento_parcela (
    cod_tenant                          INTEGER         NOT NULL,
    cod_empresa                         INTEGER         NOT NULL,
    codigo                              SERIAL          NOT NULL,
    versao_layout                       VARCHAR(10),
    codigo_erp_condicao_pagamento       VARCHAR(20)     NOT NULL,
    numero_parcela                      INTEGER         NOT NULL,
    quantidade_dias                     INTEGER         NOT NULL,
    percentual_rateio                   NUMERIC(15,4)   DEFAULT 0,
    dt_inclusao                         TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                        TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_cond_parcela PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_cond_parc_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_cond_parc_cond ON condicao_pagamento_parcela (cod_tenant, cod_empresa, codigo_erp_condicao_pagamento);
COMMENT ON TABLE condicao_pagamento_parcela IS 'Parcelas da condição de pagamento (rateio, prazos)';


-- ============================================================
-- 25. TIPO_VENDA_CONDICAO_PAGAMENTO
-- ============================================================
CREATE TABLE tipo_venda_condicao_pagamento (
    cod_tenant                          INTEGER         NOT NULL,
    cod_empresa                         INTEGER         NOT NULL,
    codigo                              SERIAL          NOT NULL,
    codigo_erp_tipo_venda               VARCHAR(20)     NOT NULL,
    codigo_erp_condicao_pagamento       VARCHAR(20)     NOT NULL,
    dt_inclusao                         TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                        TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_tv_cond PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_tv_cond_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_tv_cond_tipo ON tipo_venda_condicao_pagamento (cod_tenant, cod_empresa, codigo_erp_tipo_venda);
COMMENT ON TABLE tipo_venda_condicao_pagamento IS 'Condições permitidas por tipo de venda (N:N)';


-- ============================================================
-- 26. TIPO_VENDA_UNIDADE_NEGOCIO
-- ============================================================
CREATE TABLE tipo_venda_unidade_negocio (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    codigo_erp_tipo_venda           VARCHAR(20)     NOT NULL,
    codigo_erp_unidade_negocio      VARCHAR(20)     NOT NULL,
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_tv_und PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_tv_und_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_tv_und_tipo ON tipo_venda_unidade_negocio (cod_tenant, cod_empresa, codigo_erp_tipo_venda);
COMMENT ON TABLE tipo_venda_unidade_negocio IS 'Unidades onde o tipo de venda está disponível (N:N)';


-- ============================================================
-- 27. FORMA_PAGAMENTO_UNIDADE_NEGOCIO
-- ============================================================
CREATE TABLE forma_pagamento_unidade_negocio (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    codigo_erp_forma_pagamento      VARCHAR(20)     NOT NULL,
    codigo_erp_unidade_negocio      VARCHAR(20)     NOT NULL,
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_fp_und PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_fp_und_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_fp_und_forma ON forma_pagamento_unidade_negocio (cod_tenant, cod_empresa, codigo_erp_forma_pagamento);
COMMENT ON TABLE forma_pagamento_unidade_negocio IS 'Unidades onde a forma está disponível (N:N)';


-- ============================================================
-- 28. EQUIPE_VENDA_CATEGORIA
-- ============================================================
CREATE TABLE equipe_venda_categoria (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    codigo_erp_equipe_venda         VARCHAR(20)     NOT NULL,
    codigo_categoria                VARCHAR(20)     NOT NULL,
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_equipe_cat PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_equipe_cat_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_equipe_cat_equipe ON equipe_venda_categoria (cod_tenant, cod_empresa, codigo_erp_equipe_venda);
COMMENT ON TABLE equipe_venda_categoria IS 'Categorias de cliente vinculadas à equipe (N:N)';


-- ============================================================
-- 29. EQUIPE_VENDA_ITEM
-- ============================================================
CREATE TABLE equipe_venda_item (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    codigo_erp_equipe_venda         VARCHAR(20)     NOT NULL,
    codigo_erp_item                 VARCHAR(20)     NOT NULL,
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_equipe_item PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_equipe_item_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_equipe_item_equipe ON equipe_venda_item (cod_tenant, cod_empresa, codigo_erp_equipe_venda);
COMMENT ON TABLE equipe_venda_item IS 'Itens vinculados à equipe de venda (N:N)';


-- ============================================================
-- 30. PEDIDO_ITEM
-- ============================================================
CREATE TABLE pedido_item (
    cod_tenant                              INTEGER         NOT NULL,
    cod_empresa                             INTEGER         NOT NULL,
    codigo                                  SERIAL          NOT NULL,
    versao_layout                           VARCHAR(10),
    codigo_erp_empresa                      VARCHAR(20),
    codigo_erp_pedido                       VARCHAR(20)     NOT NULL,
    nosso_codigo_item_pedido                VARCHAR(20),
    codigo_erp_item_pedido                  VARCHAR(20)     NOT NULL,
    codigo_erp_produto                      VARCHAR(20)     NOT NULL,
    codigo_erp_tabela_preco                 VARCHAR(20),
    codigo_erp_moeda                        VARCHAR(20),
    codigo_erp_embalagem                    VARCHAR(20),
    embalagem_unidade_medida                VARCHAR(20),
    preco_venda_original_sugerido           NUMERIC(15,4)   DEFAULT 0,
    preco_venda_praticado_digitado          NUMERIC(15,4)   DEFAULT 0,
    quantidade_informada                    NUMERIC(15,4)   DEFAULT 0,
    fator_conversao                         NUMERIC(15,4)   DEFAULT 0,
    embalagem_preco_venda_praticado         NUMERIC(15,4)   DEFAULT 0,
    embalagem_quantidade                    NUMERIC(15,4)   DEFAULT 0,
    valor_desconto_comercial                NUMERIC(15,4)   DEFAULT 0,
    percentual_desconto_comercial           NUMERIC(15,4)   DEFAULT 0,
    valor_acrescimo_comercial               NUMERIC(15,4)   DEFAULT 0,
    percentual_acrescimo_comercial          NUMERIC(15,4)   DEFAULT 0,
    valor_total_produtos_liquido            NUMERIC(15,4),
    data_entrega                            DATE,
    observacao_item                         TEXT,
    situacao_item_pedido                    VARCHAR(2),
    quantidade_faturada                     NUMERIC(15,4)   DEFAULT 0,
    aliquota_icms                           NUMERIC(15,4)   DEFAULT 0,
    valor_icms                              NUMERIC(15,4)   DEFAULT 0,
    aliquota_ipi                            NUMERIC(15,4)   DEFAULT 0,
    valor_ipi                               NUMERIC(15,4)   DEFAULT 0,
    valor_icms_subst                        NUMERIC(15,4)   DEFAULT 0,
    perc_desconto_02                        NUMERIC(15,4)   DEFAULT 0,
    perc_desconto_03                        NUMERIC(15,4)   DEFAULT 0,
    perc_desconto_04                        NUMERIC(15,4)   DEFAULT 0,
    perc_desconto_05                        NUMERIC(15,4)   DEFAULT 0,
    perc_desconto_06                        NUMERIC(15,4)   DEFAULT 0,
    perc_desconto_07                        NUMERIC(15,4)   DEFAULT 0,
    dt_inclusao                             TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                            TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_pedido_item PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_ped_item_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_ped_item_pedido ON pedido_item (cod_tenant, cod_empresa, codigo_erp_pedido);
CREATE INDEX idx_ped_item_produto ON pedido_item (cod_tenant, cod_empresa, codigo_erp_produto);
COMMENT ON TABLE pedido_item IS 'Itens do pedido de venda';


-- ============================================================
-- 31. PEDIDO_HISTORICO
-- ============================================================
CREATE TABLE pedido_historico (
    cod_tenant                          INTEGER         NOT NULL,
    cod_empresa                         INTEGER         NOT NULL,
    codigo                              SERIAL          NOT NULL,
    versao_layout                       VARCHAR(10),
    codigo_erp_unidade_negocio          VARCHAR(20),
    nosso_codigo_pedido                 VARCHAR(20),
    codigo_erp_pedido                   VARCHAR(20)     NOT NULL,
    codigo_erp_historico_pedido         VARCHAR(50)     NOT NULL,
    data_historico                      DATE,
    hora_historico                      TIME,
    tipo_historico                      VARCHAR(2),
    descricao_historico                 VARCHAR(200),
    nro_nota_fiscal                     VARCHAR(20),
    chave_nfe_nfse                      VARCHAR(50),
    dt_inclusao                         TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                        TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_pedido_historico PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_ped_hist_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_ped_hist_pedido ON pedido_historico (cod_tenant, cod_empresa, codigo_erp_pedido);
COMMENT ON TABLE pedido_historico IS 'Histórico do pedido (faturamento, cancelamento, entrega)';
COMMENT ON COLUMN pedido_historico.tipo_historico IS '2=Cancelado, 3=Faturado, 4=Enviado transp., 5=Entregue';


-- ============================================================
-- 32. (Reservado)
-- ============================================================


-- ============================================================
-- 33. (Reservado)
-- ============================================================


-- ============================================================
-- 34. (Reservado)
-- ============================================================


-- ============================================================
-- TRIGGERS
-- ============================================================
CREATE TRIGGER tg_cli_end_dt_alteracao BEFORE UPDATE ON cliente_endereco_adicional
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_cli_rep_dt_alteracao BEFORE UPDATE ON cliente_representante
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_cli_cont_dt_alteracao BEFORE UPDATE ON cliente_contato
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_cli_tab_dt_alteracao BEFORE UPDATE ON cliente_tabela_preco
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_cli_cond_dt_alteracao BEFORE UPDATE ON cliente_condicao_pagamento
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_cli_forma_dt_alteracao BEFORE UPDATE ON cliente_forma_pagamento
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_cli_imp_dt_alteracao BEFORE UPDATE ON cliente_imposto
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_cli_camp_dt_alteracao BEFORE UPDATE ON cliente_campo_adicional
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_cli_rota_dt_alteracao BEFORE UPDATE ON cliente_rota_simples
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_item_imp_dt_alteracao BEFORE UPDATE ON item_imposto
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_item_und_dt_alteracao BEFORE UPDATE ON item_unidade_negocio
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_item_emb_dt_alteracao BEFORE UPDATE ON item_embalagem_venda
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_item_camp_dt_alteracao BEFORE UPDATE ON item_campo_adicional
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_rep_tv_dt_alteracao BEFORE UPDATE ON representante_tipo_venda
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_rep_sup_dt_alteracao BEFORE UPDATE ON representante_supervisor
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_tab_rep_dt_alteracao BEFORE UPDATE ON tabela_preco_representante
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_tab_cond_dt_alteracao BEFORE UPDATE ON tabela_preco_condicao_pagamento
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_tab_tv_dt_alteracao BEFORE UPDATE ON tabela_preco_tipo_venda
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_tab_cli_dt_alteracao BEFORE UPDATE ON tabela_preco_cliente
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_tab_gc_dt_alteracao BEFORE UPDATE ON tabela_preco_grupo_cliente
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_tab_un_dt_alteracao BEFORE UPDATE ON tabela_preco_unidade_negocio
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_cond_forma_dt_alteracao BEFORE UPDATE ON condicao_pagamento_forma
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_cond_und_dt_alteracao BEFORE UPDATE ON condicao_pagamento_unidade
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_cond_parc_dt_alteracao BEFORE UPDATE ON condicao_pagamento_parcela
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_tv_cond_dt_alteracao BEFORE UPDATE ON tipo_venda_condicao_pagamento
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_tv_und_dt_alteracao BEFORE UPDATE ON tipo_venda_unidade_negocio
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_fp_und_dt_alteracao BEFORE UPDATE ON forma_pagamento_unidade_negocio
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_equipe_cat_dt_alteracao BEFORE UPDATE ON equipe_venda_categoria
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_equipe_item_dt_alteracao BEFORE UPDATE ON equipe_venda_item
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_ped_item_dt_alteracao BEFORE UPDATE ON pedido_item
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_ped_hist_dt_alteracao BEFORE UPDATE ON pedido_historico
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();

COMMIT;

-- ============================================================
-- FIM DA PARTE 4
-- ============================================================
-- Total de tabelas filho criadas: 31
-- Validação:
--   SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';
-- ============================================================
