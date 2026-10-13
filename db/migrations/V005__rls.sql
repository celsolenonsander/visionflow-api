-- ============================================================
-- PARTE 5 — ROW-LEVEL SECURITY (RLS)
-- Banco: epare_forca_de_vendas
-- PostgreSQL 16
-- ============================================================
-- Objetivo: isolamento automático por tenant/empresa.
--
-- COMO FUNCIONA:
--   1. A API, ao autenticar um usuário, executa:
--        SET LOCAL app.cod_tenant = '1';
--        SET LOCAL app.cod_empresa = '1';   -- opcional
--   2. Todas as queries nas tabelas com RLS filtram automaticamente
--   3. Se a API esquecer o filtro, o banco filtra por ela
-- ============================================================

BEGIN;

-- ============================================================
-- 1. FUNÇÕES HELPER — leem o contexto da sessão
-- ============================================================
CREATE OR REPLACE FUNCTION fn_current_tenant()
RETURNS INTEGER AS $$
BEGIN
    RETURN NULLIF(current_setting('app.cod_tenant', true), '')::INTEGER;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION fn_current_empresa()
RETURNS INTEGER AS $$
BEGIN
    RETURN NULLIF(current_setting('app.cod_empresa', true), '')::INTEGER;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION fn_current_tenant() IS 'Retorna cod_tenant da sessão (SET LOCAL app.cod_tenant)';
COMMENT ON FUNCTION fn_current_empresa() IS 'Retorna cod_empresa da sessão (SET LOCAL app.cod_empresa)';


-- ============================================================
-- 2. HABILITAR RLS + POLICY em TODAS as tabelas operacionais
-- ============================================================
DO $$
DECLARE
    tabelas TEXT[] := ARRAY[
        -- Parte 2: Cadastros base
        'unidade_medida', 'categoria_item', 'fabricante',
        'classificacao_fiscal', 'grupo_cliente', 'ramo_atividade',
        'rota_simples', 'risco_cliente', 'tipo_venda', 'tipo_frete',
        'forma_pagamento', 'condicao_pagamento', 'transportadora',
        'tabela_preco', 'unidade_negocio', 'representante',
        'equipe_venda', 'embalagem_venda',
        -- Parte 3: Operacionais
        'item', 'item_estoque', 'tabela_preco_item',
        'cliente', 'cliente_conta_receber', 'pedido', 'customizador_dados',
        -- Parte 4: Filhos
        'cliente_endereco_adicional', 'cliente_representante',
        'cliente_contato', 'cliente_tabela_preco',
        'cliente_condicao_pagamento', 'cliente_forma_pagamento',
        'cliente_imposto', 'cliente_campo_adicional',
        'cliente_rota_simples', 'item_imposto',
        'item_unidade_negocio', 'item_embalagem_venda',
        'item_campo_adicional', 'representante_tipo_venda',
        'representante_supervisor', 'tabela_preco_representante',
        'tabela_preco_condicao_pagamento', 'tabela_preco_tipo_venda',
        'tabela_preco_cliente', 'tabela_preco_grupo_cliente',
        'tabela_preco_unidade_negocio', 'condicao_pagamento_forma',
        'condicao_pagamento_unidade', 'condicao_pagamento_parcela',
        'tipo_venda_condicao_pagamento', 'tipo_venda_unidade_negocio',
        'forma_pagamento_unidade_negocio', 'equipe_venda_categoria',
        'equipe_venda_item', 'pedido_item', 'pedido_historico'
    ];
    t TEXT;
BEGIN
    FOREACH t IN ARRAY tabelas LOOP
        -- Habilita RLS
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
        
        -- Força RLS até para o dono (epare)
        EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
        
        -- Policy de isolamento
        EXECUTE format($f$
            CREATE POLICY tenant_isolation ON %I
                FOR ALL
                TO PUBLIC
                USING (
                    cod_tenant = fn_current_tenant()
                    AND (
                        fn_current_empresa() IS NULL
                        OR cod_empresa = fn_current_empresa()
                    )
                )
                WITH CHECK (
                    cod_tenant = fn_current_tenant()
                    AND (
                        fn_current_empresa() IS NULL
                        OR cod_empresa = fn_current_empresa()
                    )
                )
        $f$, t);
        
        RAISE NOTICE 'RLS aplicado em: %', t;
    END LOOP;
END $$;


-- ============================================================
-- 3. DADOS DE TESTE — 2 tenants + empresas + clientes
-- ============================================================
INSERT INTO tenant (cod_revendedor, slug, nome, plano, limite_empresas, limite_usuarios, ativo)
VALUES (1, 'tenant-a', 'Tenant A Ltda', 'basico', 5, 10, TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO tenant (cod_revendedor, slug, nome, plano, limite_empresas, limite_usuarios, ativo)
VALUES (1, 'tenant-b', 'Tenant B Ltda', 'basico', 5, 10, TRUE)
ON CONFLICT DO NOTHING;

DO $$
DECLARE
    t_a INTEGER;
    t_b INTEGER;
BEGIN
    SELECT cod_tenant INTO t_a FROM tenant WHERE slug = 'tenant-a';
    SELECT cod_tenant INTO t_b FROM tenant WHERE slug = 'tenant-b';
    
    INSERT INTO empresa (cod_tenant, cod_empresa, cnpj, razao_social, ativo)
    VALUES (t_a, 1, '33.333.333/0001-33', 'Empresa do Tenant A', TRUE)
    ON CONFLICT DO NOTHING;
    
    INSERT INTO empresa (cod_tenant, cod_empresa, cnpj, razao_social, ativo)
    VALUES (t_b, 1, '44.444.444/0001-44', 'Empresa do Tenant B', TRUE)
    ON CONFLICT DO NOTHING;
    
    -- Define contexto para poder inserir clientes (RLS está ativo)
    PERFORM set_config('app.cod_tenant', t_a::TEXT, true);
    PERFORM set_config('app.cod_empresa', '1', true);
    
    INSERT INTO cliente (cod_tenant, cod_empresa, codigo_erp, nome_razao_social, tipo_pessoa, ativo)
    VALUES 
        (t_a, 1, 'A001', 'Cliente A1', 'J', TRUE),
        (t_a, 1, 'A002', 'Cliente A2', 'J', TRUE)
    ON CONFLICT DO NOTHING;
    
    PERFORM set_config('app.cod_tenant', t_b::TEXT, true);
    
    INSERT INTO cliente (cod_tenant, cod_empresa, codigo_erp, nome_razao_social, tipo_pessoa, ativo)
    VALUES 
        (t_b, 1, 'B001', 'Cliente B1', 'J', TRUE),
        (t_b, 1, 'B002', 'Cliente B2', 'J', TRUE)
    ON CONFLICT DO NOTHING;
    
    RAISE NOTICE 'Tenant A: %, Tenant B: %', t_a, t_b;
END $$;

COMMIT;

-- ============================================================
-- FIM DA PARTE 5
-- ============================================================
-- COMO TESTAR:
--   psql -h localhost -U epare -d epare_forca_de_vendas
--
--   -- Sem contexto: retorna vazio
--   SELECT * FROM cliente;
--
--   -- Com contexto do Tenant A
--   BEGIN;
--   SET LOCAL app.cod_tenant = '2';
--   SELECT cod_tenant, codigo_erp, nome_razao_social FROM cliente;
--   COMMIT;
--
--   -- Com contexto do Tenant B
--   BEGIN;
--   SET LOCAL app.cod_tenant = '3';
--   SELECT cod_tenant, codigo_erp, nome_razao_social FROM cliente;
--   COMMIT;
-- ============================================================
