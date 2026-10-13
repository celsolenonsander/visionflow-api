-- ============================================================
-- SEED — Demo Comercial — Base
-- ============================================================
-- Cria: revendedor, tenant, empresas, usuários, vínculos
-- Cenário: distribuidora de bebidas em SP
-- Idempotente: usa WHERE NOT EXISTS em vez de ON CONFLICT
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- 1. Revendedor (você, VisionFlow)
-- ------------------------------------------------------------
INSERT INTO revendedor (
    slug, nome, cnpj, email_contato, telefone,
    marca_nome, marca_cor_primaria, marca_cor_secundaria,
    plano, percentual_comissao, limite_tenants, ativo
)
SELECT
    'visionflow',
    'VisionFlow Sistemas LTDA',
    '12.345.678/0001-90',
    'contato@visionflow.com.br',
    '(11) 3000-1000',
    'VisionFlow',
    '#0066CC',
    '#004A99',
    'enterprise',
    30.00,
    100,
    TRUE
WHERE NOT EXISTS (
    SELECT 1 FROM revendedor WHERE slug = 'visionflow'
);

-- ------------------------------------------------------------
-- 2. Tenant — Distribuidora São João
-- ------------------------------------------------------------
INSERT INTO tenant (
    cod_revendedor, slug, nome, cnpj, email_contato, telefone,
    plano, limite_empresas, limite_usuarios, ativo
)
SELECT
    r.cod_revendedor,
    'distribuidora-sao-joao',
    'Distribuidora São João LTDA',
    '23.456.789/0001-10',
    'financeiro@saajoao.com.br',
    '(11) 3344-5566',
    'pro',
    10,
    50,
    TRUE
FROM revendedor r
WHERE r.slug = 'visionflow'
  AND NOT EXISTS (
    SELECT 1 FROM tenant WHERE slug = 'distribuidora-sao-joao'
  );

-- ------------------------------------------------------------
-- 3. Empresas (Matriz SP + Filial Campinas)
-- ------------------------------------------------------------
INSERT INTO empresa (
    cod_tenant, cod_empresa, slug, cnpj, razao_social, nome_fantasia,
    inscricao_estadual,
    cep, logradouro, numero, complemento, bairro, cidade, estado,
    email, telefone, ativo
)
SELECT
    t.cod_tenant, 1, 'matriz',
    '23.456.789/0001-10',
    'Distribuidora São João LTDA',
    'São João Distribuidora',
    '123.456.789.012',
    '01310-100', 'Av. Paulista', '1578', 'Sala 401', 'Bela Vista', 'São Paulo', 'SP',
    'matriz@saajoao.com.br', '(11) 3344-5566',
    TRUE
FROM tenant t
WHERE t.slug = 'distribuidora-sao-joao'
  AND NOT EXISTS (
    SELECT 1 FROM empresa WHERE cod_tenant = t.cod_tenant AND cod_empresa = 1
  );

INSERT INTO empresa (
    cod_tenant, cod_empresa, slug, cnpj, razao_social, nome_fantasia,
    inscricao_estadual,
    cep, logradouro, numero, complemento, bairro, cidade, estado,
    email, telefone, ativo
)
SELECT
    t.cod_tenant, 2, 'campinas',
    '23.456.789/0002-00',
    'Distribuidora São João - Filial Campinas',
    'São João Campinas',
    '123.456.789.013',
    '13010-100', 'Av. Francisco Glicério', '500', '', 'Centro', 'Campinas', 'SP',
    'campinas@saajoao.com.br', '(19) 3232-4455',
    TRUE
FROM tenant t
WHERE t.slug = 'distribuidora-sao-joao'
  AND NOT EXISTS (
    SELECT 1 FROM empresa WHERE cod_tenant = t.cod_tenant AND cod_empresa = 2
  );

-- ------------------------------------------------------------
-- 4. Usuários
-- ------------------------------------------------------------
-- Senha padrão: "visionflow123" (hash bcrypt)
-- ------------------------------------------------------------
INSERT INTO usuario (cod_tenant, email, senha_hash, nome, telefone, cpf, tipo, ativo)
SELECT t.cod_tenant,
       'admin@saajoao.com.br',
       '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyfBGzY0e6m5G2',
       'Maria Aparecida Santos',
       '(11) 99876-5432',
       '123.456.789-00',
       'admin', TRUE
FROM tenant t
WHERE t.slug = 'distribuidora-sao-joao'
  AND NOT EXISTS (
    SELECT 1 FROM usuario WHERE email = 'admin@saajoao.com.br'
  );

INSERT INTO usuario (cod_tenant, email, senha_hash, nome, telefone, cpf, tipo, ativo)
SELECT t.cod_tenant,
       'joao.silva@saajoao.com.br',
       '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyfBGzY0e6m5G2',
       'João Carlos Silva',
       '(11) 98765-4321',
       '234.567.890-11',
       'vendedor', TRUE
FROM tenant t
WHERE t.slug = 'distribuidora-sao-joao'
  AND NOT EXISTS (
    SELECT 1 FROM usuario WHERE email = 'joao.silva@saajoao.com.br'
  );

INSERT INTO usuario (cod_tenant, email, senha_hash, nome, telefone, cpf, tipo, ativo)
SELECT t.cod_tenant,
       'ana.costa@saajoao.com.br',
       '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyfBGzY0e6m5G2',
       'Ana Paula Costa',
       '(11) 97654-3210',
       '345.678.901-22',
       'vendedor', TRUE
FROM tenant t
WHERE t.slug = 'distribuidora-sao-joao'
  AND NOT EXISTS (
    SELECT 1 FROM usuario WHERE email = 'ana.costa@saajoao.com.br'
  );

INSERT INTO usuario (cod_tenant, email, senha_hash, nome, telefone, cpf, tipo, ativo)
SELECT t.cod_tenant,
       'carlos.oliveira@saajoao.com.br',
       '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyfBGzY0e6m5G2',
       'Carlos Eduardo Oliveira',
       '(19) 96543-2109',
       '456.789.012-33',
       'vendedor', TRUE
FROM tenant t
WHERE t.slug = 'distribuidora-sao-joao'
  AND NOT EXISTS (
    SELECT 1 FROM usuario WHERE email = 'carlos.oliveira@saajoao.com.br'
  );

-- ------------------------------------------------------------
-- 5. Vínculos usuário ↔ empresa
-- ------------------------------------------------------------
-- Maria (admin) → Matriz
INSERT INTO usuario_empresa (cod_usuario, cod_tenant, cod_empresa, empresa_padrao)
SELECT u.cod_usuario, u.cod_tenant, 1, TRUE
FROM usuario u
WHERE u.email = 'admin@saajoao.com.br'
  AND NOT EXISTS (
    SELECT 1 FROM usuario_empresa
    WHERE cod_usuario = u.cod_usuario AND cod_tenant = u.cod_tenant AND cod_empresa = 1
  );

-- Maria (admin) → Filial Campinas
INSERT INTO usuario_empresa (cod_usuario, cod_tenant, cod_empresa, empresa_padrao)
SELECT u.cod_usuario, u.cod_tenant, 2, FALSE
FROM usuario u
WHERE u.email = 'admin@saajoao.com.br'
  AND NOT EXISTS (
    SELECT 1 FROM usuario_empresa
    WHERE cod_usuario = u.cod_usuario AND cod_tenant = u.cod_tenant AND cod_empresa = 2
  );

-- João (vendedor) → Matriz
INSERT INTO usuario_empresa (cod_usuario, cod_tenant, cod_empresa, empresa_padrao)
SELECT u.cod_usuario, u.cod_tenant, 1, TRUE
FROM usuario u
WHERE u.email = 'joao.silva@saajoao.com.br'
  AND NOT EXISTS (
    SELECT 1 FROM usuario_empresa
    WHERE cod_usuario = u.cod_usuario AND cod_tenant = u.cod_tenant AND cod_empresa = 1
  );

-- Ana (vendedor) → Matriz
INSERT INTO usuario_empresa (cod_usuario, cod_tenant, cod_empresa, empresa_padrao)
SELECT u.cod_usuario, u.cod_tenant, 1, TRUE
FROM usuario u
WHERE u.email = 'ana.costa@saajoao.com.br'
  AND NOT EXISTS (
    SELECT 1 FROM usuario_empresa
    WHERE cod_usuario = u.cod_usuario AND cod_tenant = u.cod_tenant AND cod_empresa = 1
  );

-- Carlos (vendedor) → Filial Campinas
INSERT INTO usuario_empresa (cod_usuario, cod_tenant, cod_empresa, empresa_padrao)
SELECT u.cod_usuario, u.cod_tenant, 2, TRUE
FROM usuario u
WHERE u.email = 'carlos.oliveira@saajoao.com.br'
  AND NOT EXISTS (
    SELECT 1 FROM usuario_empresa
    WHERE cod_usuario = u.cod_usuario AND cod_tenant = u.cod_tenant AND cod_empresa = 2
  );

COMMIT;

-- ============================================================
-- Verificação
-- ============================================================
DO $$
DECLARE
    v_tenant  INTEGER;
    v_nome    TEXT;
    v_emp     INTEGER;
    v_usr     INTEGER;
BEGIN
    SELECT cod_tenant, nome INTO v_tenant, v_nome
    FROM tenant WHERE slug = 'distribuidora-sao-joao';

    SELECT COUNT(*) INTO v_emp FROM empresa WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_usr FROM usuario WHERE cod_tenant = v_tenant;

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE '✅ Base criada com sucesso!';
    RAISE NOTICE 'Tenant ID: % (%)', v_tenant, v_nome;
    RAISE NOTICE 'Empresas: %', v_emp;
    RAISE NOTICE 'Usuarios: %', v_usr;
    RAISE NOTICE '============================================';
END $$;