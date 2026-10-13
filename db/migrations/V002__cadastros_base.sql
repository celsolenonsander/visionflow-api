-- ============================================================
-- PARTE 2 v2 — CADASTROS BASE (18 tabelas PAI)
-- Banco: epare_forca_de_vendas
-- PostgreSQL 16
-- ============================================================
-- Padrões aplicados:
--   PK:       (cod_tenant, cod_empresa, codigo)
--   UNIQUE:   (cod_tenant, cod_empresa, codigo_erp)
--   FK:       empresa (cod_tenant, cod_empresa)
--   Ativo:    BOOLEAN DEFAULT TRUE (NULL = usa padrão)
--   Auditoria: dt_inclusao, dt_alteracao
--   Sem slug (identificação por codigo/codigo_erp)
-- ============================================================

BEGIN;

-- ============================================================
-- 1. UNIDADE_MEDIDA
-- ============================================================
CREATE TABLE unidade_medida (
    cod_tenant          INTEGER         NOT NULL,
    cod_empresa         INTEGER         NOT NULL,
    codigo              SERIAL          NOT NULL,
    versao_layout       VARCHAR(10),
    codigo_erp          VARCHAR(20)     NOT NULL,
    sigla               VARCHAR(20),
    descricao           VARCHAR(100),
    casas_decimais      INTEGER         DEFAULT 0,
    tipo_leitura        VARCHAR(10),
    ativo               BOOLEAN         DEFAULT TRUE,
    data_bloqueio       DATE,
    motivo_bloqueio     VARCHAR(200),
    dt_inclusao         TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao        TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_unidade_medida PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_unidade_medida_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE UNIQUE INDEX uk_unidade_medida_codigo_erp 
    ON unidade_medida (cod_tenant, cod_empresa, codigo_erp);

COMMENT ON TABLE  unidade_medida IS 'Cadastro de Unidade de Medida';
COMMENT ON COLUMN unidade_medida.codigo_erp IS 'Código da unidade no ERP do cliente';
COMMENT ON COLUMN unidade_medida.ativo IS 'NULL = usa padrão do sistema (equivalente ao ADM do ERP)';


-- ============================================================
-- 2. CATEGORIA_ITEM (Grupos e Subgrupos)
-- ============================================================
CREATE TABLE categoria_item (
    cod_tenant              INTEGER         NOT NULL,
    cod_empresa             INTEGER         NOT NULL,
    codigo                  SERIAL          NOT NULL,
    versao_layout           VARCHAR(10),
    codigo_erp              VARCHAR(20)     NOT NULL,
    descricao               VARCHAR(100),
    codigo_erp_pai          VARCHAR(20),
    ativo                   BOOLEAN         DEFAULT TRUE,
    data_bloqueio           DATE,
    motivo_bloqueio         VARCHAR(200),
    dt_inclusao             TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao            TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_categoria_item PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_categoria_item_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE UNIQUE INDEX uk_categoria_item_codigo_erp 
    ON categoria_item (cod_tenant, cod_empresa, codigo_erp);
CREATE INDEX idx_categoria_item_pai 
    ON categoria_item (cod_tenant, cod_empresa, codigo_erp_pai);

COMMENT ON TABLE  categoria_item IS 'Categorias de item (grupo, subgrupo, etc) — hierárquico';
COMMENT ON COLUMN categoria_item.codigo_erp_pai IS 'Código ERP do pai (para hierarquia)';


-- ============================================================
-- 3. FABRICANTE
-- ============================================================
CREATE TABLE fabricante (
    cod_tenant              INTEGER         NOT NULL,
    cod_empresa             INTEGER         NOT NULL,
    codigo                  SERIAL          NOT NULL,
    versao_layout           VARCHAR(10),
    codigo_erp              VARCHAR(20)     NOT NULL,
    apelido_fantasia        VARCHAR(100),
    ativo                   BOOLEAN         DEFAULT TRUE,
    data_bloqueio           DATE,
    motivo_bloqueio         VARCHAR(200),
    dt_inclusao             TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao            TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_fabricante PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_fabricante_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE UNIQUE INDEX uk_fabricante_codigo_erp 
    ON fabricante (cod_tenant, cod_empresa, codigo_erp);

COMMENT ON TABLE fabricante IS 'Cadastro de Fabricante';


-- ============================================================
-- 4. CLASSIFICACAO_FISCAL
-- ============================================================
CREATE TABLE classificacao_fiscal (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    versao_layout                   VARCHAR(10),
    codigo_erp                      VARCHAR(20)     NOT NULL,
    descricao                       VARCHAR(100),
    classificacao_fiscal            VARCHAR(20),
    percentual_ipi                  NUMERIC(15,4)   DEFAULT 0,
    ativo                           BOOLEAN         DEFAULT TRUE,
    data_bloqueio                   DATE,
    motivo_bloqueio                 VARCHAR(200),
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_classificacao_fiscal PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_classificacao_fiscal_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE UNIQUE INDEX uk_classificacao_fiscal_codigo_erp 
    ON classificacao_fiscal (cod_tenant, cod_empresa, codigo_erp);

COMMENT ON TABLE classificacao_fiscal IS 'Classificação Fiscal (NCM, CST, etc)';


-- ============================================================
-- 5. GRUPO_CLIENTE
-- ============================================================
CREATE TABLE grupo_cliente (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    versao_layout                   VARCHAR(10),
    codigo_erp                      VARCHAR(20)     NOT NULL,
    descricao                       VARCHAR(100),
    codigo_erp_tabela_preco         VARCHAR(20),
    ativo                           BOOLEAN         DEFAULT TRUE,
    data_bloqueio                   DATE,
    motivo_bloqueio                 VARCHAR(200),
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_grupo_cliente PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_grupo_cliente_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE UNIQUE INDEX uk_grupo_cliente_codigo_erp 
    ON grupo_cliente (cod_tenant, cod_empresa, codigo_erp);

COMMENT ON TABLE grupo_cliente IS 'Grupo de Cliente (segmentação comercial)';


-- ============================================================
-- 6. RAMO_ATIVIDADE
-- ============================================================
CREATE TABLE ramo_atividade (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    versao_layout                   VARCHAR(10),
    codigo_erp                      VARCHAR(20)     NOT NULL,
    descricao                       VARCHAR(100),
    ativo                           BOOLEAN         DEFAULT TRUE,
    data_bloqueio                   DATE,
    motivo_bloqueio                 VARCHAR(200),
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_ramo_atividade PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_ramo_atividade_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE UNIQUE INDEX uk_ramo_atividade_codigo_erp 
    ON ramo_atividade (cod_tenant, cod_empresa, codigo_erp);

COMMENT ON TABLE ramo_atividade IS 'Ramo de Atividade / Segmento do cliente';


-- ============================================================
-- 7. ROTA_SIMPLES
-- ============================================================
CREATE TABLE rota_simples (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    versao_layout                   VARCHAR(10),
    codigo_erp                      VARCHAR(20)     NOT NULL,
    descricao                       VARCHAR(100),
    ativo                           BOOLEAN         DEFAULT TRUE,
    data_bloqueio                   DATE,
    motivo_bloqueio                 VARCHAR(200),
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_rota_simples PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_rota_simples_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE UNIQUE INDEX uk_rota_simples_codigo_erp 
    ON rota_simples (cod_tenant, cod_empresa, codigo_erp);

COMMENT ON TABLE rota_simples IS 'Cadastro de Rota Simples (sequência de visitas)';


-- ============================================================
-- 8. RISCO_CLIENTE
-- ============================================================
CREATE TABLE risco_cliente (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    versao_layout                   VARCHAR(10),
    codigo_erp                      VARCHAR(20)     NOT NULL,
    descricao                       VARCHAR(100),
    controle_cliente_receber_dx     INTEGER         DEFAULT 0,
    controle_cliente_receber        VARCHAR(2)      DEFAULT 'N',
    controle_limite_credito         VARCHAR(2)      DEFAULT 'N',
    controle_geral                  VARCHAR(2)      DEFAULT 'N',
    controle_mensagem_padrao        VARCHAR(200),
    cor                             VARCHAR(20),
    ativo                           BOOLEAN         DEFAULT TRUE,
    data_bloqueio                   DATE,
    motivo_bloqueio                 VARCHAR(200),
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_risco_cliente PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_risco_cliente_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE UNIQUE INDEX uk_risco_cliente_codigo_erp 
    ON risco_cliente (cod_tenant, cod_empresa, codigo_erp);

COMMENT ON TABLE risco_cliente IS 'Tipo de Risco Financeiro do Cliente (controle de crédito)';
COMMENT ON COLUMN risco_cliente.controle_cliente_receber IS 'N/D/M/B/1..16 — ver doc do ERP';


-- ============================================================
-- 9. TIPO_VENDA
-- ============================================================
CREATE TABLE tipo_venda (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    versao_layout                   VARCHAR(10),
    codigo_erp                      VARCHAR(20)     NOT NULL,
    descricao                       VARCHAR(100),
    ativo                           BOOLEAN         DEFAULT TRUE,
    data_bloqueio                   DATE,
    motivo_bloqueio                 VARCHAR(200),
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_tipo_venda PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_tipo_venda_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE UNIQUE INDEX uk_tipo_venda_codigo_erp 
    ON tipo_venda (cod_tenant, cod_empresa, codigo_erp);

COMMENT ON TABLE tipo_venda IS 'Tipo de Venda (VENDA, CONSIGNAÇÃO, BONIFICAÇÃO, etc)';


-- ============================================================
-- 10. TIPO_FRETE
-- ============================================================
CREATE TABLE tipo_frete (
    cod_tenant                      INTEGER         NOT NULL,
    cod_empresa                     INTEGER         NOT NULL,
    codigo                          SERIAL          NOT NULL,
    versao_layout                   VARCHAR(10),
    codigo_erp                      VARCHAR(20)     NOT NULL,
    descricao                       VARCHAR(100),
    ativo                           BOOLEAN         DEFAULT TRUE,
    data_bloqueio                   DATE,
    motivo_bloqueio                 VARCHAR(200),
    dt_inclusao                     TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                    TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_tipo_frete PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_tipo_frete_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE UNIQUE INDEX uk_tipo_frete_codigo_erp 
    ON tipo_frete (cod_tenant, cod_empresa, codigo_erp);

COMMENT ON TABLE tipo_frete IS 'Tipo de Frete (CIF, FOB, etc)';


-- ============================================================
-- 11. FORMA_PAGAMENTO
-- ============================================================
CREATE TABLE forma_pagamento (
    cod_tenant                          INTEGER         NOT NULL,
    cod_empresa                         INTEGER         NOT NULL,
    codigo                              SERIAL          NOT NULL,
    versao_layout                       VARCHAR(10),
    codigo_erp                          VARCHAR(20)     NOT NULL,
    descricao                           VARCHAR(100),
    exibir_pedidos_negociados           BOOLEAN         DEFAULT TRUE,
    ativo                               BOOLEAN         DEFAULT TRUE,
    data_bloqueio                       DATE,
    motivo_bloqueio                     VARCHAR(200),
    dt_inclusao                         TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                        TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_forma_pagamento PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_forma_pagamento_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE UNIQUE INDEX uk_forma_pagamento_codigo_erp 
    ON forma_pagamento (cod_tenant, cod_empresa, codigo_erp);

COMMENT ON TABLE forma_pagamento IS 'Forma de Pagamento (DINHEIRO, PIX, BOLETO, etc)';


-- ============================================================
-- 12. CONDICAO_PAGAMENTO
-- ============================================================
CREATE TABLE condicao_pagamento (
    cod_tenant                              INTEGER         NOT NULL,
    cod_empresa                             INTEGER         NOT NULL,
    codigo                                  SERIAL          NOT NULL,
    versao_layout                           VARCHAR(10),
    codigo_erp                              VARCHAR(20)     NOT NULL,
    descricao                               VARCHAR(100),
    quantidade_parcelas                     INTEGER         DEFAULT 1,
    valor_minimo_parcela                    NUMERIC(15,4)   DEFAULT 0,
    calcular_valor_adicional                BOOLEAN         DEFAULT FALSE,
    percentual_valor_adicional              NUMERIC(15,4)   DEFAULT 0,
    prazo_medio                             INTEGER         DEFAULT 0,
    exibir_pedidos_negociados               BOOLEAN         DEFAULT TRUE,
    tipo_calculo                            VARCHAR(2),
    ativo                                   BOOLEAN         DEFAULT TRUE,
    data_bloqueio                           DATE,
    motivo_bloqueio                         VARCHAR(200),
    ordem_exibicao                          INTEGER         DEFAULT 0,
    dt_inclusao                             TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                            TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_condicao_pagamento PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_condicao_pagamento_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE UNIQUE INDEX uk_condicao_pagamento_codigo_erp 
    ON condicao_pagamento (cod_tenant, cod_empresa, codigo_erp);

COMMENT ON TABLE condicao_pagamento IS 'Condição de Pagamento (prazo, parcelas, etc)';


-- ============================================================
-- 13. TRANSPORTADORA
-- ============================================================
CREATE TABLE transportadora (
    cod_tenant                          INTEGER         NOT NULL,
    cod_empresa                         INTEGER         NOT NULL,
    codigo                              SERIAL          NOT NULL,
    versao_layout                       VARCHAR(10),
    codigo_erp                          VARCHAR(20)     NOT NULL,
    tipo_pessoa                         CHAR(1),
    cnpj_cpf                            VARCHAR(20),
    inscricao_estadual_rg               VARCHAR(20),
    nome_razao                          VARCHAR(100),
    nome_fantasia                       VARCHAR(100),
    ativo                               BOOLEAN         DEFAULT TRUE,
    data_bloqueio                       DATE,
    motivo_bloqueio                     VARCHAR(200),
    dt_inclusao                         TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                        TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_transportadora PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_transportadora_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE,
    CONSTRAINT ck_transportadora_tipo CHECK (tipo_pessoa IN ('F','J') OR tipo_pessoa IS NULL)
);
CREATE UNIQUE INDEX uk_transportadora_codigo_erp 
    ON transportadora (cod_tenant, cod_empresa, codigo_erp);
CREATE INDEX idx_transportadora_cnpj 
    ON transportadora (cod_tenant, cod_empresa, cnpj_cpf);

COMMENT ON TABLE transportadora IS 'Cadastro de Transportadora';


-- ============================================================
-- 14. TABELA_PRECO
-- ============================================================
CREATE TABLE tabela_preco (
    cod_tenant                              INTEGER         NOT NULL,
    cod_empresa                             INTEGER         NOT NULL,
    codigo                                  SERIAL          NOT NULL,
    versao_layout                           VARCHAR(10),
    codigo_erp                              VARCHAR(20)     NOT NULL,
    descricao                               VARCHAR(100),
    percentual_maximo_desconto              NUMERIC(15,4)   DEFAULT 100,
    permitir_alterar_preco                  BOOLEAN         DEFAULT TRUE,
    disponibilizar_todos_clientes           BOOLEAN         DEFAULT FALSE,
    ativo                                   BOOLEAN         DEFAULT TRUE,
    data_bloqueio                           DATE,
    motivo_bloqueio                         VARCHAR(200),
    dt_entrega_minima                       DATE,
    dt_entrega_maxima                       DATE,
    obrigar_digitacao_dt_entrega            BOOLEAN         DEFAULT FALSE,
    dt_inclusao                             TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                            TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_tabela_preco PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_tabela_preco_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE UNIQUE INDEX uk_tabela_preco_codigo_erp 
    ON tabela_preco (cod_tenant, cod_empresa, codigo_erp);

COMMENT ON TABLE tabela_preco IS 'Cadastro de Tabela de Preço';


-- ============================================================
-- 15. UNIDADE_NEGOCIO
-- ============================================================
CREATE TABLE unidade_negocio (
    cod_tenant                              INTEGER         NOT NULL,
    cod_empresa                             INTEGER         NOT NULL,
    codigo                                  SERIAL          NOT NULL,
    versao_layout                           VARCHAR(10),
    codigo_erp                              VARCHAR(20)     NOT NULL,
    tipo_pessoa                             CHAR(1),
    cnpj_cpf                                VARCHAR(20),
    inscricao_estadual_rg                   VARCHAR(20),
    nome_razao                              VARCHAR(100),
    nome_fantasia                           VARCHAR(100),
    cep                                     VARCHAR(10),
    tipo_logradouro                         VARCHAR(50),
    logradouro                              VARCHAR(100),
    numero_endereco                         VARCHAR(20),
    complemento                             VARCHAR(100),
    bairro                                  VARCHAR(100),
    cidade                                  VARCHAR(100),
    estado                                  CHAR(2),
    email_responsavel                       VARCHAR(100),
    apelido_estoque                         VARCHAR(100),
    telefone1                               VARCHAR(20),
    telefone2                               VARCHAR(20),
    ativo                                   BOOLEAN         DEFAULT TRUE,
    data_bloqueio                           DATE,
    motivo_bloqueio                         VARCHAR(200),
    dt_inclusao                             TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                            TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_unidade_negocio PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_unidade_negocio_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE,
    CONSTRAINT ck_unidade_negocio_tipo CHECK (tipo_pessoa IN ('F','J') OR tipo_pessoa IS NULL)
);
CREATE UNIQUE INDEX uk_unidade_negocio_codigo_erp 
    ON unidade_negocio (cod_tenant, cod_empresa, codigo_erp);

COMMENT ON TABLE unidade_negocio IS 'Unidade de Negócio (filial) do cliente';


-- ============================================================
-- 16. REPRESENTANTE
-- ============================================================
CREATE TABLE representante (
    cod_tenant                              INTEGER         NOT NULL,
    cod_empresa                             INTEGER         NOT NULL,
    codigo                                  SERIAL          NOT NULL,
    versao_layout                           VARCHAR(10),
    codigo_erp                              VARCHAR(20)     NOT NULL,
    tipo_pessoa                             CHAR(1),
    cnpj_cpf                                VARCHAR(20),
    inscricao_estadual_rg                   VARCHAR(20),
    nome_razao                              VARCHAR(100),
    nome_fantasia                           VARCHAR(100),
    estado                                  CHAR(2),
    email                                   VARCHAR(100),
    telefone_fixo                           VARCHAR(20),
    ramal                                   VARCHAR(10),
    celular                                 VARCHAR(20),
    outros_telefones                        VARCHAR(100),
    ativo                                   BOOLEAN         DEFAULT TRUE,
    data_bloqueio                           DATE,
    motivo_bloqueio                         VARCHAR(200),
    codigo_erp_tabela_preco                 VARCHAR(20),
    codigo_erp_unidade_negocio              VARCHAR(20),
    codigo_erp_equipe_venda                 VARCHAR(20),
    dt_inclusao                             TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                            TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_representante PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_representante_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE,
    CONSTRAINT ck_representante_tipo CHECK (tipo_pessoa IN ('F','J') OR tipo_pessoa IS NULL)
);
CREATE UNIQUE INDEX uk_representante_codigo_erp 
    ON representante (cod_tenant, cod_empresa, codigo_erp);
CREATE INDEX idx_representante_cnpj 
    ON representante (cod_tenant, cod_empresa, cnpj_cpf);

COMMENT ON TABLE representante IS 'Representante / Vendedor';


-- ============================================================
-- 17. EQUIPE_VENDA
-- ============================================================
CREATE TABLE equipe_venda (
    cod_tenant                              INTEGER         NOT NULL,
    cod_empresa                             INTEGER         NOT NULL,
    codigo                                  SERIAL          NOT NULL,
    versao_layout                           VARCHAR(10),
    codigo_erp                              VARCHAR(20)     NOT NULL,
    descricao                               VARCHAR(100),
    ativo                                   BOOLEAN         DEFAULT TRUE,
    data_bloqueio                           DATE,
    motivo_bloqueio                         VARCHAR(200),
    chave                                   VARCHAR(20),
    dt_inclusao                             TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                            TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_equipe_venda PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_equipe_venda_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE UNIQUE INDEX uk_equipe_venda_codigo_erp 
    ON equipe_venda (cod_tenant, cod_empresa, codigo_erp);

COMMENT ON TABLE equipe_venda IS 'Equipe de Venda (agrupamento de representantes)';


-- ============================================================
-- 18. EMBALAGEM_VENDA
-- ============================================================
CREATE TABLE embalagem_venda (
    cod_tenant                              INTEGER         NOT NULL,
    cod_empresa                             INTEGER         NOT NULL,
    codigo                                  SERIAL          NOT NULL,
    versao_layout                           VARCHAR(10),
    codigo_erp                              VARCHAR(20)     NOT NULL,
    descricao                               VARCHAR(100),
    codigo_erp_unidade_medida               VARCHAR(20),
    ativo                                   BOOLEAN         DEFAULT TRUE,
    data_bloqueio                           DATE,
    motivo_bloqueio                         VARCHAR(200),
    dt_inclusao                             TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                            TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_embalagem_venda PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_embalagem_venda_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE UNIQUE INDEX uk_embalagem_venda_codigo_erp 
    ON embalagem_venda (cod_tenant, cod_empresa, codigo_erp);

COMMENT ON TABLE embalagem_venda IS 'Embalagem de Venda (caixa, fardo, etc)';


-- ============================================================
-- TRIGGERS: atualiza dt_alteracao automaticamente
-- ============================================================
CREATE TRIGGER tg_unidade_medida_dt_alteracao BEFORE UPDATE ON unidade_medida
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_categoria_item_dt_alteracao BEFORE UPDATE ON categoria_item
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_fabricante_dt_alteracao BEFORE UPDATE ON fabricante
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_classificacao_fiscal_dt_alteracao BEFORE UPDATE ON classificacao_fiscal
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_grupo_cliente_dt_alteracao BEFORE UPDATE ON grupo_cliente
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_ramo_atividade_dt_alteracao BEFORE UPDATE ON ramo_atividade
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_rota_simples_dt_alteracao BEFORE UPDATE ON rota_simples
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_risco_cliente_dt_alteracao BEFORE UPDATE ON risco_cliente
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_tipo_venda_dt_alteracao BEFORE UPDATE ON tipo_venda
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_tipo_frete_dt_alteracao BEFORE UPDATE ON tipo_frete
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_forma_pagamento_dt_alteracao BEFORE UPDATE ON forma_pagamento
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_condicao_pagamento_dt_alteracao BEFORE UPDATE ON condicao_pagamento
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_transportadora_dt_alteracao BEFORE UPDATE ON transportadora
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_tabela_preco_dt_alteracao BEFORE UPDATE ON tabela_preco
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_unidade_negocio_dt_alteracao BEFORE UPDATE ON unidade_negocio
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_representante_dt_alteracao BEFORE UPDATE ON representante
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_equipe_venda_dt_alteracao BEFORE UPDATE ON equipe_venda
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_embalagem_venda_dt_alteracao BEFORE UPDATE ON embalagem_venda
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();


-- ============================================================
-- DADOS DE TESTE
-- ============================================================
INSERT INTO unidade_medida (cod_tenant, cod_empresa, codigo_erp, sigla, descricao)
VALUES (1, 1, 'UN', 'UN', 'Unidade');

INSERT INTO categoria_item (cod_tenant, cod_empresa, codigo_erp, descricao)
VALUES (1, 1, 'G1', 'Bebidas');

INSERT INTO tipo_venda (cod_tenant, cod_empresa, codigo_erp, descricao)
VALUES (1, 1, '1', 'VENDA');

INSERT INTO forma_pagamento (cod_tenant, cod_empresa, codigo_erp, descricao)
VALUES (1, 1, '1', 'DINHEIRO');

INSERT INTO condicao_pagamento (cod_tenant, cod_empresa, codigo_erp, descricao, quantidade_parcelas)
VALUES (1, 1, '1', 'À VISTA', 1);

INSERT INTO representante (cod_tenant, cod_empresa, codigo_erp, nome_razao, tipo_pessoa)
VALUES (1, 1, '1', 'VENDEDOR TESTE', 'F');

INSERT INTO unidade_negocio (cod_tenant, cod_empresa, codigo_erp, nome_razao, tipo_pessoa)
VALUES (1, 1, '1', 'MATRIZ', 'J');

COMMIT;

-- ============================================================
-- FIM DA PARTE 2 v2
-- ============================================================
-- Validação:
--   \dt
--   SELECT * FROM unidade_medida;
--   SELECT * FROM representante;
-- ============================================================
