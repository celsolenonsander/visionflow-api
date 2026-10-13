-- ============================================================
-- SEED — Demo Comercial — Pedidos + Itens + Histórico
-- ============================================================
-- Popula: 40 pedidos ao longo dos últimos 6 meses, com:
--   - status variados (aberto, faturado, entregue, cancelado)
--   - itens reais (2 a 5 produtos por pedido)
--   - histórico completo (faturamento, entrega)
-- Idempotente: WHERE NOT EXISTS
-- RLS: set_config antes de INSERT e SELECT
-- ============================================================

BEGIN;

DO $$
DECLARE
    v_tenant         INTEGER;
    v_emp            INTEGER := 1;
    v_pedidos_ok     INTEGER := 0;
    v_itens_ok       INTEGER := 0;
    v_hist_ok        INTEGER := 0;
    v_pedido_id      INTEGER;
    v_item_id        INTEGER;
    v_cliente        RECORD;
    v_produto        RECORD;
    v_data           DATE;
    v_status         VARCHAR(2);
    v_qtd_itens      INTEGER;
    v_qtd            NUMERIC(15,4);
    v_preco          NUMERIC(15,4);
    v_desconto       NUMERIC(15,4);
    v_total_pedido   NUMERIC(15,4);
    v_contador       INTEGER := 0;
    v_cliente_arr    TEXT[];
    v_produto_arr    TEXT[];
    v_status_arr     TEXT[] := ARRAY['1', '1', '3', '3', '3', '5', '2', '12'];
BEGIN
    SELECT cod_tenant INTO v_tenant
    FROM tenant WHERE slug = 'distribuidora-sao-joao';

    IF v_tenant IS NULL THEN
        RAISE EXCEPTION 'Tenant não encontrado.';
    END IF;

    -- ⚠️ RLS
    PERFORM set_config('app.cod_tenant', v_tenant::TEXT, true);
    PERFORM set_config('app.cod_empresa', v_emp::TEXT, true);

    RAISE NOTICE 'Populando pedidos para tenant % / empresa %', v_tenant, v_emp;

    -- Coleta clientes e produtos disponíveis
    SELECT array_agg(codigo_erp) INTO v_cliente_arr
    FROM cliente WHERE cod_tenant = v_tenant AND cod_empresa = v_emp;

    SELECT array_agg(codigo_erp) INTO v_produto_arr
    FROM item WHERE cod_tenant = v_tenant AND cod_empresa = v_emp;

    -- ========================================================
    -- LOOP: cria 40 pedidos
    -- ========================================================
    FOR v_contador IN 1..40 LOOP
        -- Gera um código de pedido único
        DECLARE
            v_codigo_pedido VARCHAR(20) := 'PED' || LPAD(v_contador::TEXT, 5, '0');
            v_cliente_cod   TEXT;
            v_representante TEXT;
            v_condicao      TEXT;
            v_forma         TEXT;
            v_tipo_venda    TEXT;
            v_dias_atras    INTEGER;
            v_data_emissao  DATE;
            v_total         NUMERIC(15,4) := 0;
        BEGIN
            -- Escolhe aleatoriamente
            v_cliente_cod   := v_cliente_arr[1 + floor(random() * array_length(v_cliente_arr, 1))::INTEGER];
            v_representante := CASE (v_contador % 3)
                WHEN 0 THEN '1'  -- João
                WHEN 1 THEN '2'  -- Ana
                WHEN 2 THEN '3'  -- Carlos
            END;
            v_condicao      := (ARRAY['01','02','03','04','05'])[1 + floor(random() * 5)::INTEGER];
            v_forma         := (ARRAY['01','03','04','15','17'])[1 + floor(random() * 5)::INTEGER];            
            v_tipo_venda    := CASE WHEN v_contador % 10 = 0 THEN '2' ELSE '1' END;  -- 10% bonificação
            v_status        := v_status_arr[1 + floor(random() * array_length(v_status_arr, 1))::INTEGER];
            v_dias_atras    := floor(random() * 180)::INTEGER;
            v_data_emissao  := CURRENT_DATE - v_dias_atras;

            -- Só insere se ainda não existe
            IF NOT EXISTS (
                SELECT 1 FROM pedido
                WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = v_codigo_pedido
            ) THEN
                INSERT INTO pedido (
                    cod_tenant, cod_empresa, codigo_erp,
                    data_digitacao, data_emissao,
                    e_um_orcamento,
                    codigo_erp_cliente, cliente_tipo_pessoa, cliente_cnpj_cpf,
                    endereco_ident_faturamento, endereco_ident_cobranca, endereco_ident_entrega,
                    codigo_erp_representante,
                    codigo_erp_condicao_pagamento,
                    codigo_erp_forma_pagamento,
                    codigo_erp_tipo_frete,
                    codigo_erp_tipo_venda,
                    valor_frete, valor_desconto_capa,
                    nro_pedido_cliente,
                    observacoes_pedido,
                    situacao_pedido,
                    situacao_bloqueio
                )
                SELECT
                    v_tenant, v_emp, v_codigo_pedido,
                    v_data_emissao, v_data_emissao,
                    FALSE,
                    c.codigo_erp, c.tipo_pessoa, c.cnpj_cpf,
                    'PRINCIPAL', 'PRINCIPAL', 'PRINCIPAL',
                    v_representante,
                    v_condicao,
                    v_forma,
                    '0',
                    v_tipo_venda,
                    0, 0,
                    'CLI-' || v_contador::TEXT,
                    CASE WHEN v_contador % 5 = 0
                         THEN 'Pedido de reposição urgente'
                         ELSE '' END,
                    v_status,
                    ''
                FROM cliente c
                WHERE c.cod_tenant = v_tenant
                  AND c.cod_empresa = v_emp
                  AND c.codigo_erp = v_cliente_cod;

                GET DIAGNOSTICS v_pedido_id = ROW_COUNT;
                v_pedidos_ok := v_pedidos_ok + 1;

                -- Pega o ID interno do pedido
                SELECT codigo INTO v_pedido_id
                FROM pedido
                WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = v_codigo_pedido;

                -- ==========================================
                -- ITENS: 2 a 5 produtos por pedido
                -- ==========================================
                v_qtd_itens := 2 + floor(random() * 4)::INTEGER;

                DECLARE
                    i INTEGER;
                    v_prod_cod TEXT;
                    v_preco_prod NUMERIC(15,4);
                BEGIN
                    FOR i IN 1..v_qtd_itens LOOP
                        v_prod_cod := v_produto_arr[1 + floor(random() * array_length(v_produto_arr, 1))::INTEGER];

                        -- Pega preço do produto
                        SELECT preco_venda INTO v_preco_prod
                        FROM item
                        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = v_prod_cod;

                        v_qtd := (1 + floor(random() * 20))::NUMERIC;
                        v_desconto := ROUND((v_qtd * v_preco_prod) * 0.05, 2);  -- 5% desconto
                        v_total := v_total + (v_qtd * v_preco_prod) - v_desconto;

                        INSERT INTO pedido_item (
                            cod_tenant, cod_empresa,
                            codigo_erp_pedido, codigo_erp_item_pedido,
                            codigo_erp_produto,
                            codigo_erp_tabela_preco,
                            preco_venda_original_sugerido,
                            preco_venda_praticado_digitado,
                            quantidade_informada,
                            valor_desconto_comercial,
                            valor_total_produtos_liquido,
                            data_entrega,
                            situacao_item_pedido,
                            quantidade_faturada
                        )
                        SELECT
                            v_tenant, v_emp,
                            v_codigo_pedido,
                            v_codigo_pedido || '-' || LPAD(i::TEXT, 3, '0'),
                            v_prod_cod,
                            '1',                              -- Tabela de preço: Varejo
                            v_preco_prod,
                            v_preco_prod,
                            v_qtd,
                            v_desconto,
                            (v_qtd * v_preco_prod) - v_desconto,
                            v_data_emissao + 7,               -- entrega em 7 dias
                            CASE v_status
                                WHEN '2' THEN '2'
                                WHEN '3' THEN '3'
                                WHEN '5' THEN '5'
                                ELSE '1'
                            END,
                            CASE v_status
                                WHEN '3' THEN v_qtd
                                WHEN '5' THEN v_qtd
                                ELSE 0
                            END
                        WHERE NOT EXISTS (
                            SELECT 1 FROM pedido_item
                            WHERE cod_tenant = v_tenant
                              AND cod_empresa = v_emp
                              AND codigo_erp_pedido = v_codigo_pedido
                              AND codigo_erp_item_pedido = v_codigo_pedido || '-' || LPAD(i::TEXT, 3, '0')
                        );

                        v_itens_ok := v_itens_ok + 1;
                    END LOOP;
                END;

                -- Atualiza desconto da capa do pedido com o total
                UPDATE pedido
                SET valor_desconto_capa = v_total * 0.05
                WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo = v_pedido_id;

                -- ==========================================
                -- HISTÓRICO (para pedidos faturados/entregues/cancelados)
                -- ==========================================
                IF v_status IN ('3', '5', '2') THEN
                    INSERT INTO pedido_historico (
                        cod_tenant, cod_empresa,
                        codigo_erp_pedido, codigo_erp_historico_pedido,
                        data_historico, hora_historico,
                        tipo_historico, descricao_historico,
                        nro_nota_fiscal
                    )
                    SELECT
                        v_tenant, v_emp,
                        v_codigo_pedido,
                        'HIST-' || v_codigo_pedido || '-1',
                        v_data_emissao + 1,
                        '10:30:00'::TIME,
                        CASE
                            WHEN v_status = '3' THEN '3'  -- Faturado
                            WHEN v_status = '5' THEN '5'  -- Entregue
                            WHEN v_status = '2' THEN '2'  -- Cancelado
                            ELSE '3'
                        END,
                        CASE
                            WHEN v_status = '3' THEN 'Pedido faturado - NF ' || (100000 + v_contador)
                            WHEN v_status = '5' THEN 'Pedido entregue ao cliente'
                            WHEN v_status = '2' THEN 'Pedido cancelado pelo cliente'
                            ELSE ''
                        END,
                        CASE
                            WHEN v_status IN ('3', '5') THEN (100000 + v_contador)::TEXT
                            ELSE ''
                        END
                    WHERE NOT EXISTS (
                        SELECT 1 FROM pedido_historico
                        WHERE cod_tenant = v_tenant
                          AND cod_empresa = v_emp
                          AND codigo_erp_pedido = v_codigo_pedido
                    );

                    v_hist_ok := v_hist_ok + 1;
                END IF;

                -- Se faturado, adiciona histórico de entrega também
                IF v_status = '5' THEN
                    INSERT INTO pedido_historico (
                        cod_tenant, cod_empresa,
                        codigo_erp_pedido, codigo_erp_historico_pedido,
                        data_historico, hora_historico,
                        tipo_historico, descricao_historico,
                        nro_nota_fiscal
                    )
                    SELECT
                        v_tenant, v_emp,
                        v_codigo_pedido,
                        'HIST-' || v_codigo_pedido || '-2',
                        v_data_emissao + 3,
                        '14:15:00'::TIME,
                        '5',
                        'Pedido entregue ao cliente final',
                        (100000 + v_contador)::TEXT
                    WHERE NOT EXISTS (
                        SELECT 1 FROM pedido_historico
                        WHERE cod_tenant = v_tenant
                          AND cod_empresa = v_emp
                          AND codigo_erp_pedido = v_codigo_pedido
                          AND codigo_erp_historico_pedido = 'HIST-' || v_codigo_pedido || '-2'
                    );

                    v_hist_ok := v_hist_ok + 1;
                END IF;

            END IF;
        END;
    END LOOP;

    RAISE NOTICE '✅ % pedidos inseridos', v_pedidos_ok;
    RAISE NOTICE '✅ % itens inseridos', v_itens_ok;
    RAISE NOTICE '✅ % registros de histórico', v_hist_ok;

END $$;

COMMIT;

-- ============================================================
-- Verificação
-- ============================================================
DO $$
DECLARE
    v_tenant    INTEGER;
    v_pedidos   INTEGER;
    v_itens     INTEGER;
    v_hist      INTEGER;
    v_abertos   INTEGER;
    v_faturados INTEGER;
    v_entregues INTEGER;
    v_cancel    INTEGER;
BEGIN
    SELECT cod_tenant INTO v_tenant FROM tenant WHERE slug = 'distribuidora-sao-joao';

    -- ⚠️ RLS
    PERFORM set_config('app.cod_tenant', v_tenant::TEXT, true);
    PERFORM set_config('app.cod_empresa', '1', true);

    SELECT COUNT(*) INTO v_pedidos   FROM pedido WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_itens     FROM pedido_item WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_hist      FROM pedido_historico WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_abertos   FROM pedido WHERE cod_tenant = v_tenant AND situacao_pedido = '1';
    SELECT COUNT(*) INTO v_faturados FROM pedido WHERE cod_tenant = v_tenant AND situacao_pedido = '3';
    SELECT COUNT(*) INTO v_entregues FROM pedido WHERE cod_tenant = v_tenant AND situacao_pedido = '5';
    SELECT COUNT(*) INTO v_cancel    FROM pedido WHERE cod_tenant = v_tenant AND situacao_pedido = '2';

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE '✅ Pedidos — Resumo';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Tenant:                    %', v_tenant;
    RAISE NOTICE 'Total de pedidos:          %', v_pedidos;
    RAISE NOTICE '  Abertos (1):             %', v_abertos;
    RAISE NOTICE '  Faturados (3):           %', v_faturados;
    RAISE NOTICE '  Entregues (5):           %', v_entregues;
    RAISE NOTICE '  Cancelados (2):          %', v_cancel;
    RAISE NOTICE 'Itens de pedido:           %', v_itens;
    RAISE NOTICE 'Históricos:                %', v_hist;
    RAISE NOTICE '============================================';
END $$;