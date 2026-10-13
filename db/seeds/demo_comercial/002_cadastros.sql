-- ============================================================
-- SEED — Demo Comercial — Cadastros Base
-- ============================================================
-- Popula: unidades, categorias, fabricantes, classificação fiscal,
--         tipos, formas, condições, transportadoras, tabelas de preço,
--         unidades de negócio, equipes, embalagens, ramos, grupos,
--         riscos, rotas.
-- Idempotente: usa WHERE NOT EXISTS
-- ============================================================

BEGIN;

DO $$
DECLARE
    v_tenant INTEGER;
    v_emp    INTEGER := 1;  -- empresa matriz
BEGIN
    -- Pega o tenant da Distribuidora São João
    SELECT cod_tenant INTO v_tenant
    FROM tenant WHERE slug = 'distribuidora-sao-joao';

    IF v_tenant IS NULL THEN
        RAISE EXCEPTION 'Tenant "distribuidora-sao-joao" não encontrado. Rode 001_base.sql primeiro.';
    END IF;

    -- ⚠️ IMPORTANTE: Define contexto para RLS
    -- Sem isso, os INSERTs vão falhar com:
    -- "new row violates row-level security policy"
    PERFORM set_config('app.cod_tenant', v_tenant::TEXT, true);
    PERFORM set_config('app.cod_empresa', v_emp::TEXT, true);

    RAISE NOTICE 'Populando cadastros para tenant % / empresa %', v_tenant, v_emp;

    -- ========================================================
    -- 1. UNIDADES DE MEDIDA
    -- ========================================================
    INSERT INTO unidade_medida (cod_tenant, cod_empresa, codigo_erp, sigla, descricao, casas_decimais, ativo)
    SELECT v_tenant, v_emp, x.codigo_erp, x.sigla, x.descricao, x.casas, TRUE
    FROM (VALUES
        ('UN',  'UN', 'Unidade',          0),
        ('CX',  'CX', 'Caixa',            0),
        ('FD',  'FD', 'Fardo',            0),
        ('PACK','PC', 'Pack',             0),
        ('L',   'L',  'Litro',            3),
        ('ML',  'ML', 'Mililitro',        0),
        ('KG',  'KG', 'Quilograma',       3),
        ('G',   'G',  'Grama',            0)
    ) AS x(codigo_erp, sigla, descricao, casas)
    WHERE NOT EXISTS (
        SELECT 1 FROM unidade_medida
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = x.codigo_erp
    );

    -- ========================================================
    -- 2. CATEGORIAS DE ITEM
    -- ========================================================
    -- Nível 1: grupos principais (codigo_erp começa com "G")
    -- Nível 2: subgrupos (codigo_erp começa com "S")
    -- ========================================================
    INSERT INTO categoria_item (cod_tenant, cod_empresa, codigo_erp, descricao, codigo_erp_pai, ativo)
    SELECT v_tenant, v_emp, x.codigo_erp, x.descricao, x.pai, TRUE
    FROM (VALUES
        ('G1', 'Bebidas',          NULL::VARCHAR),
        ('G2', 'Alimentos',        NULL),
        ('G3', 'Limpeza',          NULL),
        ('G4', 'Higiene',          NULL),
        ('S1', 'Cervejas',         'G1'),
        ('S2', 'Refrigerantes',    'G1'),
        ('S3', 'Sucos e Águas',    'G1'),
        ('S4', 'Destilados',       'G1'),
        ('S5', 'Petiscos',         'G2'),
        ('S6', 'Enlatados',        'G2')
    ) AS x(codigo_erp, descricao, pai)
    WHERE NOT EXISTS (
        SELECT 1 FROM categoria_item
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = x.codigo_erp
    );

    -- ========================================================
    -- 3. FABRICANTES
    -- ========================================================
    INSERT INTO fabricante (cod_tenant, cod_empresa, codigo_erp, apelido_fantasia, ativo)
    SELECT v_tenant, v_emp, x.codigo_erp, x.apelido, TRUE
    FROM (VALUES
        ('F001', 'Coca-Cola'),
        ('F002', 'Ambev'),
        ('F003', 'Heineken'),
        ('F004', 'PepsiCo'),
        ('F005', 'Unilever'),
        ('F006', 'Parmalat')
    ) AS x(codigo_erp, apelido)
    WHERE NOT EXISTS (
        SELECT 1 FROM fabricante
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = x.codigo_erp
    );

    -- ========================================================
    -- 4. CLASSIFICAÇÃO FISCAL (NCM + IPI)
    -- ========================================================
    INSERT INTO classificacao_fiscal (
        cod_tenant, cod_empresa, codigo_erp, descricao,
        classificacao_fiscal, percentual_ipi, ativo
    )
    SELECT v_tenant, v_emp, x.codigo_erp, x.descricao, x.ncm, x.ipi, TRUE
    FROM (VALUES
        ('CF01', 'Cervejas de malte',       '2203.00.00', 0.00),
        ('CF02', 'Refrigerantes',           '2202.10.00', 0.00),
        ('CF03', 'Águas minerais',          '2201.10.00', 0.00),
        ('CF04', 'Sucos de frutas',         '2009.11.00', 0.00),
        ('CF05', 'Batatas fritas (snacks)', '2005.20.00', 0.00),
        ('CF06', 'Amendoim salgado',        '2008.11.00', 0.00),
        ('CF07', 'Vodka',                   '2208.60.00', 0.00),
        ('CF08', 'Whisky',                  '2208.30.00', 0.00)
    ) AS x(codigo_erp, descricao, ncm, ipi)
    WHERE NOT EXISTS (
        SELECT 1 FROM classificacao_fiscal
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = x.codigo_erp
    );

    -- ========================================================
    -- 5. TIPOS DE VENDA
    -- ========================================================
    INSERT INTO tipo_venda (cod_tenant, cod_empresa, codigo_erp, descricao, ativo)
    SELECT v_tenant, v_emp, x.codigo_erp, x.descricao, TRUE
    FROM (VALUES
        ('1', 'VENDA'),
        ('2', 'BONIFICAÇÃO'),
        ('3', 'TROCA'),
        ('4', 'CONSIGNAÇÃO')
    ) AS x(codigo_erp, descricao)
    WHERE NOT EXISTS (
        SELECT 1 FROM tipo_venda
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = x.codigo_erp
    );

    -- ========================================================
    -- 6. TIPOS DE FRETE
    -- ========================================================
    INSERT INTO tipo_frete (cod_tenant, cod_empresa, codigo_erp, descricao, ativo)
    SELECT v_tenant, v_emp, x.codigo_erp, x.descricao, TRUE
    FROM (VALUES
        ('0', 'Contratação do Frete por conta do Remetente (CIF)'),
        ('1', 'Contratação do Frete por conta do Destinatário (FOB)'),
        ('2', 'Contratação do Frete por conta de Terceiros'),
        ('9', 'Sem Ocorrência de Transporte')
    ) AS x(codigo_erp, descricao)
    WHERE NOT EXISTS (
        SELECT 1 FROM tipo_frete
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = x.codigo_erp
    );

    -- ========================================================
    -- 7. FORMAS DE PAGAMENTO
    -- ========================================================
    INSERT INTO forma_pagamento (
        cod_tenant, cod_empresa, codigo_erp, descricao,
        exibir_pedidos_negociados, ativo
    )
    SELECT v_tenant, v_emp, x.codigo_erp, x.descricao, TRUE, TRUE
    FROM (VALUES
        ('01', 'Dinheiro'),
        ('03', 'Cartão de Crédito'),
        ('04', 'Cartão de Débito'),
        ('15', 'Boleto Bancário'),
        ('17', 'PIX')
    ) AS x(codigo_erp, descricao)
    WHERE NOT EXISTS (
        SELECT 1 FROM forma_pagamento
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = x.codigo_erp
    );

    -- ========================================================
    -- 8. CONDIÇÕES DE PAGAMENTO
    -- ========================================================
    INSERT INTO condicao_pagamento (
        cod_tenant, cod_empresa, codigo_erp, descricao,
        quantidade_parcelas, valor_minimo_parcela,
        calcular_valor_adicional, percentual_valor_adicional,
        prazo_medio, exibir_pedidos_negociados, tipo_calculo,
        ativo, ordem_exibicao
    )
    SELECT v_tenant, v_emp, x.codigo_erp, x.descricao,
           x.parcelas, 0, FALSE, 0,
           x.prazo_medio, TRUE, '9',
           TRUE, x.ordem
    FROM (VALUES
        ('01', 'À Vista',            1,  0,  1),
        ('02', '30 dias',            1, 30,  2),
        ('03', '30/60 dias',         2, 45,  3),
        ('04', '30/60/90 dias',      3, 60,  4),
        ('05', '15/30/45/60 dias',   4, 37,  5)
    ) AS x(codigo_erp, descricao, parcelas, prazo_medio, ordem)
    WHERE NOT EXISTS (
        SELECT 1 FROM condicao_pagamento
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = x.codigo_erp
    );

    -- ========================================================
    -- 9. PARCELAS DAS CONDIÇÕES
    -- ========================================================
    -- Vamos popular as parcelas das condições 03, 04, 05
    -- (as condições 01 e 02 são à vista / 1 parcela)

    -- 30/60
    INSERT INTO condicao_pagamento_parcela (
        cod_tenant, cod_empresa, codigo_erp_condicao_pagamento,
        numero_parcela, quantidade_dias, percentual_rateio
    )
    SELECT v_tenant, v_emp, '03', 1, 30, 50.00
    WHERE NOT EXISTS (
        SELECT 1 FROM condicao_pagamento_parcela
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp
          AND codigo_erp_condicao_pagamento = '03' AND numero_parcela = 1
    );

    INSERT INTO condicao_pagamento_parcela (
        cod_tenant, cod_empresa, codigo_erp_condicao_pagamento,
        numero_parcela, quantidade_dias, percentual_rateio
    )
    SELECT v_tenant, v_emp, '03', 2, 60, 50.00
    WHERE NOT EXISTS (
        SELECT 1 FROM condicao_pagamento_parcela
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp
          AND codigo_erp_condicao_pagamento = '03' AND numero_parcela = 2
    );

    -- 30/60/90
    INSERT INTO condicao_pagamento_parcela (
        cod_tenant, cod_empresa, codigo_erp_condicao_pagamento,
        numero_parcela, quantidade_dias, percentual_rateio
    )
    SELECT v_tenant, v_emp, '04', 1, 30, 33.33
    WHERE NOT EXISTS (
        SELECT 1 FROM condicao_pagamento_parcela
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp
          AND codigo_erp_condicao_pagamento = '04' AND numero_parcela = 1
    );
    INSERT INTO condicao_pagamento_parcela (
        cod_tenant, cod_empresa, codigo_erp_condicao_pagamento,
        numero_parcela, quantidade_dias, percentual_rateio
    )
    SELECT v_tenant, v_emp, '04', 2, 60, 33.33
    WHERE NOT EXISTS (
        SELECT 1 FROM condicao_pagamento_parcela
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp
          AND codigo_erp_condicao_pagamento = '04' AND numero_parcela = 2
    );
    INSERT INTO condicao_pagamento_parcela (
        cod_tenant, cod_empresa, codigo_erp_condicao_pagamento,
        numero_parcela, quantidade_dias, percentual_rateio
    )
    SELECT v_tenant, v_emp, '04', 3, 90, 33.34
    WHERE NOT EXISTS (
        SELECT 1 FROM condicao_pagamento_parcela
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp
          AND codigo_erp_condicao_pagamento = '04' AND numero_parcela = 3
    );

    -- 15/30/45/60
    INSERT INTO condicao_pagamento_parcela (
        cod_tenant, cod_empresa, codigo_erp_condicao_pagamento,
        numero_parcela, quantidade_dias, percentual_rateio
    )
    SELECT v_tenant, v_emp, '05', x.num, x.dias, 25.00
    FROM (VALUES (1, 15), (2, 30), (3, 45), (4, 60)) AS x(num, dias)
    WHERE NOT EXISTS (
        SELECT 1 FROM condicao_pagamento_parcela
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp
          AND codigo_erp_condicao_pagamento = '05' AND numero_parcela = x.num
    );

    -- ========================================================
    -- 10. TRANSPORTADORAS
    -- ========================================================
    INSERT INTO transportadora (
        cod_tenant, cod_empresa, codigo_erp, tipo_pessoa, cnpj_cpf,
        inscricao_estadual_rg, nome_razao, nome_fantasia, ativo
    )
    SELECT v_tenant, v_emp, x.codigo_erp, x.tipo, x.cnpj, x.ie, x.razao, x.fantasia, TRUE
    FROM (VALUES
        ('T001', 'J', '45.678.901/0001-45', '456.789.012.345', 'Transportadora São João LTDA', 'São João Log'),
        ('T002', 'J', '56.789.012/0001-56', '567.890.123.456', 'Jadlog Logística S.A.', 'Jadlog'),
        ('T003', 'J', '67.890.123/0001-67', '678.901.234.567', 'Braspress Transportes Urgentes LTDA', 'Braspress')
    ) AS x(codigo_erp, tipo, cnpj, ie, razao, fantasia)
    WHERE NOT EXISTS (
        SELECT 1 FROM transportadora
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = x.codigo_erp
    );

    -- ========================================================
    -- 11. TABELAS DE PREÇO
    -- ========================================================
    INSERT INTO tabela_preco (
        cod_tenant, cod_empresa, codigo_erp, descricao,
        percentual_maximo_desconto, permitir_alterar_preco,
        disponibilizar_todos_clientes, ativo,
        obrigar_digitacao_dt_entrega
    )
    SELECT v_tenant, v_emp, x.codigo_erp, x.descricao,
           x.desconto, x.alterar_preco, x.todos, TRUE, FALSE
    FROM (VALUES
        ('1', 'Varejo',          5.00,  FALSE, TRUE),
        ('2', 'Atacado',        10.00,  FALSE, FALSE),
        ('3', 'Promocional',     0.00,  TRUE,  FALSE)
    ) AS x(codigo_erp, descricao, desconto, alterar_preco, todos)
    WHERE NOT EXISTS (
        SELECT 1 FROM tabela_preco
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = x.codigo_erp
    );

    -- ========================================================
    -- 12. UNIDADES DE NEGÓCIO (filiais)
    -- ========================================================
    INSERT INTO unidade_negocio (
        cod_tenant, cod_empresa, codigo_erp, tipo_pessoa, cnpj_cpf,
        nome_razao, nome_fantasia, cidade, estado, ativo
    )
    SELECT v_tenant, v_emp, x.codigo_erp, 'J', x.cnpj, x.razao, x.fantasia, x.cidade, 'SP', TRUE
    FROM (VALUES
        ('1', '23.456.789/0001-10', 'Distribuidora São João LTDA - Matriz', 'São João - Matriz', 'São Paulo'),
        ('2', '23.456.789/0002-00', 'Distribuidora São João LTDA - Filial Campinas', 'São João - Campinas', 'Campinas')
    ) AS x(codigo_erp, cnpj, razao, fantasia, cidade)
    WHERE NOT EXISTS (
        SELECT 1 FROM unidade_negocio
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = x.codigo_erp
    );

    -- ========================================================
    -- 13. EQUIPES DE VENDA
    -- ========================================================
    INSERT INTO equipe_venda (cod_tenant, cod_empresa, codigo_erp, descricao, ativo, chave)
    SELECT v_tenant, v_emp, x.codigo_erp, x.descricao, TRUE, x.codigo_erp
    FROM (VALUES
        ('EQ1', 'Equipe São Paulo'),
        ('EQ2', 'Equipe Interior')
    ) AS x(codigo_erp, descricao)
    WHERE NOT EXISTS (
        SELECT 1 FROM equipe_venda
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = x.codigo_erp
    );

    -- ========================================================
    -- 14. EMBALAGENS DE VENDA
    -- ========================================================
    INSERT INTO embalagem_venda (
        cod_tenant, cod_empresa, codigo_erp, descricao,
        codigo_erp_unidade_medida, ativo
    )
    SELECT v_tenant, v_emp, x.codigo_erp, x.descricao, x.un, TRUE
    FROM (VALUES
        ('E001', 'Unidade',      'UN'),
        ('E002', 'Fardo 12',     'FD'),
        ('E003', 'Caixa 24',     'CX'),
        ('E004', 'Pack 6',       'PACK'),
        ('E005', 'Galão 5L',     'UN')
    ) AS x(codigo_erp, descricao, un)
    WHERE NOT EXISTS (
        SELECT 1 FROM embalagem_venda
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = x.codigo_erp
    );

    -- ========================================================
    -- 15. RAMOS DE ATIVIDADE
    -- ========================================================
    INSERT INTO ramo_atividade (cod_tenant, cod_empresa, codigo_erp, descricao, ativo)
    SELECT v_tenant, v_emp, x.codigo_erp, x.descricao, TRUE
    FROM (VALUES
        ('R01', 'Bar'),
        ('R02', 'Restaurante'),
        ('R03', 'Supermercado'),
        ('R04', 'Padaria'),
        ('R05', 'Loja de Conveniência'),
        ('R06', 'Distribuidora'),
        ('R07', 'Hotel / Pousada'),
        ('R08', 'Eventos / Buffet')
    ) AS x(codigo_erp, descricao)
    WHERE NOT EXISTS (
        SELECT 1 FROM ramo_atividade
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = x.codigo_erp
    );

    -- ========================================================
    -- 16. GRUPOS DE CLIENTE
    -- ========================================================
    INSERT INTO grupo_cliente (cod_tenant, cod_empresa, codigo_erp, descricao, ativo)
    SELECT v_tenant, v_emp, x.codigo_erp, x.descricao, TRUE
    FROM (VALUES
        ('A', 'Cliente Premium (A)'),
        ('B', 'Cliente Médio (B)'),
        ('C', 'Cliente Pequeno (C)'),
        ('D', 'Cliente Novo (D)')
    ) AS x(codigo_erp, descricao)
    WHERE NOT EXISTS (
        SELECT 1 FROM grupo_cliente
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = x.codigo_erp
    );

    -- ========================================================
    -- 17. RISCOS DE CLIENTE
    -- ========================================================
    INSERT INTO risco_cliente (
        cod_tenant, cod_empresa, codigo_erp, descricao,
        controle_cliente_receber_dx, controle_cliente_receber,
        controle_limite_credito, controle_geral,
        controle_mensagem_padrao, cor, ativo
    )
    SELECT v_tenant, v_emp, x.codigo_erp, x.descricao,
           0, x.receber, x.limite, x.geral,
           x.mensagem, x.cor, TRUE
    FROM (VALUES
        ('L', 'LIBERADO',  'N', 'N', 'N', '', 'HUE_GREEN'),
        ('B', 'BLOQUEADO', 'N', 'N', 'B', 'Cliente bloqueado no ERP', 'HUE_RED'),
        ('A', 'ALERTA',    'M', 'M', 'M', 'Cliente com títulos em atraso', 'HUE_YELLOW')
    ) AS x(codigo_erp, descricao, receber, limite, geral, mensagem, cor)
    WHERE NOT EXISTS (
        SELECT 1 FROM risco_cliente
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = x.codigo_erp
    );

    -- ========================================================
    -- 18. ROTAS SIMPLES
    -- ========================================================
    INSERT INTO rota_simples (cod_tenant, cod_empresa, codigo_erp, descricao, ativo)
    SELECT v_tenant, v_emp, x.codigo_erp, x.descricao, TRUE
    FROM (VALUES
        ('RT1', 'Rota Centro'),
        ('RT2', 'Rota Zona Sul'),
        ('RT3', 'Rota Zona Norte'),
        ('RT4', 'Rota Interior')
    ) AS x(codigo_erp, descricao)
    WHERE NOT EXISTS (
        SELECT 1 FROM rota_simples
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = x.codigo_erp
    );

    RAISE NOTICE '✅ Cadastros base populados com sucesso!';
END $$;

COMMIT;

-- ============================================================
-- Verificação
-- ============================================================
DO $$
DECLARE
    v_tenant INTEGER;
    v_un     INTEGER;
    v_cat    INTEGER;
    v_fab    INTEGER;
    v_cf     INTEGER;
    v_tp     INTEGER;
    v_tf     INTEGER;
    v_fp     INTEGER;
    v_cp     INTEGER;
    v_cpp    INTEGER;
    v_trans  INTEGER;
    v_tab    INTEGER;
    v_und    INTEGER;
    v_eq     INTEGER;
    v_emb    INTEGER;
    v_ram    INTEGER;
    v_grup   INTEGER;
    v_ris    INTEGER;
    v_rot    INTEGER;
BEGIN
    SELECT cod_tenant INTO v_tenant FROM tenant WHERE slug = 'distribuidora-sao-joao';

    SELECT COUNT(*) INTO v_un    FROM unidade_medida        WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_cat   FROM categoria_item        WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_fab   FROM fabricante            WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_cf    FROM classificacao_fiscal  WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_tp    FROM tipo_venda            WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_tf    FROM tipo_frete            WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_fp    FROM forma_pagamento       WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_cp    FROM condicao_pagamento    WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_cpp   FROM condicao_pagamento_parcela WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_trans FROM transportadora        WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_tab   FROM tabela_preco          WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_und   FROM unidade_negocio       WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_eq    FROM equipe_venda          WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_emb   FROM embalagem_venda       WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_ram   FROM ramo_atividade        WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_grup  FROM grupo_cliente         WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_ris   FROM risco_cliente         WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_rot   FROM rota_simples          WHERE cod_tenant = v_tenant;

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE '✅ Cadastros base — Resumo';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Tenant:                        %', v_tenant;
    RAISE NOTICE 'Unidades de medida:            %', v_un;
    RAISE NOTICE 'Categorias de item:            %', v_cat;
    RAISE NOTICE 'Fabricantes:                   %', v_fab;
    RAISE NOTICE 'Classificações fiscais:        %', v_cf;
    RAISE NOTICE 'Tipos de venda:                %', v_tp;
    RAISE NOTICE 'Tipos de frete:                %', v_tf;
    RAISE NOTICE 'Formas de pagamento:           %', v_fp;
    RAISE NOTICE 'Condições de pagamento:        %', v_cp;
    RAISE NOTICE 'Parcelas das condições:        %', v_cpp;
    RAISE NOTICE 'Transportadoras:               %', v_trans;
    RAISE NOTICE 'Tabelas de preço:              %', v_tab;
    RAISE NOTICE 'Unidades de negócio:           %', v_und;
    RAISE NOTICE 'Equipes de venda:              %', v_eq;
    RAISE NOTICE 'Embalagens:                    %', v_emb;
    RAISE NOTICE 'Ramos de atividade:            %', v_ram;
    RAISE NOTICE 'Grupos de cliente:             %', v_grup;
    RAISE NOTICE 'Riscos de cliente:             %', v_ris;
    RAISE NOTICE 'Rotas simples:                 %', v_rot;
    RAISE NOTICE '============================================';
END $$;