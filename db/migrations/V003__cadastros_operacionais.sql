-- ============================================================
-- PARTE 3 — CADASTROS OPERACIONAIS (7 tabelas PAI)
-- Banco: epare_forca_de_vendas
-- PostgreSQL 16
-- ============================================================
-- Tabelas:
--   ITEM                   → Produto / Serviço
--   ITEM_ESTOQUE           → Estoque por unidade de negócio
--   TABELA_PRECO_ITEM      → Preço do item por tabela
--   CLIENTE                → Cadastro de cliente final
--   CLIENTE_CONTA_RECEBER  → Títulos em aberto
--   PEDIDO                 → Pedido de venda / orçamento
--   CUSTOMIZADOR_DADOS     → Relatórios customizados
-- ============================================================

BEGIN;

-- ============================================================
-- 1. ITEM (Produto / Serviço)
-- ============================================================
CREATE TABLE item (
    cod_tenant                              INTEGER         NOT NULL,
    cod_empresa                             INTEGER         NOT NULL,
    codigo                                  SERIAL          NOT NULL,
    versao_layout                           VARCHAR(10),
    codigo_erp                              VARCHAR(20)     NOT NULL,
    codigo_erp_interno                      VARCHAR(20),
    descricao                               VARCHAR(200)    NOT NULL,
    -- Categorização
    codigo_erp_categoria_nivel1             VARCHAR(20),
    descricao_categoria_nivel1              VARCHAR(100),
    codigo_erp_categoria_nivel2             VARCHAR(20),
    descricao_categoria_nivel2              VARCHAR(100),
    codigo_erp_categoria_nivel3             VARCHAR(20),
    descricao_categoria_nivel3              VARCHAR(100),
    -- Unidades e fabricante
    codigo_erp_unidade_medida               VARCHAR(20),
    codigo_erp_fabricante                   VARCHAR(20),
    apelido_fantasia_fabricante             VARCHAR(100),
    codigo_integracao_tabela_preco          VARCHAR(20),
    -- Preços
    preco_venda                             NUMERIC(15,4)   DEFAULT 0,
    preco_promocional                       NUMERIC(15,4)   DEFAULT 0,
    data_inicio_promocao                    DATE,
    data_termino_promocao                   DATE,
    percentual_maximo_desconto              NUMERIC(15,4)   DEFAULT 0,
    -- Estoque
    quantidade_disponivel_estoque           NUMERIC(15,4)   DEFAULT 0,
    permite_venda_sem_estoque               BOOLEAN         DEFAULT FALSE,
    -- Detalhes
    caracteristicas                         TEXT,
    ficha_tecnica                           TEXT,
    acessorios_inclusos                     TEXT,
    termos_garantia                         TEXT,
    -- Dimensões
    peso_bruto                              NUMERIC(15,4)   DEFAULT 0,
    peso_liquido                            NUMERIC(15,4)   DEFAULT 0,
    altura_embalagem                        NUMERIC(15,4)   DEFAULT 0,
    comprimento_embalagem                   NUMERIC(15,4)   DEFAULT 0,
    largura_embalagem                       NUMERIC(15,4)   DEFAULT 0,
    cubagem_embalagem                       NUMERIC(15,4)   DEFAULT 0,
    qtde_volumes_embalagem                  NUMERIC(15,4)   DEFAULT 0,
    -- Fiscal
    codigo_erp_classificacao_fiscal         VARCHAR(20),
    percentual_ipi_classificacao_fiscal     NUMERIC(15,4)   DEFAULT 0,
    -- Configurações
    item_e_um_lancamento                    BOOLEAN         DEFAULT FALSE,
    data_inclusao                           DATE,
    ativo                                   BOOLEAN         DEFAULT TRUE,
    data_bloqueio                           DATE,
    motivo_bloqueio                         VARCHAR(200),
    dt_inclusao                             TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                            TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_item PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_item_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE UNIQUE INDEX uk_item_codigo_erp 
    ON item (cod_tenant, cod_empresa, codigo_erp);
CREATE INDEX idx_item_categoria1 
    ON item (cod_tenant, cod_empresa, codigo_erp_categoria_nivel1);
CREATE INDEX idx_item_categoria2 
    ON item (cod_tenant, cod_empresa, codigo_erp_categoria_nivel2);
CREATE INDEX idx_item_fabricante 
    ON item (cod_tenant, cod_empresa, codigo_erp_fabricante);
CREATE INDEX idx_item_unidade_medida 
    ON item (cod_tenant, cod_empresa, codigo_erp_unidade_medida);
CREATE INDEX idx_item_ativo 
    ON item (cod_tenant, cod_empresa, ativo);

COMMENT ON TABLE  item IS 'Produto ou Serviço';
COMMENT ON COLUMN item.codigo_erp IS 'Código do produto no ERP do cliente';
COMMENT ON COLUMN item.codigo_erp_interno IS 'Código interno do ERP (quando diferente do principal)';
COMMENT ON COLUMN item.item_e_um_lancamento IS 'TRUE = item de lançamento (não é produto físico)';


-- ============================================================
-- 2. ITEM_ESTOQUE (Estoque por unidade de negócio)
-- ============================================================
CREATE TABLE item_estoque (
    cod_tenant                              INTEGER         NOT NULL,
    cod_empresa                             INTEGER         NOT NULL,
    codigo                                  SERIAL          NOT NULL,
    versao_layout                           VARCHAR(10),
    codigo_erp_unidade_negocio              VARCHAR(20)     NOT NULL,
    codigo_erp_item                         VARCHAR(20)     NOT NULL,
    agrupamento_adicional                   VARCHAR(50),
    quantidade                              NUMERIC(15,4)   DEFAULT 0,
    quantidade_est_prevista                 NUMERIC(15,4)   DEFAULT 0,
    data_est_prevista                       DATE,
    quantidade_est_prevista_futura          NUMERIC(15,4)   DEFAULT 0,
    data_est_prevista_futura                DATE,
    quantidade_pedido_venda_erp             NUMERIC(15,4)   DEFAULT 0,
    dt_inclusao                             TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                            TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_item_estoque PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_item_estoque_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_item_estoque_item 
    ON item_estoque (cod_tenant, cod_empresa, codigo_erp_item);
CREATE INDEX idx_item_estoque_unidade 
    ON item_estoque (cod_tenant, cod_empresa, codigo_erp_unidade_negocio);
CREATE UNIQUE INDEX uk_item_estoque_unico 
    ON item_estoque (cod_tenant, cod_empresa, codigo_erp_unidade_negocio, codigo_erp_item);

COMMENT ON TABLE item_estoque IS 'Estoque do item por unidade de negócio (filial)';


-- ============================================================
-- 3. TABELA_PRECO_ITEM (Preço do item por tabela)
-- ============================================================
CREATE TABLE tabela_preco_item (
    cod_tenant                              INTEGER         NOT NULL,
    cod_empresa                             INTEGER         NOT NULL,
    codigo                                  SERIAL          NOT NULL,
    versao_layout                           VARCHAR(10),
    codigo_erp_tabela_preco                 VARCHAR(20)     NOT NULL,
    codigo_erp_item_tabela_preco            VARCHAR(20)     NOT NULL,
    codigo_erp_item                         VARCHAR(20)     NOT NULL,
    quantidade_inicial                      NUMERIC(15,4)   DEFAULT 0,
    quantidade_final                        NUMERIC(15,4)   DEFAULT 999999,
    preco_venda                             NUMERIC(15,4)   DEFAULT 0,
    validade_inicial                        DATE,
    validade_final                          DATE,
    perc_desconto_maximo                    NUMERIC(15,4)   DEFAULT 100,
    preco_venda_promocao                    NUMERIC(15,4)   DEFAULT 0,
    validade_inicial_promocao               DATE,
    validade_final_promocao                 DATE,
    perc_desconto_maximo_promocao           NUMERIC(15,4)   DEFAULT 100,
    codigo_erp_tabela_prazo                 VARCHAR(20),
    dt_inclusao                             TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                            TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_tabela_preco_item PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_tabela_preco_item_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_tab_preco_item_tabela 
    ON tabela_preco_item (cod_tenant, cod_empresa, codigo_erp_tabela_preco);
CREATE INDEX idx_tab_preco_item_item 
    ON tabela_preco_item (cod_tenant, cod_empresa, codigo_erp_item);

COMMENT ON TABLE tabela_preco_item IS 'Preço do item em cada tabela de preço';


-- ============================================================
-- 4. CLIENTE
-- ============================================================
CREATE TABLE cliente (
    cod_tenant                              INTEGER         NOT NULL,
    cod_empresa                             INTEGER         NOT NULL,
    codigo                                  SERIAL          NOT NULL,
    versao_layout                           VARCHAR(10),
    codigo_erp                              VARCHAR(20)     NOT NULL,
    prospect                                BOOLEAN         DEFAULT FALSE,
    tipo_pessoa                             CHAR(1),
    cnpj_cpf                                VARCHAR(20),
    inscricao_estadual_rg                   VARCHAR(20),
    nome_razao_social                       VARCHAR(100)    NOT NULL,
    nome_fantasia                           VARCHAR(100),
    -- Endereço principal
    identificacao_endereco                  VARCHAR(50),
    cep                                     VARCHAR(10),
    tipo_logradouro                         VARCHAR(50),
    logradouro                              VARCHAR(100),
    numero_endereco                         VARCHAR(20),
    complemento                             VARCHAR(100),
    bairro                                  VARCHAR(100),
    cidade                                  VARCHAR(100),
    estado                                  CHAR(2),
    regiao                                  VARCHAR(100),
    ponto_referencia                        VARCHAR(200),
    restricoes_horarios                     VARCHAR(200),
    -- Contatos
    telefone1                               VARCHAR(20),
    telefone2                               VARCHAR(20),
    celular                                 VARCHAR(20),
    fax                                     VARCHAR(20),
    radio                                   VARCHAR(20),
    nome_contato_comprador                  VARCHAR(100),
    email_contato_comprador                 VARCHAR(100),
    telefone_contato_comprador              VARCHAR(20),
    nome_contato_faturamento                VARCHAR(100),
    email_contato_faturamento               VARCHAR(100),
    telefone_contato_faturamento            VARCHAR(20),
    -- Classificações
    codigo_erp_ramo_atividade               VARCHAR(20),
    descricao_ramo_atividade                VARCHAR(100),
    codigo_erp_grupo_cliente                VARCHAR(20),
    descricao_grupo_cliente                 VARCHAR(100),
    -- Vínculos com outros cadastros
    codigo_erp_transportadora               VARCHAR(20),
    cnpj_cpf_transportadora                 VARCHAR(20),
    codigo_erp_tabela_preco                 VARCHAR(20),
    codigo_erp_como_conheceu_empresa        VARCHAR(20),
    descricao_como_conheceu_empresa         VARCHAR(100),
    codigo_erp_condicao_pagamento           VARCHAR(20),
    codigo_erp_forma_pagamento              VARCHAR(20),
    codigo_erp_tipo_venda                   VARCHAR(20),
    codigo_erp_tipo_frete                   VARCHAR(20),
    -- Financeiro
    percentual_desconto_automatico          NUMERIC(15,4)   DEFAULT 0,
    limite_credito_total                    NUMERIC(15,4)   DEFAULT 0,
    quantidade_dias_titulo_vencido          INTEGER         DEFAULT 0,
    analisa_valor_minimo_parcela            BOOLEAN         DEFAULT FALSE,
    tipo_bloqueio_para_venda                VARCHAR(20),
    descricao_aviso_bloqueio_venda          VARCHAR(200),
    -- Auditoria
    data_inclusao                           DATE,
    anotacao_erp                            TEXT,
    ativo                                   BOOLEAN         DEFAULT TRUE,
    data_bloqueio                           DATE,
    motivo_bloqueio                         VARCHAR(200),
    dt_inclusao                             TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                            TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_cliente PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_cliente_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE,
    CONSTRAINT ck_cliente_tipo CHECK (tipo_pessoa IN ('F','J') OR tipo_pessoa IS NULL)
);
CREATE UNIQUE INDEX uk_cliente_codigo_erp 
    ON cliente (cod_tenant, cod_empresa, codigo_erp);
CREATE INDEX idx_cliente_cnpj 
    ON cliente (cod_tenant, cod_empresa, cnpj_cpf);
CREATE INDEX idx_cliente_grupo 
    ON cliente (cod_tenant, cod_empresa, codigo_erp_grupo_cliente);
CREATE INDEX idx_cliente_ramo 
    ON cliente (cod_tenant, cod_empresa, codigo_erp_ramo_atividade);
CREATE INDEX idx_cliente_ativo 
    ON cliente (cod_tenant, cod_empresa, ativo);
CREATE INDEX idx_cliente_nome 
    ON cliente (cod_tenant, cod_empresa, nome_razao_social);

COMMENT ON TABLE  cliente IS 'Cadastro de Cliente (destinatário final)';
COMMENT ON COLUMN cliente.prospect IS 'TRUE = ainda é prospect (não é cliente efetivo)';
COMMENT ON COLUMN cliente.anotacao_erp IS 'Anotações do ERP que o app deve mostrar';


-- ============================================================
-- 5. CLIENTE_CONTA_RECEBER
-- ============================================================
CREATE TABLE cliente_conta_receber (
    cod_tenant                              INTEGER         NOT NULL,
    cod_empresa                             INTEGER         NOT NULL,
    codigo                                  SERIAL          NOT NULL,
    versao_layout                           VARCHAR(10),
    codigo_erp                              VARCHAR(20)     NOT NULL,
    codigo_erp_cliente                      VARCHAR(20)     NOT NULL,
    tipo_pessoa                             CHAR(1),
    cnpj_cpf                                VARCHAR(20),
    codigo_erp_unidade_negocio              VARCHAR(20),
    titulo_serie                            VARCHAR(20),
    titulo_especie_documento                VARCHAR(50),
    titulo_numero_documento                 VARCHAR(50),
    titulo_numero_parcela                   VARCHAR(20),
    data_emissao                            DATE,
    data_vencimento                         DATE,
    valor_total                             NUMERIC(15,4)   DEFAULT 0,
    valor_total_aberto                      NUMERIC(15,4)   DEFAULT 0,
    data_liquidacao                         DATE,
    campo_auxiliar01                        VARCHAR(50),
    campo_auxiliar02                        VARCHAR(50),
    dt_inclusao                             TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                            TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_cliente_conta_receber PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_cliente_cr_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE UNIQUE INDEX uk_cliente_cr_codigo_erp 
    ON cliente_conta_receber (cod_tenant, cod_empresa, codigo_erp);
CREATE INDEX idx_cliente_cr_cliente 
    ON cliente_conta_receber (cod_tenant, cod_empresa, codigo_erp_cliente);
CREATE INDEX idx_cliente_cr_vencimento 
    ON cliente_conta_receber (cod_tenant, cod_empresa, data_vencimento);

COMMENT ON TABLE cliente_conta_receber IS 'Títulos a receber do cliente (em aberto)';


-- ============================================================
-- 6. PEDIDO
-- ============================================================
CREATE TABLE pedido (
    cod_tenant                              INTEGER         NOT NULL,
    cod_empresa                             INTEGER         NOT NULL,
    codigo                                  SERIAL          NOT NULL,
    versao_layout                           VARCHAR(10),
    codigo_erp                              VARCHAR(20)     NOT NULL,
    codigo_erp_empresa                      VARCHAR(20),
    nosso_codigo_pedido                     VARCHAR(20),
    apagar_dados_pedido                     BOOLEAN         DEFAULT FALSE,
    -- Cliente
    nosso_codigo_cliente                    VARCHAR(20),
    codigo_erp_cliente                      VARCHAR(20),
    cliente_tipo_pessoa                     CHAR(1),
    cliente_cnpj_cpf                        VARCHAR(20),
    -- Endereços
    endereco_ident_faturamento              VARCHAR(50),
    endereco_ident_cobranca                 VARCHAR(50),
    endereco_ident_entrega                  VARCHAR(50),
    -- Datas
    data_digitacao                          DATE,
    hora_digitacao                          TIME,
    data_emissao                            DATE,
    e_um_orcamento                          BOOLEAN         DEFAULT FALSE,
    -- Vínculos
    codigo_erp_representante                VARCHAR(20),
    representante_cnpj_cpf                  VARCHAR(20),
    codigo_erp_transportadora               VARCHAR(20),
    transportadora_cnpj_cpf                 VARCHAR(20),
    codigo_erp_redespacho                   VARCHAR(20),
    redespacho_cnpj_cpf                     VARCHAR(20),
    comprador_nome_responsavel              VARCHAR(100),
    codigo_erp_condicao_pagamento           VARCHAR(20),
    codigo_erp_forma_pagamento              VARCHAR(20),
    codigo_erp_tipo_frete                   VARCHAR(20),
    codigo_erp_tipo_venda                   VARCHAR(20),
    -- Valores
    valor_frete                             NUMERIC(15,4)   DEFAULT 0,
    valor_desconto_capa                     NUMERIC(15,4)   DEFAULT 0,
    -- Informações
    nro_pedido_cliente                      VARCHAR(50),
    observacoes_pedido                      TEXT,
    observacoes_nota_fiscal                 TEXT,
    situacao_pedido                         VARCHAR(2),
    situacao_bloqueio                       VARCHAR(2),
    motivo_cancelamento                     VARCHAR(200),
    -- Auditoria
    dt_inclusao                             TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                            TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_pedido PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_pedido_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE,
    CONSTRAINT ck_pedido_cliente_tipo CHECK (cliente_tipo_pessoa IN ('F','J') OR cliente_tipo_pessoa IS NULL)
);
CREATE UNIQUE INDEX uk_pedido_codigo_erp 
    ON pedido (cod_tenant, cod_empresa, codigo_erp);
CREATE INDEX idx_pedido_cliente 
    ON pedido (cod_tenant, cod_empresa, codigo_erp_cliente);
CREATE INDEX idx_pedido_representante 
    ON pedido (cod_tenant, cod_empresa, codigo_erp_representante);
CREATE INDEX idx_pedido_data_emissao 
    ON pedido (cod_tenant, cod_empresa, data_emissao);
CREATE INDEX idx_pedido_situacao 
    ON pedido (cod_tenant, cod_empresa, situacao_pedido);

COMMENT ON TABLE  pedido IS 'Pedido de Venda ou Orçamento';
COMMENT ON COLUMN pedido.situacao_pedido IS '1=Aberto, 2=Cancelado, 3=Faturado Total, 4=Expedido, 5=Entregue, 7=Faturado Parcial/Encerrado, 8=Faturado Parcial/Aberto, 11=Orçamento Revisado, 12=Orçamento Aprovado';
COMMENT ON COLUMN pedido.situacao_bloqueio IS '10..24 — código do bloqueio (ver doc do ERP)';


-- ============================================================
-- 7. CUSTOMIZADOR_DADOS
-- ============================================================
CREATE TABLE customizador_dados (
    cod_tenant                              INTEGER         NOT NULL,
    cod_empresa                             INTEGER         NOT NULL,
    codigo                                  SERIAL          NOT NULL,
    versao_layout                           VARCHAR(10),
    nosso_codigo_customizador               VARCHAR(20),
    codigo_erp_representante                VARCHAR(20),
    codigo_erp_identificacao_dados          VARCHAR(50),
    descricao_periodo_dados                 VARCHAR(100),
    titulo_adicional_dados                  VARCHAR(200),
    dados_html                              TEXT,
    dt_inclusao                             TIMESTAMPTZ     DEFAULT NOW(),
    dt_alteracao                            TIMESTAMPTZ     DEFAULT NOW(),
    CONSTRAINT pk_customizador_dados PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_customizador_dados_empresa FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES empresa (cod_tenant, cod_empresa) ON DELETE CASCADE
);
CREATE INDEX idx_customizador_representante 
    ON customizador_dados (cod_tenant, cod_empresa, codigo_erp_representante);

COMMENT ON TABLE customizador_dados IS 'Relatórios/dados customizados exibidos no app';


-- ============================================================
-- TRIGGERS: atualiza dt_alteracao automaticamente
-- ============================================================
CREATE TRIGGER tg_item_dt_alteracao BEFORE UPDATE ON item
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_item_estoque_dt_alteracao BEFORE UPDATE ON item_estoque
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_tabela_preco_item_dt_alteracao BEFORE UPDATE ON tabela_preco_item
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_cliente_dt_alteracao BEFORE UPDATE ON cliente
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_cliente_conta_receber_dt_alteracao BEFORE UPDATE ON cliente_conta_receber
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_pedido_dt_alteracao BEFORE UPDATE ON pedido
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();
CREATE TRIGGER tg_customizador_dados_dt_alteracao BEFORE UPDATE ON customizador_dados
    FOR EACH ROW EXECUTE FUNCTION fn_atualiza_dt_alteracao();


-- ============================================================
-- DADOS DE TESTE
-- ============================================================
INSERT INTO item (cod_tenant, cod_empresa, codigo_erp, descricao, codigo_erp_unidade_medida, preco_venda)
VALUES (1, 1, '001', 'PRODUTO TESTE 001', 'UN', 100.00);

INSERT INTO item_estoque (cod_tenant, cod_empresa, codigo_erp_unidade_negocio, codigo_erp_item, quantidade)
VALUES (1, 1, '1', '001', 50);

INSERT INTO tabela_preco_item (cod_tenant, cod_empresa, codigo_erp_tabela_preco, codigo_erp_item_tabela_preco, codigo_erp_item, preco_venda)
VALUES (1, 1, '1', '1-001', '001', 100.00);

INSERT INTO cliente (cod_tenant, cod_empresa, codigo_erp, tipo_pessoa, cnpj_cpf, nome_razao_social, cidade, estado)
VALUES (1, 1, '000001', 'J', '22.222.222/0001-22', 'CLIENTE TESTE LTDA', 'São Paulo', 'SP');

INSERT INTO cliente_conta_receber (cod_tenant, cod_empresa, codigo_erp, codigo_erp_cliente, valor_total, valor_total_aberto, data_vencimento)
VALUES (1, 1, 'TIT001', '000001', 500.00, 500.00, '2026-12-31');

INSERT INTO pedido (cod_tenant, cod_empresa, codigo_erp, codigo_erp_cliente, cliente_tipo_pessoa, cliente_cnpj_cpf,
                    data_emissao, e_um_orcamento, situacao_pedido)
VALUES (1, 1, '1001', '000001', 'J', '22.222.222/0001-22', CURRENT_DATE, FALSE, '1');

COMMIT;

-- ============================================================
-- FIM DA PARTE 3
-- ============================================================
-- Validação:
--   \dt
--   SELECT codigo_erp, descricao, preco_venda FROM item;
--   SELECT codigo_erp, nome_razao_social, cidade, estado FROM cliente;
--   SELECT codigo_erp, situacao_pedido FROM pedido;
-- ============================================================
