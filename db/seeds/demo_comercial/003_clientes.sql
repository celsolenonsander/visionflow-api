-- ============================================================
-- SEED — Demo Comercial — Clientes
-- ============================================================
-- Popula: 30 clientes (bares, restaurantes, mercados, padarias, etc)
--         com endereços, contatos e vínculos completos.
-- Idempotente: usa WHERE NOT EXISTS
-- RLS: define contexto antes dos INSERTs e SELECTs
-- ============================================================

BEGIN;

DO $$
DECLARE
    v_tenant INTEGER;
    v_emp    INTEGER := 1;
    v_inseridos INTEGER := 0;
BEGIN
    -- Pega o tenant
    SELECT cod_tenant INTO v_tenant
    FROM tenant WHERE slug = 'distribuidora-sao-joao';

    IF v_tenant IS NULL THEN
        RAISE EXCEPTION 'Tenant "distribuidora-sao-joao" não encontrado.';
    END IF;

    -- ⚠️ RLS: define contexto
    PERFORM set_config('app.cod_tenant', v_tenant::TEXT, true);
    PERFORM set_config('app.cod_empresa', v_emp::TEXT, true);

    RAISE NOTICE 'Populando clientes para tenant % / empresa %', v_tenant, v_emp;

    -- ========================================================
    -- CLIENTES
    -- ========================================================
    INSERT INTO cliente (
        cod_tenant, cod_empresa, codigo_erp, prospect,
        tipo_pessoa, cnpj_cpf, inscricao_estadual_rg,
        nome_razao_social, nome_fantasia,
        -- endereço principal
        identificacao_endereco, cep, tipo_logradouro, logradouro,
        numero_endereco, complemento, bairro, cidade, estado,
        -- contato
        telefone1, celular, nome_contato_comprador, email_contato_comprador,
        -- vínculos
        codigo_erp_ramo_atividade, descricao_ramo_atividade,
        codigo_erp_grupo_cliente, descricao_grupo_cliente,
        codigo_erp_tabela_preco,
        codigo_erp_condicao_pagamento,
        codigo_erp_forma_pagamento,
        -- financeiro
        percentual_desconto_automatico, limite_credito_total,
        tipo_bloqueio_para_venda, descricao_aviso_bloqueio_venda,
        -- status
        ativo
    )
    SELECT
        v_tenant, v_emp, x.codigo_erp, FALSE,
        x.tipo_pessoa, x.cnpj_cpf, x.ie,
        x.razao, x.fantasia,
        'PRINCIPAL', x.cep, 'Rua', x.logradouro,
        x.numero, x.complemento, x.bairro, x.cidade, x.estado,
        x.telefone, x.celular, x.contato_nome, x.contato_email,
        x.ramo, x.ramo_desc,
        x.grupo, x.grupo_desc,
        x.tabela,
        x.condicao,
        x.forma,
        x.desconto, x.limite,
        x.risco, x.risco_msg,
        TRUE
    FROM (VALUES
        -- codigo_erp, tipo, cnpj_cpf, ie, razao, fantasia,
        -- cep, logradouro, numero, complemento, bairro, cidade, estado,
        -- telefone, celular, contato_nome, contato_email,
        -- ramo, ramo_desc, grupo, grupo_desc, tabela, condicao, forma,
        -- desconto, limite, risco, risco_msg
        ('000001', 'J', '11.111.111/0001-11', '111.111.111.111',
         'Bar do Zé LTDA', 'Bar do Zé',
         '01310-100', 'Av. Paulista', '1000', '',
         'Bela Vista', 'São Paulo', 'SP',
         '(11) 3111-1111', '(11) 91111-1111', 'José Carlos', 'ze@bardoze.com.br',
         'R01', 'Bar', 'B', 'Cliente Médio (B)', '1', '03', '15',
         0, 5000.00, 'L', ''),

        ('000002', 'J', '22.222.222/0001-22', '222.222.222.222',
         'Restaurante Bom Sabor LTDA', 'Bom Sabor',
         '04543-011', 'Rua Funchal', '500', 'Loja 2',
         'Vila Olímpia', 'São Paulo', 'SP',
         '(11) 3222-2222', '(11) 92222-2222', 'Marina Silva', 'marina@bomsabor.com.br',
         'R02', 'Restaurante', 'A', 'Cliente Premium (A)', '2', '04', '15',
         5, 15000.00, 'L', ''),

        ('000003', 'J', '33.333.333/0001-33', '333.333.333.333',
         'Supermercado Central LTDA', 'Central',
         '01310-200', 'Av. Brigadeiro Luís Antônio', '2500', '',
         'Jardim Paulista', 'São Paulo', 'SP',
         '(11) 3333-3333', '(11) 93333-3333', 'Roberto Alves', 'compras@central.com.br',
         'R03', 'Supermercado', 'A', 'Cliente Premium (A)', '2', '04', '15',
         8, 30000.00, 'L', ''),

        ('000004', 'J', '44.444.444/0001-44', '444.444.444.444',
         'Padaria Pão Quente ME', 'Pão Quente',
         '05407-002', 'Rua Cardeal Arcoverde', '1500', '',
         'Pinheiros', 'São Paulo', 'SP',
         '(11) 3444-4444', '(11) 94444-4444', 'Antônio Pereira', 'antonio@paoquente.com.br',
         'R04', 'Padaria', 'C', 'Cliente Pequeno (C)', '1', '02', '01',
         0, 3000.00, 'L', ''),

        ('000005', 'J', '55.555.555/0001-55', '555.555.555.555',
         'Loja de Conveniência 24h LTDA', 'Conv 24h',
         '04094-050', 'Av. Ibirapuera', '3000', '',
         'Indianópolis', 'São Paulo', 'SP',
         '(11) 3555-5555', '(11) 95555-5555', 'Patrícia Souza', 'patricia@conv24h.com.br',
         'R05', 'Loja de Conveniência', 'B', 'Cliente Médio (B)', '1', '03', '17',
         0, 8000.00, 'L', ''),

        ('000006', 'J', '66.666.666/0001-66', '666.666.666.666',
         'Hotel Estrela do Sul LTDA', 'Hotel Estrela',
         '01310-300', 'Rua Augusta', '2000', '',
         'Consolação', 'São Paulo', 'SP',
         '(11) 3666-6666', '(11) 96666-6666', 'Fernando Lima', 'compras@estreladosul.com.br',
         'R07', 'Hotel / Pousada', 'A', 'Cliente Premium (A)', '2', '04', '15',
         5, 20000.00, 'L', ''),

        ('000007', 'J', '77.777.777/0001-77', '777.777.777.777',
         'Espeto do Gaúcho LTDA', 'Espeto do Gaúcho',
         '03164-000', 'Rua Azevedo Soares', '800', '',
         'Tatuapé', 'São Paulo', 'SP',
         '(11) 3777-7777', '(11) 97777-7777', 'Ricardo Mendes', 'ricardo@espetogaucho.com.br',
         'R01', 'Bar', 'B', 'Cliente Médio (B)', '1', '03', '17',
         0, 6000.00, 'L', ''),

        ('000008', 'J', '88.888.888/0001-88', '888.888.888.888',
         'Cantina da Nonna LTDA', 'Cantina da Nonna',
         '05416-000', 'Rua dos Pinheiros', '1200', '',
         'Pinheiros', 'São Paulo', 'SP',
         '(11) 3888-8888', '(11) 98888-8888', 'Giovanna Rossi', 'giovanna@cantinadonna.com.br',
         'R02', 'Restaurante', 'A', 'Cliente Premium (A)', '2', '04', '15',
         5, 12000.00, 'L', ''),

        ('000009', 'J', '99.999.999/0001-99', '999.999.999.999',
         'Mercado Bom Preço ME', 'Bom Preço',
         '02011-000', 'Rua Voluntários da Pátria', '600', '',
         'Santana', 'São Paulo', 'SP',
         '(11) 3999-9999', '(11) 99999-9999', 'Sandra Rocha', 'sandra@bompreco.com.br',
         'R03', 'Supermercado', 'B', 'Cliente Médio (B)', '1', '03', '15',
         0, 10000.00, 'L', ''),

        ('000010', 'J', '10.101.010/0001-10', '101.101.101.101',
         'Adega Vinhos & Cia LTDA', 'Vinhos & Cia',
         '01310-400', 'Alameda Santos', '1500', 'Loja 5',
         'Cerqueira César', 'São Paulo', 'SP',
         '(11) 3101-0101', '(11) 91010-1010', 'Cláudio Fonseca', 'claudio@vinhosecia.com.br',
         'R01', 'Bar', 'A', 'Cliente Premium (A)', '2', '04', '15',
         5, 18000.00, 'L', ''),

        ('000011', 'J', '11.121.212/0001-11', '121.212.121.212',
         'Eventos & Buffet Festa Feliz LTDA', 'Festa Feliz',
         '04563-020', 'Rua Gomes de Carvalho', '800', '',
         'Vila Olímpia', 'São Paulo', 'SP',
         '(11) 3112-1212', '(11) 91212-1212', 'Beatriz Almeida', 'bia@festafeliz.com.br',
         'R08', 'Eventos / Buffet', 'A', 'Cliente Premium (A)', '2', '03', '15',
         10, 25000.00, 'L', ''),

        ('000012', 'J', '13.141.414/0001-13', '141.414.141.414',
         'Churrascaria Gaúcha LTDA', 'Gaúcha',
         '01415-000', 'Rua Haddock Lobo', '1500', '',
         'Cerqueira César', 'São Paulo', 'SP',
         '(11) 3113-1414', '(11) 91314-1414', 'Eduardo Nunes', 'eduardo@gaucha.com.br',
         'R02', 'Restaurante', 'A', 'Cliente Premium (A)', '2', '04', '15',
         5, 20000.00, 'L', ''),

        ('000013', 'J', '15.161.616/0001-15', '161.616.161.616',
         'Restaurante Vegetariano Verde Vida ME', 'Verde Vida',
         '05425-070', 'Rua Teodoro Sampaio', '1800', '',
         'Pinheiros', 'São Paulo', 'SP',
         '(11) 3115-1616', '(11) 91516-1616', 'Juliana Martins', 'juliana@verdevida.com.br',
         'R02', 'Restaurante', 'B', 'Cliente Médio (B)', '1', '03', '17',
         0, 7000.00, 'L', ''),

        ('000014', 'J', '17.181.818/0001-17', '181.818.181.818',
         'Empório dos Pães LTDA', 'Empório dos Pães',
         '05407-000', 'Rua dos Pinheiros', '800', '',
         'Pinheiros', 'São Paulo', 'SP',
         '(11) 3117-1818', '(11) 91718-1818', 'Marcos Vieira', 'marcos@emporiodospaes.com.br',
         'R04', 'Padaria', 'B', 'Cliente Médio (B)', '1', '03', '17',
         0, 5000.00, 'L', ''),

        ('000015', 'J', '19.202.020/0001-19', '202.020.202.020',
         'Bar do Beco LTDA', 'Bar do Beco',
         '05424-020', 'Rua Artur de Azevedo', '500', '',
         'Pinheiros', 'São Paulo', 'SP',
         '(11) 3119-2020', '(11) 91920-2020', 'Thiago Lopes', 'thiago@bardobeco.com.br',
         'R01', 'Bar', 'C', 'Cliente Pequeno (C)', '1', '02', '01',
         0, 3000.00, 'L', ''),

        ('000016', 'J', '21.222.222/0001-21', '222.222.222.222',
         'Restaurante Sabor Caseiro ME', 'Sabor Caseiro',
         '03310-000', 'Rua Antônio de Barros', '1000', '',
         'Tatuapé', 'São Paulo', 'SP',
         '(11) 3121-2222', '(11) 92122-2222', 'Luciana Ferreira', 'luciana@saborcaseiro.com.br',
         'R02', 'Restaurante', 'C', 'Cliente Pequeno (C)', '1', '02', '01',
         0, 4000.00, 'L', ''),

        ('000017', 'J', '23.242.424/0001-23', '242.424.242.424',
         'Supermercado do Bairro LTDA', 'Mercado do Bairro',
         '04829-000', 'Av. Interlagos', '3000', '',
         'Interlagos', 'São Paulo', 'SP',
         '(11) 3123-2424', '(11) 92324-2424', 'Paulo Henrique', 'paulo@mercadodobairro.com.br',
         'R03', 'Supermercado', 'B', 'Cliente Médio (B)', '1', '03', '15',
         0, 9000.00, 'L', ''),

        ('000018', 'J', '25.262.626/0001-25', '262.626.262.626',
         'Pizzaria Bella Itália LTDA', 'Bella Itália',
         '05433-000', 'Rua dos Três Irmãos', '1500', '',
         'Vila Progredior', 'São Paulo', 'SP',
         '(11) 3125-2626', '(11) 92526-2626', 'Alessandro Moretti', 'alessandro@bellaitalia.com.br',
         'R02', 'Restaurante', 'B', 'Cliente Médio (B)', '1', '03', '17',
         0, 8000.00, 'L', ''),

        ('000019', 'J', '27.282.828/0001-27', '282.828.282.828',
         'Lanchonete do Ponto ME', 'Lanchonete do Ponto',
         '01310-500', 'Av. Paulista', '900', 'Box 5',
         'Bela Vista', 'São Paulo', 'SP',
         '(11) 3127-2828', '(11) 92728-2828', 'Carla Pereira', 'carla@lanchonetedoponto.com.br',
         'R02', 'Restaurante', 'C', 'Cliente Pequeno (C)', '1', '02', '01',
         0, 2500.00, 'L', ''),

        ('000020', 'J', '29.303.030/0001-29', '303.030.303.030',
         'Mercearia São Jorge ME', 'Mercearia São Jorge',
         '08010-000', 'Rua Serra de Japi', '500', '',
         'Tatuapé', 'São Paulo', 'SP',
         '(11) 3129-3030', '(11) 92930-3030', 'Jorge Rodrigues', 'jorge@merceariasaojorge.com.br',
         'R03', 'Supermercado', 'C', 'Cliente Pequeno (C)', '1', '02', '01',
         0, 3500.00, 'L', ''),

        ('000021', 'J', '31.323.232/0001-31', '323.232.323.232',
         'Bar do Futebol LTDA', 'Bar do Futebol',
         '05307-000', 'Av. Escola Politécnica', '2000', '',
         'Jaguaré', 'São Paulo', 'SP',
         '(11) 3131-3232', '(11) 93132-3232', 'Rogério Cunha', 'rogerio@bardofutebol.com.br',
         'R01', 'Bar', 'C', 'Cliente Pequeno (C)', '1', '02', '01',
         0, 3000.00, 'L', ''),

        ('000022', 'J', '33.343.434/0001-33', '343.434.343.434',
         'Doceria Amor aos Doces ME', 'Amor aos Doces',
         '05407-001', 'Rua Cardeal Arcoverde', '2000', '',
         'Pinheiros', 'São Paulo', 'SP',
         '(11) 3133-3434', '(11) 93334-3434', 'Fernanda Costa', 'fernanda@amoraosdoces.com.br',
         'R04', 'Padaria', 'B', 'Cliente Médio (B)', '1', '03', '17',
         0, 4500.00, 'L', ''),

        ('000023', 'J', '35.363.636/0001-35', '363.636.363.636',
         'Bistrô Parisiense LTDA', 'Bistrô Paris',
         '01452-001', 'Rua Oscar Freire', '1500', '',
         'Jardim Paulista', 'São Paulo', 'SP',
         '(11) 3135-3636', '(11) 93536-3636', 'Camila Duarte', 'camila@bistroparis.com.br',
         'R02', 'Restaurante', 'A', 'Cliente Premium (A)', '2', '04', '15',
         5, 15000.00, 'L', ''),

        ('000024', 'J', '37.383.838/0001-37', '383.838.383.838',
         'Barzinho do Beco ME', 'Barzinho do Beco',
         '03164-001', 'Rua Azevedo Soares', '100', '',
         'Tatuapé', 'São Paulo', 'SP',
         '(11) 3137-3838', '(11) 93738-3838', 'Vinícius Barbosa', 'vinicius@barzinhodobeco.com.br',
         'R01', 'Bar', 'C', 'Cliente Pequeno (C)', '1', '02', '01',
         0, 2500.00, 'L', ''),

        ('000025', 'J', '39.404.040/0001-39', '404.040.404.040',
         'Restaurante Italiano La Famiglia LTDA', 'La Famiglia',
         '01415-001', 'Rua Haddock Lobo', '2000', '',
         'Cerqueira César', 'São Paulo', 'SP',
         '(11) 3139-4040', '(11) 93940-4040', 'Sofia Conti', 'sofia@lafamiglia.com.br',
         'R02', 'Restaurante', 'A', 'Cliente Premium (A)', '2', '04', '15',
         5, 18000.00, 'L', ''),

        ('000026', 'J', '41.424.242/0001-41', '424.242.424.242',
         'Mercadinho da Esquina ME', 'Mercadinho da Esquina',
         '08010-001', 'Rua Serra de Japi', '800', '',
         'Tatuapé', 'São Paulo', 'SP',
         '(11) 3141-4242', '(11) 94142-4242', 'Marcelo Alves', 'marcelo@mercadinho.com.br',
         'R03', 'Supermercado', 'C', 'Cliente Pequeno (C)', '1', '02', '01',
         0, 4000.00, 'L', ''),

        ('000027', 'J', '43.444.444/0001-43', '444.444.444.444',
         'Choperia da Praça LTDA', 'Choperia da Praça',
         '05307-001', 'Av. Escola Politécnica', '3000', '',
         'Jaguaré', 'São Paulo', 'SP',
         '(11) 3143-4444', '(11) 94344-4444', 'André Carvalho', 'andre@choperiadapraca.com.br',
         'R01', 'Bar', 'B', 'Cliente Médio (B)', '1', '03', '17',
         0, 7000.00, 'L', ''),

        ('000028', 'J', '45.464.646/0001-45', '464.646.464.646',
         'Restaurante Japonês Sakura LTDA', 'Sakura',
         '01452-002', 'Rua Oscar Freire', '2500', '',
         'Jardim Paulista', 'São Paulo', 'SP',
         '(11) 3145-4646', '(11) 94546-4646', 'Yuki Tanaka', 'yuki@sakura.com.br',
         'R02', 'Restaurante', 'A', 'Cliente Premium (A)', '2', '04', '15',
         5, 22000.00, 'L', ''),

        ('000029', 'J', '47.484.848/0001-47', '484.848.484.848',
         'Bar do Atleticano LTDA', 'Bar do Atleticano',
         '03164-002', 'Rua Azevedo Soares', '400', '',
         'Tatuapé', 'São Paulo', 'SP',
         '(11) 3147-4848', '(11) 94748-4848', 'Fábio Gomes', 'fabio@bardoataleticano.com.br',
         'R01', 'Bar', 'C', 'Cliente Pequeno (C)', '1', '02', '01',
         0, 3500.00, 'L', ''),

        ('000030', 'J', '49.505.050/0001-49', '505.050.505.050',
         'Conveniência Express 24h LTDA', 'Express 24h',
         '04094-051', 'Av. Ibirapuera', '4000', '',
         'Indianópolis', 'São Paulo', 'SP',
         '(11) 3149-5050', '(11) 94950-5050', 'Renata Lopes', 'renata@express24h.com.br',
         'R05', 'Loja de Conveniência', 'B', 'Cliente Médio (B)', '1', '03', '17',
         0, 6000.00, 'L', '')
    ) AS x(
        codigo_erp, tipo_pessoa, cnpj_cpf, ie, razao, fantasia,
        cep, logradouro, numero, complemento, bairro, cidade, estado,
        telefone, celular, contato_nome, contato_email,
        ramo, ramo_desc, grupo, grupo_desc, tabela, condicao, forma,
        desconto, limite, risco, risco_msg
    )
    WHERE NOT EXISTS (
        SELECT 1 FROM cliente
        WHERE cod_tenant = v_tenant AND cod_empresa = v_emp AND codigo_erp = x.codigo_erp
    );

    GET DIAGNOSTICS v_inseridos = ROW_COUNT;

    RAISE NOTICE '✅ % clientes inseridos!', v_inseridos;

END $$;

COMMIT;

-- ============================================================
-- Verificação (com RLS configurado)
-- ============================================================
DO $$
DECLARE
    v_tenant INTEGER;
    v_total  INTEGER;
    v_ativos INTEGER;
    v_grupo_a INTEGER;
    v_grupo_b INTEGER;
    v_grupo_c INTEGER;
BEGIN
    SELECT cod_tenant INTO v_tenant FROM tenant WHERE slug = 'distribuidora-sao-joao';

    -- ⚠️ RLS: define contexto para poder LER
    PERFORM set_config('app.cod_tenant', v_tenant::TEXT, true);
    PERFORM set_config('app.cod_empresa', '1', true);

    SELECT COUNT(*) INTO v_total   FROM cliente WHERE cod_tenant = v_tenant;
    SELECT COUNT(*) INTO v_ativos  FROM cliente WHERE cod_tenant = v_tenant AND ativo = TRUE;
    SELECT COUNT(*) INTO v_grupo_a FROM cliente WHERE cod_tenant = v_tenant AND codigo_erp_grupo_cliente = 'A';
    SELECT COUNT(*) INTO v_grupo_b FROM cliente WHERE cod_tenant = v_tenant AND codigo_erp_grupo_cliente = 'B';
    SELECT COUNT(*) INTO v_grupo_c FROM cliente WHERE cod_tenant = v_tenant AND codigo_erp_grupo_cliente = 'C';

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE '✅ Clientes — Resumo';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Tenant:                  %', v_tenant;
    RAISE NOTICE 'Total de clientes:       %', v_total;
    RAISE NOTICE 'Ativos:                  %', v_ativos;
    RAISE NOTICE 'Grupo A (Premium):       %', v_grupo_a;
    RAISE NOTICE 'Grupo B (Médio):         %', v_grupo_b;
    RAISE NOTICE 'Grupo C (Pequeno):       %', v_grupo_c;
    RAISE NOTICE '============================================';
END $$;