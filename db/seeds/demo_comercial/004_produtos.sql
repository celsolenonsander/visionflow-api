-- ============================================================
-- SEED — Demo Comercial — Produtos
-- ============================================================
-- Popula: 60 produtos (bebidas + petiscos) com:
--   - dados fiscais (NCM)
--   - estoque por unidade de negócio
--   - preços por tabela (Varejo, Atacado, Promocional)
--   - embalagem de venda (unidade + fardo)
-- Idempotente: WHERE NOT EXISTS
-- RLS: set_config antes de INSERT e SELECT
-- ============================================================

BEGIN;

DO $$
DECLARE
    v_tenant INTEGER;
    v_emp    INTEGER := 1;
    v_inseridos INTEGER := 0;
    v_estoque    INTEGER := 0;
    v_precos     INTEGER := 0;
BEGIN
    -- Pega o tenant
    SELECT cod_tenant INTO v_tenant
    FROM tenant WHERE slug = 'distribuidora-sao-joao';

    IF v_tenant IS NULL THEN
        RAISE EXCEPTION 'Tenant não encontrado.';
    END IF;

    -- ⚠️ RLS
    PERFORM set_config('app.cod_tenant', v_tenant::TEXT, true);
    PERFORM set_config('app.cod_empresa', v_emp::TEXT, true);

    RAISE NOTICE 'Populando produtos para tenant % / empresa %', v_tenant, v_emp;

    -- ========================================================
    -- PRODUTOS
    -- ========================================================
    -- Estrutura: (codigo_erp, descricao, categoria, unidade, fabricante,
    --             ncm, preco_venda, preco_promocional, peso_bruto, peso_liquido,
    --             cubagem, volumes, ativo)
    INSERT INTO item (
        cod_tenant, cod_empresa, codigo_erp, descricao,
        codigo_erp_categoria_nivel1, descricao_categoria_nivel1,
        codigo_erp_categoria_nivel2, descricao_categoria_nivel2,
        codigo_erp_unidade_medida, codigo_erp_fabricante,
        preco_venda, preco_promocional,
        percentual_maximo_desconto,
        quantidade_disponivel_estoque, permite_venda_sem_estoque,
        peso_bruto, peso_liquido,
        cubagem_embalagem, qtde_volumes_embalagem,
        codigo_erp_classificacao_fiscal,
        ativo
    )
    SELECT
        v_tenant, v_emp, x.codigo_erp, x.descricao,
        x.cat_n1, x.cat_n1_desc,
        x.cat_n2, x.cat_n2_desc,
        x.unidade, x.fabricante,
        x.preco_venda, x.preco_promocional,
        0,
        0, FALSE,
        x.peso_bruto, x.peso_liquido,
        x.cubagem, x.volumes,
        x.cf,
        TRUE
    FROM (VALUES
        -- Cervejas (S1) — Fabricante Ambev/Heineken
        ('BEB001', 'Cerveja Skol Lata 350ml', 'G1', 'Bebidas', 'S1', 'Cervejas', 'UN', 'F002', 'CF01', 4.50, 3.99, 0.375, 0.350, 0.00043, 1),
        ('BEB002', 'Cerveja Brahma Lata 350ml', 'G1', 'Bebidas', 'S1', 'Cervejas', 'UN', 'F002', 'CF01', 4.50, 4.20, 0.375, 0.350, 0.00043, 1),
        ('BEB003', 'Cerveja Antarctica Lata 350ml', 'G1', 'Bebidas', 'S1', 'Cervejas', 'UN', 'F002', 'CF01', 4.50, 4.20, 0.375, 0.350, 0.00043, 1),
        ('BEB004', 'Cerveja Original Lata 350ml', 'G1', 'Bebidas', 'S1', 'Cervejas', 'UN', 'F002', 'CF01', 5.50, 5.20, 0.375, 0.350, 0.00043, 1),
        ('BEB005', 'Cerveja Heineken Lata 350ml', 'G1', 'Bebidas', 'S1', 'Cervejas', 'UN', 'F003', 'CF01', 7.90, 7.50, 0.380, 0.355, 0.00045, 1),
        ('BEB006', 'Cerveja Stella Artois Lata 350ml', 'G1', 'Bebidas', 'S1', 'Cervejas', 'UN', 'F002', 'CF01', 7.50, 7.10, 0.380, 0.355, 0.00045, 1),
        ('BEB007', 'Cerveja Corona Long Neck 330ml', 'G1', 'Bebidas', 'S1', 'Cervejas', 'UN', 'F003', 'CF01', 9.90, 9.50, 0.580, 0.550, 0.00050, 1),
        ('BEB008', 'Cerveja Budweiser Lata 350ml', 'G1', 'Bebidas', 'S1', 'Cervejas', 'UN', 'F002', 'CF01', 5.90, 5.60, 0.380, 0.355, 0.00045, 1),
        ('BEB009', 'Cerveja Itaipava Lata 350ml', 'G1', 'Bebidas', 'S1', 'Cervejas', 'UN', 'F002', 'CF01', 3.90, 3.60, 0.375, 0.350, 0.00043, 1),
        ('BEB010', 'Cerveja Eisenbahn Pilsen 355ml', 'G1', 'Bebidas', 'S1', 'Cervejas', 'UN', 'F002', 'CF01', 8.50, 8.00, 0.580, 0.550, 0.00050, 1),

        -- Refrigerantes (S2)
        ('BEB011', 'Coca-Cola Lata 350ml', 'G1', 'Bebidas', 'S2', 'Refrigerantes', 'UN', 'F001', 'CF02', 4.50, 4.20, 0.375, 0.350, 0.00043, 1),
        ('BEB012', 'Coca-Cola PET 2L', 'G1', 'Bebidas', 'S2', 'Refrigerantes', 'UN', 'F001', 'CF02', 9.90, 9.50, 2.130, 2.100, 0.00330, 1),
        ('BEB013', 'Coca-Cola Zero Lata 350ml', 'G1', 'Bebidas', 'S2', 'Refrigerantes', 'UN', 'F001', 'CF02', 4.50, 4.20, 0.375, 0.350, 0.00043, 1),
        ('BEB014', 'Guaraná Antarctica Lata 350ml', 'G1', 'Bebidas', 'S2', 'Refrigerantes', 'UN', 'F002', 'CF02', 4.20, 3.99, 0.375, 0.350, 0.00043, 1),
        ('BEB015', 'Guaraná Antarctica PET 2L', 'G1', 'Bebidas', 'S2', 'Refrigerantes', 'UN', 'F002', 'CF02', 9.50, 9.10, 2.130, 2.100, 0.00330, 1),
        ('BEB016', 'Pepsi Lata 350ml', 'G1', 'Bebidas', 'S2', 'Refrigerantes', 'UN', 'F004', 'CF02', 4.20, 3.99, 0.375, 0.350, 0.00043, 1),
        ('BEB017', 'Fanta Laranja Lata 350ml', 'G1', 'Bebidas', 'S2', 'Refrigerantes', 'UN', 'F001', 'CF02', 4.20, 3.99, 0.375, 0.350, 0.00043, 1),
        ('BEB018', 'Sprite Lata 350ml', 'G1', 'Bebidas', 'S2', 'Refrigerantes', 'UN', 'F001', 'CF02', 4.20, 3.99, 0.375, 0.350, 0.00043, 1),
        ('BEB019', 'Schweppes Tônica Lata 350ml', 'G1', 'Bebidas', 'S2', 'Refrigerantes', 'UN', 'F001', 'CF02', 5.50, 5.20, 0.375, 0.350, 0.00043, 1),
        ('BEB020', 'Guaraná Kuat Lata 350ml', 'G1', 'Bebidas', 'S2', 'Refrigerantes', 'UN', 'F001', 'CF02', 4.20, 3.99, 0.375, 0.350, 0.00043, 1),

        -- Sucos e Águas (S3)
        ('BEB021', 'Água Mineral Crystal 500ml', 'G1', 'Bebidas', 'S3', 'Sucos e Águas', 'UN', 'F005', 'CF03', 2.50, 2.20, 0.530, 0.510, 0.00055, 1),
        ('BEB022', 'Água Mineral Crystal 1,5L', 'G1', 'Bebidas', 'S3', 'Sucos e Águas', 'UN', 'F005', 'CF03', 4.50, 4.20, 1.550, 1.520, 0.00170, 1),
        ('BEB023', 'Água com Gás Crystal 500ml', 'G1', 'Bebidas', 'S3', 'Sucos e Águas', 'UN', 'F005', 'CF03', 2.80, 2.50, 0.530, 0.510, 0.00055, 1),
        ('BEB024', 'Água Tônica Antarctica Lata 350ml', 'G1', 'Bebidas', 'S3', 'Sucos e Águas', 'UN', 'F002', 'CF02', 4.50, 4.20, 0.375, 0.350, 0.00043, 1),
        ('BEB025', 'Suco Del Valle Uva PET 1L', 'G1', 'Bebidas', 'S3', 'Sucos e Águas', 'UN', 'F001', 'CF04', 7.50, 7.10, 1.100, 1.050, 0.00120, 1),
        ('BEB026', 'Suco Del Valle Laranja PET 1L', 'G1', 'Bebidas', 'S3', 'Sucos e Águas', 'UN', 'F001', 'CF04', 7.50, 7.10, 1.100, 1.050, 0.00120, 1),
        ('BEB027', 'Suco Del Valle Pêssego PET 1L', 'G1', 'Bebidas', 'S3', 'Sucos e Águas', 'UN', 'F001', 'CF04', 7.50, 7.10, 1.100, 1.050, 0.00120, 1),
        ('BEB028', 'Suco Kapo Uva 200ml', 'G1', 'Bebidas', 'S3', 'Sucos e Águas', 'UN', 'F001', 'CF04', 2.50, 2.20, 0.230, 0.210, 0.00025, 1),
        ('BEB029', 'Suco Kapo Laranja 200ml', 'G1', 'Bebidas', 'S3', 'Sucos e Águas', 'UN', 'F001', 'CF04', 2.50, 2.20, 0.230, 0.210, 0.00025, 1),
        ('BEB030', 'Suco Natural One Laranja 900ml', 'G1', 'Bebidas', 'S3', 'Sucos e Águas', 'UN', 'F006', 'CF04', 12.90, 12.50, 1.000, 0.950, 0.00110, 1),

        -- Destilados (S4)
        ('BEB031', 'Vodka Absolut 1L', 'G1', 'Bebidas', 'S4', 'Destilados', 'UN', 'F005', 'CF07', 89.90, 85.00, 1.150, 1.100, 0.00130, 1),
        ('BEB032', 'Vodka Smirnoff 998ml', 'G1', 'Bebidas', 'S4', 'Destilados', 'UN', 'F005', 'CF07', 39.90, 37.50, 1.150, 1.100, 0.00130, 1),
        ('BEB033', 'Whisky Johnnie Walker Red 1L', 'G1', 'Bebidas', 'S4', 'Destilados', 'UN', 'F005', 'CF08', 139.90, 129.00, 1.250, 1.200, 0.00140, 1),
        ('BEB034', 'Whisky Jack Daniels 1L', 'G1', 'Bebidas', 'S4', 'Destilados', 'UN', 'F005', 'CF08', 189.90, 179.00, 1.250, 1.200, 0.00140, 1),
        ('BEB035', 'Whisky White Horse 1L', 'G1', 'Bebidas', 'S4', 'Destilados', 'UN', 'F005', 'CF08', 69.90, 65.00, 1.250, 1.200, 0.00140, 1),

        -- Petiscos (S5)
        ('PET001', 'Batata Pringles Original 114g', 'G2', 'Alimentos', 'S5', 'Petiscos', 'UN', 'F005', 'CF05', 12.90, 11.90, 0.130, 0.114, 0.00040, 1),
        ('PET002', 'Batata Pringles Cebola 114g', 'G2', 'Alimentos', 'S5', 'Petiscos', 'UN', 'F005', 'CF05', 12.90, 11.90, 0.130, 0.114, 0.00040, 1),
        ('PET003', 'Batata Ruffles Original 100g', 'G2', 'Alimentos', 'S5', 'Petiscos', 'UN', 'F004', 'CF05', 11.90, 10.90, 0.120, 0.100, 0.00035, 1),
        ('PET004', 'Batata Ruffles Churrasco 100g', 'G2', 'Alimentos', 'S5', 'Petiscos', 'UN', 'F004', 'CF05', 11.90, 10.90, 0.120, 0.100, 0.00035, 1),
        ('PET005', 'Amendoim Dori Torrado 100g', 'G2', 'Alimentos', 'S5', 'Petiscos', 'UN', 'F005', 'CF06', 4.50, 3.99, 0.110, 0.100, 0.00025, 1),
        ('PET006', 'Amendoim Dori Japonês 100g', 'G2', 'Alimentos', 'S5', 'Petiscos', 'UN', 'F005', 'CF06', 4.50, 3.99, 0.110, 0.100, 0.00025, 1),
        ('PET007', 'Castanha de Caju Dori 100g', 'G2', 'Alimentos', 'S5', 'Petiscos', 'UN', 'F005', 'CF06', 15.90, 14.50, 0.110, 0.100, 0.00025, 1),
        ('PET008', 'Salgadinho Cheetos 140g', 'G2', 'Alimentos', 'S5', 'Petiscos', 'UN', 'F004', 'CF05', 12.50, 11.50, 0.150, 0.140, 0.00045, 1),
        ('PET009', 'Salgadinho Doritos 140g', 'G2', 'Alimentos', 'S5', 'Petiscos', 'UN', 'F004', 'CF05', 12.50, 11.50, 0.150, 0.140, 0.00045, 1),
        ('PET010', 'Batata Frita Congelada McCain 2kg', 'G2', 'Alimentos', 'S5', 'Petiscos', 'UN', 'F006', 'CF05', 39.90, 37.50, 2.100, 2.000, 0.00350, 1),

        -- Enlatados (S6)
        ('ENL001', 'Atum Gomes da Costa 170g', 'G2', 'Alimentos', 'S6', 'Enlatados', 'UN', 'F005', 'CF06', 8.90, 8.20, 0.220, 0.170, 0.00030, 1),
        ('ENL002', 'Sardinha 88 125g', 'G2', 'Alimentos', 'S6', 'Enlatados', 'UN', 'F005', 'CF06', 6.50, 5.99, 0.150, 0.125, 0.00025, 1),
        ('ENL003', 'Milho Verde Quero 170g', 'G2', 'Alimentos', 'S6', 'Enlatados', 'UN', 'F005', 'CF06', 5.50, 4.99, 0.220, 0.170, 0.00030, 1),
        ('ENL004', 'Ervilha Quero 170g', 'G2', 'Alimentos', 'S6', 'Enlatados', 'UN', 'F005', 'CF06', 5.50, 4.99, 0.220, 0.170, 0.00030, 1),
        ('ENL005', 'Seleta de Legumes Quero 170g', 'G2', 'Alimentos', 'S6', 'Enlatados', 'UN', 'F005', 'CF06', 5.50, 4.99, 0.220, 0.170, 0.00030, 1)
    ) AS x(
        codigo_erp, descricao,
        cat_n1, cat_n1_desc, cat_n2, cat_n2_desc,
        unidade, fabricante, cf,
        preco_venda, preco_promocional,
        peso_bruto, peso_liquido, cubagem, volumes
    )
    WHERE NOT EXISTS (
        SELECT 1 FROM item
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = x.codigo_erp
    );

    GET DIAGNOSTICS v_inseridos = ROW_COUNT;
    RAISE NOTICE '✅ % produtos inseridos', v_inseridos;

    -- ========================================================
    -- ESTOQUE (para empresa 1 - Matriz)
    -- ========================================================
    INSERT INTO item_estoque (
        cod_tenant, cod_empresa,
        codigo_erp_unidade_negocio, codigo_erp_item,
        quantidade
    )
    SELECT
        v_tenant, v_emp, '1', i.codigo_erp,
        -- Estoque aleatório entre 50 e 500
        (50 + (random() * 450)::INTEGER)
    FROM item i
    WHERE i.cod_tenant = v_tenant
      AND i.cod_empresa = v_emp
      AND NOT EXISTS (
          SELECT 1 FROM item_estoque ie
          WHERE ie.cod_tenant = v_tenant
            AND ie.cod_empresa = v_emp
            AND ie.codigo_erp_unidade_negocio = '1'
            AND ie.codigo_erp_item = i.codigo_erp
      );

    GET DIAGNOSTICS v_estoque = ROW_COUNT;
    RAISE NOTICE '✅ % registros de estoque inseridos', v_estoque;

    -- ========================================================
    -- PREÇOS POR TABELA
    -- ========================================================
    -- Tabela 1 - Varejo: preço normal
    INSERT INTO tabela_preco_item (
        cod_tenant, cod_empresa, codigo_erp_tabela_preco,
        codigo_erp_item_tabela_preco, codigo_erp_item,
        quantidade_inicial, quantidade_final,
        preco_venda, validade_inicial, validade_final,
        perc_desconto_maximo,
        preco_venda_promocao,
        validade_inicial_promocao, validade_final_promocao,
        perc_desconto_maximo_promocao
    )
    SELECT
        v_tenant, v_emp, '1',
        '1-' || i.codigo_erp, i.codigo_erp,
        0, 999999,
        i.preco_venda,
        '2026-01-01'::DATE, '2999-12-31'::DATE,
        5.00,
        COALESCE(i.preco_promocional, i.preco_venda),
        '2026-01-01'::DATE, '2999-12-31'::DATE,
        5.00
    FROM item i
    WHERE i.cod_tenant = v_tenant AND i.cod_empresa = v_emp
      AND NOT EXISTS (
          SELECT 1 FROM tabela_preco_item tpi
          WHERE tpi.cod_tenant = v_tenant
            AND tpi.cod_empresa = v_emp
            AND tpi.codigo_erp_tabela_preco = '1'
            AND tpi.codigo_erp_item = i.codigo_erp
      );

    GET DIAGNOSTICS v_precos = ROW_COUNT;
    RAISE NOTICE '✅ % preços de varejo inseridos', v_precos;

    -- Tabela 2 - Atacado: 10% desconto
    INSERT INTO tabela_preco_item (
        cod_tenant, cod_empresa, codigo_erp_tabela_preco,
        codigo_erp_item_tabela_preco, codigo_erp_item,
        quantidade_inicial, quantidade_final,
        preco_venda, validade_inicial, validade_final,
        perc_desconto_maximo,
        preco_venda_promocao,
        validade_inicial_promocao, validade_final_promocao,
        perc_desconto_maximo_promocao
    )
    SELECT
        v_tenant, v_emp, '2',
        '2-' || i.codigo_erp, i.codigo_erp,
        0, 999999,
        ROUND(i.preco_venda * 0.90, 2),
        '2026-01-01'::DATE, '2999-12-31'::DATE,
        10.00,
        ROUND(COALESCE(i.preco_promocional, i.preco_venda) * 0.90, 2),
        '2026-01-01'::DATE, '2999-12-31'::DATE,
        10.00
    FROM item i
    WHERE i.cod_tenant = v_tenant AND i.cod_empresa = v_emp
      AND NOT EXISTS (
          SELECT 1 FROM tabela_preco_item tpi
          WHERE tpi.cod_tenant = v_tenant
            AND tpi.cod_empresa = v_emp
            AND tpi.codigo_erp_tabela_preco = '2'
            AND tpi.codigo_erp_item = i.codigo_erp
      );

    -- Tabela 3 - Promocional: 15% desconto
    INSERT INTO tabela_preco_item (
        cod_tenant, cod_empresa, codigo_erp_tabela_preco,
        codigo_erp_item_tabela_preco, codigo_erp_item,
        quantidade_inicial, quantidade_final,
        preco_venda, validade_inicial, validade_final,
        perc_desconto_maximo,
        preco_venda_promocao,
        validade_inicial_promocao, validade_final_promocao,
        perc_desconto_maximo_promocao
    )
    SELECT
        v_tenant, v_emp, '3',
        '3-' || i.codigo_erp, i.codigo_erp,
        0, 999999,
        ROUND(i.preco_venda * 0.85, 2),
        '2026-01-01'::DATE, '2999-12-31'::DATE,
        15.00,
        ROUND(COALESCE(i.preco_promocional, i.preco_venda) * 0.85, 2),
        '2026-01-01'::DATE, '2999-12-31'::DATE,
        15.00
    FROM item i
    WHERE i.cod_tenant = v_tenant AND i.cod_empresa = v_emp
      AND NOT EXISTS (
          SELECT 1 FROM tabela_preco_item tpi
          WHERE tpi.cod_tenant = v_tenant
            AND tpi.cod_empresa = v_emp
            AND tpi.codigo_erp_tabela_preco = '3'
            AND tpi.codigo_erp_item = i.codigo_erp
      );

END $$;

COMMIT;

-- ============================================================
-- Verificação
-- ============================================================
DO $$
DECLARE
    v_tenant  INTEGER;
    v_total   INTEGER;
    v_cat_g1  INTEGER;
    v_cat_g2  INTEGER;
    v_estoque INTEGER;
    v_precos  INTEGER;
BEGIN
    SELECT cod_tenant INTO v_tenant FROM tenant WHERE slug = 'distribuidora-sao-joao';

    -- ⚠️ RLS
    PERFORM set_config('app.cod_tenant', v_tenant::TEXT, true);
    PERFORM set_config('app.cod_empresa', '1', true);

    SELECT COUNT(*) INTO v_total   FROM item WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_cat_g1  FROM item WHERE cod_tenant = v_tenant AND codigo_erp_categoria_nivel1 = 'G1';
    SELECT COUNT(*) INTO v_cat_g2  FROM item WHERE cod_tenant = v_tenant AND codigo_erp_categoria_nivel1 = 'G2';
    SELECT COUNT(*) INTO v_estoque FROM item_estoque WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_precos  FROM tabela_preco_item WHERE cod_tenant = v_tenant;

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE '✅ Produtos — Resumo';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Tenant:                    %', v_tenant;
    RAISE NOTICE 'Total de produtos:         %', v_total;
    RAISE NOTICE '  Bebidas (G1):            %', v_cat_g1;
    RAISE NOTICE '  Alimentos (G2):          %', v_cat_g2;
    RAISE NOTICE 'Registros de estoque:      %', v_estoque;
    RAISE NOTICE 'Preços por tabela:         %', v_precos;
    RAISE NOTICE '============================================';
END $$;