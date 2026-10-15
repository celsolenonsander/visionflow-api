--
-- PostgreSQL database dump
--

\restrict B7pCuJmFY92L9jfcpLZ6ZgE4EpOK5ISE2ecnYXeSTuiXSBzJnkvC3m7vGdoOwFG

-- Dumped from database version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: epare
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO epare;

--
-- Name: fn_atualiza_dt_alteracao(); Type: FUNCTION; Schema: public; Owner: epare
--

CREATE FUNCTION public.fn_atualiza_dt_alteracao() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.dt_alteracao := NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_atualiza_dt_alteracao() OWNER TO epare;

--
-- Name: fn_current_empresa(); Type: FUNCTION; Schema: public; Owner: epare
--

CREATE FUNCTION public.fn_current_empresa() RETURNS integer
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    RETURN NULLIF(current_setting('app.cod_empresa', true), '')::INTEGER;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.fn_current_empresa() OWNER TO epare;

--
-- Name: FUNCTION fn_current_empresa(); Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON FUNCTION public.fn_current_empresa() IS 'Retorna cod_empresa da sessão (SET LOCAL app.cod_empresa)';


--
-- Name: fn_current_tenant(); Type: FUNCTION; Schema: public; Owner: epare
--

CREATE FUNCTION public.fn_current_tenant() RETURNS integer
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    RETURN NULLIF(current_setting('app.cod_tenant', true), '')::INTEGER;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.fn_current_tenant() OWNER TO epare;

--
-- Name: FUNCTION fn_current_tenant(); Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON FUNCTION public.fn_current_tenant() IS 'Retorna cod_tenant da sessão (SET LOCAL app.cod_tenant)';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: categoria_item; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.categoria_item (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    descricao character varying(100),
    codigo_erp_pai character varying(20),
    ativo boolean DEFAULT true,
    data_bloqueio date,
    motivo_bloqueio character varying(200),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.categoria_item FORCE ROW LEVEL SECURITY;


ALTER TABLE public.categoria_item OWNER TO epare;

--
-- Name: TABLE categoria_item; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.categoria_item IS 'Categorias de item (grupo, subgrupo, etc) — hierárquico';


--
-- Name: COLUMN categoria_item.codigo_erp_pai; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.categoria_item.codigo_erp_pai IS 'Código ERP do pai (para hierarquia)';


--
-- Name: categoria_item_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.categoria_item_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categoria_item_codigo_seq OWNER TO epare;

--
-- Name: categoria_item_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.categoria_item_codigo_seq OWNED BY public.categoria_item.codigo;


--
-- Name: classificacao_fiscal; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.classificacao_fiscal (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    descricao character varying(100),
    classificacao_fiscal character varying(20),
    percentual_ipi numeric(15,4) DEFAULT 0,
    ativo boolean DEFAULT true,
    data_bloqueio date,
    motivo_bloqueio character varying(200),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.classificacao_fiscal FORCE ROW LEVEL SECURITY;


ALTER TABLE public.classificacao_fiscal OWNER TO epare;

--
-- Name: TABLE classificacao_fiscal; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.classificacao_fiscal IS 'Classificação Fiscal (NCM, CST, etc)';


--
-- Name: classificacao_fiscal_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.classificacao_fiscal_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.classificacao_fiscal_codigo_seq OWNER TO epare;

--
-- Name: classificacao_fiscal_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.classificacao_fiscal_codigo_seq OWNED BY public.classificacao_fiscal.codigo;


--
-- Name: cliente; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.cliente (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    prospect boolean DEFAULT false,
    tipo_pessoa character(1),
    cnpj_cpf character varying(20),
    inscricao_estadual_rg character varying(20),
    nome_razao_social character varying(100) NOT NULL,
    nome_fantasia character varying(100),
    identificacao_endereco character varying(50),
    cep character varying(10),
    tipo_logradouro character varying(50),
    logradouro character varying(100),
    numero_endereco character varying(20),
    complemento character varying(100),
    bairro character varying(100),
    cidade character varying(100),
    estado character(2),
    regiao character varying(100),
    ponto_referencia character varying(200),
    restricoes_horarios character varying(200),
    telefone1 character varying(20),
    telefone2 character varying(20),
    celular character varying(20),
    fax character varying(20),
    radio character varying(20),
    nome_contato_comprador character varying(100),
    email_contato_comprador character varying(100),
    telefone_contato_comprador character varying(20),
    nome_contato_faturamento character varying(100),
    email_contato_faturamento character varying(100),
    telefone_contato_faturamento character varying(20),
    codigo_erp_ramo_atividade character varying(20),
    descricao_ramo_atividade character varying(100),
    codigo_erp_grupo_cliente character varying(20),
    descricao_grupo_cliente character varying(100),
    codigo_erp_transportadora character varying(20),
    cnpj_cpf_transportadora character varying(20),
    codigo_erp_tabela_preco character varying(20),
    codigo_erp_como_conheceu_empresa character varying(20),
    descricao_como_conheceu_empresa character varying(100),
    codigo_erp_condicao_pagamento character varying(20),
    codigo_erp_forma_pagamento character varying(20),
    codigo_erp_tipo_venda character varying(20),
    codigo_erp_tipo_frete character varying(20),
    percentual_desconto_automatico numeric(15,4) DEFAULT 0,
    limite_credito_total numeric(15,4) DEFAULT 0,
    quantidade_dias_titulo_vencido integer DEFAULT 0,
    analisa_valor_minimo_parcela boolean DEFAULT false,
    tipo_bloqueio_para_venda character varying(20),
    descricao_aviso_bloqueio_venda character varying(200),
    data_inclusao date,
    anotacao_erp text,
    ativo boolean DEFAULT true,
    data_bloqueio date,
    motivo_bloqueio character varying(200),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now(),
    CONSTRAINT ck_cliente_tipo CHECK (((tipo_pessoa = ANY (ARRAY['F'::bpchar, 'J'::bpchar])) OR (tipo_pessoa IS NULL)))
);

ALTER TABLE ONLY public.cliente FORCE ROW LEVEL SECURITY;


ALTER TABLE public.cliente OWNER TO epare;

--
-- Name: TABLE cliente; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.cliente IS 'Cadastro de Cliente (destinatário final)';


--
-- Name: COLUMN cliente.prospect; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.cliente.prospect IS 'TRUE = ainda é prospect (não é cliente efetivo)';


--
-- Name: COLUMN cliente.anotacao_erp; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.cliente.anotacao_erp IS 'Anotações do ERP que o app deve mostrar';


--
-- Name: cliente_campo_adicional; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.cliente_campo_adicional (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_cliente character varying(20) NOT NULL,
    field character varying(50) NOT NULL,
    value character varying(500),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.cliente_campo_adicional FORCE ROW LEVEL SECURITY;


ALTER TABLE public.cliente_campo_adicional OWNER TO epare;

--
-- Name: TABLE cliente_campo_adicional; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.cliente_campo_adicional IS 'Campos adicionais personalizados do cliente';


--
-- Name: cliente_campo_adicional_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.cliente_campo_adicional_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cliente_campo_adicional_codigo_seq OWNER TO epare;

--
-- Name: cliente_campo_adicional_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.cliente_campo_adicional_codigo_seq OWNED BY public.cliente_campo_adicional.codigo;


--
-- Name: cliente_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.cliente_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cliente_codigo_seq OWNER TO epare;

--
-- Name: cliente_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.cliente_codigo_seq OWNED BY public.cliente.codigo;


--
-- Name: cliente_condicao_pagamento; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.cliente_condicao_pagamento (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_cliente character varying(20) NOT NULL,
    codigo_erp_condicao_pagamento character varying(20) NOT NULL,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.cliente_condicao_pagamento FORCE ROW LEVEL SECURITY;


ALTER TABLE public.cliente_condicao_pagamento OWNER TO epare;

--
-- Name: TABLE cliente_condicao_pagamento; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.cliente_condicao_pagamento IS 'Condições de pagamento permitidas ao cliente (N:N)';


--
-- Name: cliente_condicao_pagamento_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.cliente_condicao_pagamento_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cliente_condicao_pagamento_codigo_seq OWNER TO epare;

--
-- Name: cliente_condicao_pagamento_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.cliente_condicao_pagamento_codigo_seq OWNED BY public.cliente_condicao_pagamento.codigo;


--
-- Name: cliente_conta_receber; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.cliente_conta_receber (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    codigo_erp_cliente character varying(20) NOT NULL,
    tipo_pessoa character(1),
    cnpj_cpf character varying(20),
    codigo_erp_unidade_negocio character varying(20),
    titulo_serie character varying(20),
    titulo_especie_documento character varying(50),
    titulo_numero_documento character varying(50),
    titulo_numero_parcela character varying(20),
    data_emissao date,
    data_vencimento date,
    valor_total numeric(15,4) DEFAULT 0,
    valor_total_aberto numeric(15,4) DEFAULT 0,
    data_liquidacao date,
    campo_auxiliar01 character varying(50),
    campo_auxiliar02 character varying(50),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.cliente_conta_receber FORCE ROW LEVEL SECURITY;


ALTER TABLE public.cliente_conta_receber OWNER TO epare;

--
-- Name: TABLE cliente_conta_receber; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.cliente_conta_receber IS 'Títulos a receber do cliente (em aberto)';


--
-- Name: cliente_conta_receber_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.cliente_conta_receber_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cliente_conta_receber_codigo_seq OWNER TO epare;

--
-- Name: cliente_conta_receber_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.cliente_conta_receber_codigo_seq OWNED BY public.cliente_conta_receber.codigo;


--
-- Name: cliente_contato; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.cliente_contato (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_cliente character varying(20) NOT NULL,
    identificacao_contato character varying(100),
    nome_apelido character varying(100),
    sexo character varying(3),
    data_nascimento date,
    departamento_trabalha character varying(100),
    cargo_funcao_exerce character varying(100),
    cpf character varying(20),
    telefone character varying(20),
    ramal character varying(10),
    celular character varying(20),
    radio character varying(20),
    email character varying(100),
    receber_email_pedido_venda boolean DEFAULT true,
    receber_email_nota_fiscal_nfe boolean DEFAULT false,
    receber_email_boleto boolean DEFAULT false,
    receber_email_marketing boolean DEFAULT false,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.cliente_contato FORCE ROW LEVEL SECURITY;


ALTER TABLE public.cliente_contato OWNER TO epare;

--
-- Name: TABLE cliente_contato; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.cliente_contato IS 'Contatos do cliente';


--
-- Name: cliente_contato_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.cliente_contato_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cliente_contato_codigo_seq OWNER TO epare;

--
-- Name: cliente_contato_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.cliente_contato_codigo_seq OWNED BY public.cliente_contato.codigo;


--
-- Name: cliente_endereco_adicional; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.cliente_endereco_adicional (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_cliente character varying(20) NOT NULL,
    nosso_codigo_endereco character varying(20),
    codigo_erp_endereco character varying(20) NOT NULL,
    identificacao_endereco character varying(50),
    cep character varying(10),
    tipo_logradouro character varying(50),
    logradouro character varying(100),
    endereco character varying(100),
    numero_endereco character varying(20),
    complemento_endereco character varying(100),
    bairro character varying(100),
    cidade character varying(100),
    estado character(2),
    regiao character varying(100),
    ponto_referencia character varying(200),
    restricoes_horarios character varying(200),
    tipo_endereco character(1),
    endereco_padrao boolean DEFAULT false,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now(),
    CONSTRAINT ck_cli_end_tipo CHECK (((tipo_endereco = ANY (ARRAY['C'::bpchar, 'E'::bpchar, 'A'::bpchar])) OR (tipo_endereco IS NULL)))
);

ALTER TABLE ONLY public.cliente_endereco_adicional FORCE ROW LEVEL SECURITY;


ALTER TABLE public.cliente_endereco_adicional OWNER TO epare;

--
-- Name: TABLE cliente_endereco_adicional; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.cliente_endereco_adicional IS 'Endereços adicionais do cliente (entrega, cobrança, NF)';


--
-- Name: COLUMN cliente_endereco_adicional.tipo_endereco; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.cliente_endereco_adicional.tipo_endereco IS 'C=Cobrança, E=Entrega, A=Ambos';


--
-- Name: cliente_endereco_adicional_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.cliente_endereco_adicional_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cliente_endereco_adicional_codigo_seq OWNER TO epare;

--
-- Name: cliente_endereco_adicional_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.cliente_endereco_adicional_codigo_seq OWNED BY public.cliente_endereco_adicional.codigo;


--
-- Name: cliente_forma_pagamento; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.cliente_forma_pagamento (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_cliente character varying(20) NOT NULL,
    codigo_erp_forma_pagamento character varying(20) NOT NULL,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.cliente_forma_pagamento FORCE ROW LEVEL SECURITY;


ALTER TABLE public.cliente_forma_pagamento OWNER TO epare;

--
-- Name: TABLE cliente_forma_pagamento; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.cliente_forma_pagamento IS 'Formas de pagamento permitidas ao cliente (N:N)';


--
-- Name: cliente_forma_pagamento_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.cliente_forma_pagamento_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cliente_forma_pagamento_codigo_seq OWNER TO epare;

--
-- Name: cliente_forma_pagamento_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.cliente_forma_pagamento_codigo_seq OWNED BY public.cliente_forma_pagamento.codigo;


--
-- Name: cliente_imposto; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.cliente_imposto (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_cliente character varying(20) NOT NULL,
    codigo_erp_classificacao_fiscal character varying(20),
    percentual_ipi numeric(15,4) DEFAULT 0,
    codigo_cst_origem character varying(10),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.cliente_imposto FORCE ROW LEVEL SECURITY;


ALTER TABLE public.cliente_imposto OWNER TO epare;

--
-- Name: TABLE cliente_imposto; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.cliente_imposto IS 'Configuração fiscal específica do cliente';


--
-- Name: cliente_imposto_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.cliente_imposto_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cliente_imposto_codigo_seq OWNER TO epare;

--
-- Name: cliente_imposto_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.cliente_imposto_codigo_seq OWNED BY public.cliente_imposto.codigo;


--
-- Name: cliente_representante; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.cliente_representante (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_cliente character varying(20) NOT NULL,
    codigo_erp_representante character varying(20) NOT NULL,
    cnpj_cpf_representante character varying(20),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.cliente_representante FORCE ROW LEVEL SECURITY;


ALTER TABLE public.cliente_representante OWNER TO epare;

--
-- Name: TABLE cliente_representante; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.cliente_representante IS 'Vínculo cliente x representante (N:N)';


--
-- Name: cliente_representante_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.cliente_representante_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cliente_representante_codigo_seq OWNER TO epare;

--
-- Name: cliente_representante_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.cliente_representante_codigo_seq OWNED BY public.cliente_representante.codigo;


--
-- Name: cliente_rota_simples; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.cliente_rota_simples (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_cliente character varying(20) NOT NULL,
    codigo_erp_rota_simples character varying(20) NOT NULL,
    descricao_rota_simples character varying(100),
    sequenciamento_ou_horario character(1),
    sequencia_horario character varying(20),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now(),
    CONSTRAINT ck_cli_rota_seq CHECK (((sequenciamento_ou_horario = ANY (ARRAY['S'::bpchar, 'H'::bpchar])) OR (sequenciamento_ou_horario IS NULL)))
);

ALTER TABLE ONLY public.cliente_rota_simples FORCE ROW LEVEL SECURITY;


ALTER TABLE public.cliente_rota_simples OWNER TO epare;

--
-- Name: TABLE cliente_rota_simples; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.cliente_rota_simples IS 'Rota de visita do cliente (sequência ou horário)';


--
-- Name: cliente_rota_simples_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.cliente_rota_simples_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cliente_rota_simples_codigo_seq OWNER TO epare;

--
-- Name: cliente_rota_simples_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.cliente_rota_simples_codigo_seq OWNED BY public.cliente_rota_simples.codigo;


--
-- Name: cliente_tabela_preco; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.cliente_tabela_preco (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_cliente character varying(20) NOT NULL,
    codigo_erp_tabela_preco character varying(20) NOT NULL,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.cliente_tabela_preco FORCE ROW LEVEL SECURITY;


ALTER TABLE public.cliente_tabela_preco OWNER TO epare;

--
-- Name: TABLE cliente_tabela_preco; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.cliente_tabela_preco IS 'Tabelas de preço vinculadas ao cliente (N:N)';


--
-- Name: cliente_tabela_preco_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.cliente_tabela_preco_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cliente_tabela_preco_codigo_seq OWNER TO epare;

--
-- Name: cliente_tabela_preco_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.cliente_tabela_preco_codigo_seq OWNED BY public.cliente_tabela_preco.codigo;


--
-- Name: condicao_pagamento; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.condicao_pagamento (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    descricao character varying(100),
    quantidade_parcelas integer DEFAULT 1,
    valor_minimo_parcela numeric(15,4) DEFAULT 0,
    calcular_valor_adicional boolean DEFAULT false,
    percentual_valor_adicional numeric(15,4) DEFAULT 0,
    prazo_medio integer DEFAULT 0,
    exibir_pedidos_negociados boolean DEFAULT true,
    tipo_calculo character varying(2),
    ativo boolean DEFAULT true,
    data_bloqueio date,
    motivo_bloqueio character varying(200),
    ordem_exibicao integer DEFAULT 0,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.condicao_pagamento FORCE ROW LEVEL SECURITY;


ALTER TABLE public.condicao_pagamento OWNER TO epare;

--
-- Name: TABLE condicao_pagamento; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.condicao_pagamento IS 'Condição de Pagamento (prazo, parcelas, etc)';


--
-- Name: condicao_pagamento_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.condicao_pagamento_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.condicao_pagamento_codigo_seq OWNER TO epare;

--
-- Name: condicao_pagamento_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.condicao_pagamento_codigo_seq OWNED BY public.condicao_pagamento.codigo;


--
-- Name: condicao_pagamento_forma; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.condicao_pagamento_forma (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_condicao_pagamento character varying(20) NOT NULL,
    codigo_erp_forma_pagamento character varying(20) NOT NULL,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.condicao_pagamento_forma FORCE ROW LEVEL SECURITY;


ALTER TABLE public.condicao_pagamento_forma OWNER TO epare;

--
-- Name: TABLE condicao_pagamento_forma; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.condicao_pagamento_forma IS 'Formas de pagamento da condição (N:N)';


--
-- Name: condicao_pagamento_forma_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.condicao_pagamento_forma_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.condicao_pagamento_forma_codigo_seq OWNER TO epare;

--
-- Name: condicao_pagamento_forma_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.condicao_pagamento_forma_codigo_seq OWNED BY public.condicao_pagamento_forma.codigo;


--
-- Name: condicao_pagamento_parcela; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.condicao_pagamento_parcela (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp_condicao_pagamento character varying(20) NOT NULL,
    numero_parcela integer NOT NULL,
    quantidade_dias integer NOT NULL,
    percentual_rateio numeric(15,4) DEFAULT 0,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.condicao_pagamento_parcela FORCE ROW LEVEL SECURITY;


ALTER TABLE public.condicao_pagamento_parcela OWNER TO epare;

--
-- Name: TABLE condicao_pagamento_parcela; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.condicao_pagamento_parcela IS 'Parcelas da condição de pagamento (rateio, prazos)';


--
-- Name: condicao_pagamento_parcela_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.condicao_pagamento_parcela_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.condicao_pagamento_parcela_codigo_seq OWNER TO epare;

--
-- Name: condicao_pagamento_parcela_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.condicao_pagamento_parcela_codigo_seq OWNED BY public.condicao_pagamento_parcela.codigo;


--
-- Name: condicao_pagamento_unidade; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.condicao_pagamento_unidade (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_condicao_pagamento character varying(20) NOT NULL,
    codigo_erp_unidade_negocio character varying(20) NOT NULL,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.condicao_pagamento_unidade FORCE ROW LEVEL SECURITY;


ALTER TABLE public.condicao_pagamento_unidade OWNER TO epare;

--
-- Name: TABLE condicao_pagamento_unidade; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.condicao_pagamento_unidade IS 'Unidades de negócio da condição (N:N)';


--
-- Name: condicao_pagamento_unidade_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.condicao_pagamento_unidade_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.condicao_pagamento_unidade_codigo_seq OWNER TO epare;

--
-- Name: condicao_pagamento_unidade_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.condicao_pagamento_unidade_codigo_seq OWNED BY public.condicao_pagamento_unidade.codigo;


--
-- Name: customizador_dados; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.customizador_dados (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    nosso_codigo_customizador character varying(20),
    codigo_erp_representante character varying(20),
    codigo_erp_identificacao_dados character varying(50),
    descricao_periodo_dados character varying(100),
    titulo_adicional_dados character varying(200),
    dados_html text,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.customizador_dados FORCE ROW LEVEL SECURITY;


ALTER TABLE public.customizador_dados OWNER TO epare;

--
-- Name: TABLE customizador_dados; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.customizador_dados IS 'Relatórios/dados customizados exibidos no app';


--
-- Name: customizador_dados_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.customizador_dados_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.customizador_dados_codigo_seq OWNER TO epare;

--
-- Name: customizador_dados_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.customizador_dados_codigo_seq OWNED BY public.customizador_dados.codigo;


--
-- Name: embalagem_venda; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.embalagem_venda (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    descricao character varying(100),
    codigo_erp_unidade_medida character varying(20),
    ativo boolean DEFAULT true,
    data_bloqueio date,
    motivo_bloqueio character varying(200),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.embalagem_venda FORCE ROW LEVEL SECURITY;


ALTER TABLE public.embalagem_venda OWNER TO epare;

--
-- Name: TABLE embalagem_venda; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.embalagem_venda IS 'Embalagem de Venda (caixa, fardo, etc)';


--
-- Name: embalagem_venda_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.embalagem_venda_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.embalagem_venda_codigo_seq OWNER TO epare;

--
-- Name: embalagem_venda_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.embalagem_venda_codigo_seq OWNED BY public.embalagem_venda.codigo;


--
-- Name: empresa; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.empresa (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    slug character varying(50),
    cnpj character varying(18) NOT NULL,
    razao_social character varying(200) NOT NULL,
    nome_fantasia character varying(200),
    inscricao_estadual character varying(20),
    email character varying(200),
    telefone character varying(20),
    cep character varying(10),
    logradouro character varying(200),
    numero character varying(20),
    complemento character varying(100),
    bairro character varying(100),
    cidade character varying(100),
    estado character(2),
    ativo boolean DEFAULT true,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now(),
    CONSTRAINT ck_empresa_estado CHECK (((estado IS NULL) OR (length(estado) = 2)))
);


ALTER TABLE public.empresa OWNER TO epare;

--
-- Name: TABLE empresa; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.empresa IS 'CNPJ pertencente a um tenant (1 tenant pode ter várias empresas)';


--
-- Name: COLUMN empresa.cod_empresa; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.empresa.cod_empresa IS 'Código sequencial dentro do tenant (1, 2, 3...)';


--
-- Name: COLUMN empresa.slug; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.empresa.slug IS 'Opcional. Identificador amigável dentro do tenant';


--
-- Name: equipe_venda; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.equipe_venda (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    descricao character varying(100),
    ativo boolean DEFAULT true,
    data_bloqueio date,
    motivo_bloqueio character varying(200),
    chave character varying(20),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.equipe_venda FORCE ROW LEVEL SECURITY;


ALTER TABLE public.equipe_venda OWNER TO epare;

--
-- Name: TABLE equipe_venda; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.equipe_venda IS 'Equipe de Venda (agrupamento de representantes)';


--
-- Name: equipe_venda_categoria; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.equipe_venda_categoria (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_equipe_venda character varying(20) NOT NULL,
    codigo_categoria character varying(20) NOT NULL,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.equipe_venda_categoria FORCE ROW LEVEL SECURITY;


ALTER TABLE public.equipe_venda_categoria OWNER TO epare;

--
-- Name: TABLE equipe_venda_categoria; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.equipe_venda_categoria IS 'Categorias de cliente vinculadas à equipe (N:N)';


--
-- Name: equipe_venda_categoria_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.equipe_venda_categoria_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.equipe_venda_categoria_codigo_seq OWNER TO epare;

--
-- Name: equipe_venda_categoria_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.equipe_venda_categoria_codigo_seq OWNED BY public.equipe_venda_categoria.codigo;


--
-- Name: equipe_venda_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.equipe_venda_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.equipe_venda_codigo_seq OWNER TO epare;

--
-- Name: equipe_venda_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.equipe_venda_codigo_seq OWNED BY public.equipe_venda.codigo;


--
-- Name: equipe_venda_item; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.equipe_venda_item (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_equipe_venda character varying(20) NOT NULL,
    codigo_erp_item character varying(20) NOT NULL,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.equipe_venda_item FORCE ROW LEVEL SECURITY;


ALTER TABLE public.equipe_venda_item OWNER TO epare;

--
-- Name: TABLE equipe_venda_item; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.equipe_venda_item IS 'Itens vinculados à equipe de venda (N:N)';


--
-- Name: equipe_venda_item_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.equipe_venda_item_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.equipe_venda_item_codigo_seq OWNER TO epare;

--
-- Name: equipe_venda_item_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.equipe_venda_item_codigo_seq OWNED BY public.equipe_venda_item.codigo;


--
-- Name: fabricante; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.fabricante (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    apelido_fantasia character varying(100),
    ativo boolean DEFAULT true,
    data_bloqueio date,
    motivo_bloqueio character varying(200),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.fabricante FORCE ROW LEVEL SECURITY;


ALTER TABLE public.fabricante OWNER TO epare;

--
-- Name: TABLE fabricante; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.fabricante IS 'Cadastro de Fabricante';


--
-- Name: fabricante_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.fabricante_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fabricante_codigo_seq OWNER TO epare;

--
-- Name: fabricante_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.fabricante_codigo_seq OWNED BY public.fabricante.codigo;


--
-- Name: flyway_schema_history; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.flyway_schema_history (
    installed_rank integer NOT NULL,
    version character varying(50),
    description character varying(200) NOT NULL,
    type character varying(20) NOT NULL,
    script character varying(1000) NOT NULL,
    checksum integer,
    installed_by character varying(100) NOT NULL,
    installed_on timestamp without time zone DEFAULT now() NOT NULL,
    execution_time integer NOT NULL,
    success boolean NOT NULL
);


ALTER TABLE public.flyway_schema_history OWNER TO epare;

--
-- Name: forma_pagamento; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.forma_pagamento (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    descricao character varying(100),
    exibir_pedidos_negociados boolean DEFAULT true,
    ativo boolean DEFAULT true,
    data_bloqueio date,
    motivo_bloqueio character varying(200),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.forma_pagamento FORCE ROW LEVEL SECURITY;


ALTER TABLE public.forma_pagamento OWNER TO epare;

--
-- Name: TABLE forma_pagamento; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.forma_pagamento IS 'Forma de Pagamento (DINHEIRO, PIX, BOLETO, etc)';


--
-- Name: forma_pagamento_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.forma_pagamento_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.forma_pagamento_codigo_seq OWNER TO epare;

--
-- Name: forma_pagamento_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.forma_pagamento_codigo_seq OWNED BY public.forma_pagamento.codigo;


--
-- Name: forma_pagamento_unidade_negocio; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.forma_pagamento_unidade_negocio (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_forma_pagamento character varying(20) NOT NULL,
    codigo_erp_unidade_negocio character varying(20) NOT NULL,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.forma_pagamento_unidade_negocio FORCE ROW LEVEL SECURITY;


ALTER TABLE public.forma_pagamento_unidade_negocio OWNER TO epare;

--
-- Name: TABLE forma_pagamento_unidade_negocio; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.forma_pagamento_unidade_negocio IS 'Unidades onde a forma está disponível (N:N)';


--
-- Name: forma_pagamento_unidade_negocio_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.forma_pagamento_unidade_negocio_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.forma_pagamento_unidade_negocio_codigo_seq OWNER TO epare;

--
-- Name: forma_pagamento_unidade_negocio_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.forma_pagamento_unidade_negocio_codigo_seq OWNED BY public.forma_pagamento_unidade_negocio.codigo;


--
-- Name: grupo_cliente; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.grupo_cliente (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    descricao character varying(100),
    codigo_erp_tabela_preco character varying(20),
    ativo boolean DEFAULT true,
    data_bloqueio date,
    motivo_bloqueio character varying(200),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.grupo_cliente FORCE ROW LEVEL SECURITY;


ALTER TABLE public.grupo_cliente OWNER TO epare;

--
-- Name: TABLE grupo_cliente; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.grupo_cliente IS 'Grupo de Cliente (segmentação comercial)';


--
-- Name: grupo_cliente_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.grupo_cliente_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.grupo_cliente_codigo_seq OWNER TO epare;

--
-- Name: grupo_cliente_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.grupo_cliente_codigo_seq OWNED BY public.grupo_cliente.codigo;


--
-- Name: item; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.item (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    codigo_erp_interno character varying(20),
    descricao character varying(200) NOT NULL,
    codigo_erp_categoria_nivel1 character varying(20),
    descricao_categoria_nivel1 character varying(100),
    codigo_erp_categoria_nivel2 character varying(20),
    descricao_categoria_nivel2 character varying(100),
    codigo_erp_categoria_nivel3 character varying(20),
    descricao_categoria_nivel3 character varying(100),
    codigo_erp_unidade_medida character varying(20),
    codigo_erp_fabricante character varying(20),
    apelido_fantasia_fabricante character varying(100),
    codigo_integracao_tabela_preco character varying(20),
    preco_venda numeric(15,4) DEFAULT 0,
    preco_promocional numeric(15,4) DEFAULT 0,
    data_inicio_promocao date,
    data_termino_promocao date,
    percentual_maximo_desconto numeric(15,4) DEFAULT 0,
    quantidade_disponivel_estoque numeric(15,4) DEFAULT 0,
    permite_venda_sem_estoque boolean DEFAULT false,
    caracteristicas text,
    ficha_tecnica text,
    acessorios_inclusos text,
    termos_garantia text,
    peso_bruto numeric(15,4) DEFAULT 0,
    peso_liquido numeric(15,4) DEFAULT 0,
    altura_embalagem numeric(15,4) DEFAULT 0,
    comprimento_embalagem numeric(15,4) DEFAULT 0,
    largura_embalagem numeric(15,4) DEFAULT 0,
    cubagem_embalagem numeric(15,4) DEFAULT 0,
    qtde_volumes_embalagem numeric(15,4) DEFAULT 0,
    codigo_erp_classificacao_fiscal character varying(20),
    percentual_ipi_classificacao_fiscal numeric(15,4) DEFAULT 0,
    item_e_um_lancamento boolean DEFAULT false,
    data_inclusao date,
    ativo boolean DEFAULT true,
    data_bloqueio date,
    motivo_bloqueio character varying(200),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.item FORCE ROW LEVEL SECURITY;


ALTER TABLE public.item OWNER TO epare;

--
-- Name: TABLE item; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.item IS 'Produto ou Serviço';


--
-- Name: COLUMN item.codigo_erp; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.item.codigo_erp IS 'Código do produto no ERP do cliente';


--
-- Name: COLUMN item.codigo_erp_interno; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.item.codigo_erp_interno IS 'Código interno do ERP (quando diferente do principal)';


--
-- Name: COLUMN item.item_e_um_lancamento; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.item.item_e_um_lancamento IS 'TRUE = item de lançamento (não é produto físico)';


--
-- Name: item_campo_adicional; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.item_campo_adicional (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_item character varying(20) NOT NULL,
    field character varying(50) NOT NULL,
    descricao character varying(100),
    value character varying(500),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.item_campo_adicional FORCE ROW LEVEL SECURITY;


ALTER TABLE public.item_campo_adicional OWNER TO epare;

--
-- Name: TABLE item_campo_adicional; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.item_campo_adicional IS 'Campos adicionais personalizados do item';


--
-- Name: item_campo_adicional_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.item_campo_adicional_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.item_campo_adicional_codigo_seq OWNER TO epare;

--
-- Name: item_campo_adicional_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.item_campo_adicional_codigo_seq OWNED BY public.item_campo_adicional.codigo;


--
-- Name: item_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.item_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.item_codigo_seq OWNER TO epare;

--
-- Name: item_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.item_codigo_seq OWNED BY public.item.codigo;


--
-- Name: item_embalagem_venda; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.item_embalagem_venda (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_item character varying(20) NOT NULL,
    codigo_erp_embalagem_venda character varying(20) NOT NULL,
    tipo_calculo character varying(10),
    fator_conversao numeric(15,4),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.item_embalagem_venda FORCE ROW LEVEL SECURITY;


ALTER TABLE public.item_embalagem_venda OWNER TO epare;

--
-- Name: TABLE item_embalagem_venda; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.item_embalagem_venda IS 'Embalagens de venda do item (N:N)';


--
-- Name: item_embalagem_venda_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.item_embalagem_venda_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.item_embalagem_venda_codigo_seq OWNER TO epare;

--
-- Name: item_embalagem_venda_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.item_embalagem_venda_codigo_seq OWNED BY public.item_embalagem_venda.codigo;


--
-- Name: item_estoque; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.item_estoque (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp_unidade_negocio character varying(20) NOT NULL,
    codigo_erp_item character varying(20) NOT NULL,
    agrupamento_adicional character varying(50),
    quantidade numeric(15,4) DEFAULT 0,
    quantidade_est_prevista numeric(15,4) DEFAULT 0,
    data_est_prevista date,
    quantidade_est_prevista_futura numeric(15,4) DEFAULT 0,
    data_est_prevista_futura date,
    quantidade_pedido_venda_erp numeric(15,4) DEFAULT 0,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.item_estoque FORCE ROW LEVEL SECURITY;


ALTER TABLE public.item_estoque OWNER TO epare;

--
-- Name: TABLE item_estoque; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.item_estoque IS 'Estoque do item por unidade de negócio (filial)';


--
-- Name: item_estoque_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.item_estoque_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.item_estoque_codigo_seq OWNER TO epare;

--
-- Name: item_estoque_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.item_estoque_codigo_seq OWNED BY public.item_estoque.codigo;


--
-- Name: item_imposto; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.item_imposto (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_item character varying(20) NOT NULL,
    codigo_erp_classificacao_fiscal character varying(20),
    percentual_ipi numeric(15,4) DEFAULT 0,
    codigo_cst_origem character varying(10),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.item_imposto FORCE ROW LEVEL SECURITY;


ALTER TABLE public.item_imposto OWNER TO epare;

--
-- Name: TABLE item_imposto; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.item_imposto IS 'Configuração fiscal específica do item';


--
-- Name: item_imposto_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.item_imposto_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.item_imposto_codigo_seq OWNER TO epare;

--
-- Name: item_imposto_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.item_imposto_codigo_seq OWNED BY public.item_imposto.codigo;


--
-- Name: item_unidade_negocio; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.item_unidade_negocio (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_item character varying(20) NOT NULL,
    codigo_erp_unidade_negocio character varying(20) NOT NULL,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.item_unidade_negocio FORCE ROW LEVEL SECURITY;


ALTER TABLE public.item_unidade_negocio OWNER TO epare;

--
-- Name: TABLE item_unidade_negocio; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.item_unidade_negocio IS 'Unidades de negócio onde o item está disponível (N:N)';


--
-- Name: item_unidade_negocio_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.item_unidade_negocio_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.item_unidade_negocio_codigo_seq OWNER TO epare;

--
-- Name: item_unidade_negocio_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.item_unidade_negocio_codigo_seq OWNED BY public.item_unidade_negocio.codigo;


--
-- Name: log_auditoria; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.log_auditoria (
    cod_log bigint NOT NULL,
    cod_tenant integer,
    cod_empresa integer,
    cod_usuario integer,
    acao character varying(50) NOT NULL,
    tabela character varying(100),
    registro_id character varying(100),
    dados_antes jsonb,
    dados_depois jsonb,
    ip inet,
    user_agent character varying(500),
    dt_evento timestamp with time zone DEFAULT now()
);


ALTER TABLE public.log_auditoria OWNER TO epare;

--
-- Name: TABLE log_auditoria; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.log_auditoria IS 'Log de auditoria (quem fez o quê, quando, em qual registro)';


--
-- Name: COLUMN log_auditoria.dados_antes; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.log_auditoria.dados_antes IS 'Estado do registro antes da alteração (JSON)';


--
-- Name: COLUMN log_auditoria.dados_depois; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.log_auditoria.dados_depois IS 'Estado do registro depois da alteração (JSON)';


--
-- Name: log_auditoria_cod_log_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.log_auditoria_cod_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.log_auditoria_cod_log_seq OWNER TO epare;

--
-- Name: log_auditoria_cod_log_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.log_auditoria_cod_log_seq OWNED BY public.log_auditoria.cod_log;


--
-- Name: pedido; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.pedido (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    codigo_erp_empresa character varying(20),
    nosso_codigo_pedido character varying(20),
    apagar_dados_pedido boolean DEFAULT false,
    nosso_codigo_cliente character varying(20),
    codigo_erp_cliente character varying(20),
    cliente_tipo_pessoa character(1),
    cliente_cnpj_cpf character varying(20),
    endereco_ident_faturamento character varying(50),
    endereco_ident_cobranca character varying(50),
    endereco_ident_entrega character varying(50),
    data_digitacao date,
    hora_digitacao time without time zone,
    data_emissao date,
    e_um_orcamento boolean DEFAULT false,
    codigo_erp_representante character varying(20),
    representante_cnpj_cpf character varying(20),
    codigo_erp_transportadora character varying(20),
    transportadora_cnpj_cpf character varying(20),
    codigo_erp_redespacho character varying(20),
    redespacho_cnpj_cpf character varying(20),
    comprador_nome_responsavel character varying(100),
    codigo_erp_condicao_pagamento character varying(20),
    codigo_erp_forma_pagamento character varying(20),
    codigo_erp_tipo_frete character varying(20),
    codigo_erp_tipo_venda character varying(20),
    valor_frete numeric(15,4) DEFAULT 0,
    valor_desconto_capa numeric(15,4) DEFAULT 0,
    nro_pedido_cliente character varying(50),
    observacoes_pedido text,
    observacoes_nota_fiscal text,
    situacao_pedido character varying(2),
    situacao_bloqueio character varying(2),
    motivo_cancelamento character varying(200),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now(),
    CONSTRAINT ck_pedido_cliente_tipo CHECK (((cliente_tipo_pessoa = ANY (ARRAY['F'::bpchar, 'J'::bpchar])) OR (cliente_tipo_pessoa IS NULL)))
);

ALTER TABLE ONLY public.pedido FORCE ROW LEVEL SECURITY;


ALTER TABLE public.pedido OWNER TO epare;

--
-- Name: TABLE pedido; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.pedido IS 'Pedido de Venda ou Orçamento';


--
-- Name: COLUMN pedido.situacao_pedido; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.pedido.situacao_pedido IS '1=Aberto, 2=Cancelado, 3=Faturado Total, 4=Expedido, 5=Entregue, 7=Faturado Parcial/Encerrado, 8=Faturado Parcial/Aberto, 11=Orçamento Revisado, 12=Orçamento Aprovado';


--
-- Name: COLUMN pedido.situacao_bloqueio; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.pedido.situacao_bloqueio IS '10..24 — código do bloqueio (ver doc do ERP)';


--
-- Name: pedido_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.pedido_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pedido_codigo_seq OWNER TO epare;

--
-- Name: pedido_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.pedido_codigo_seq OWNED BY public.pedido.codigo;


--
-- Name: pedido_historico; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.pedido_historico (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp_unidade_negocio character varying(20),
    nosso_codigo_pedido character varying(20),
    codigo_erp_pedido character varying(20) NOT NULL,
    codigo_erp_historico_pedido character varying(50) NOT NULL,
    data_historico date,
    hora_historico time without time zone,
    tipo_historico character varying(2),
    descricao_historico character varying(200),
    nro_nota_fiscal character varying(20),
    chave_nfe_nfse character varying(50),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.pedido_historico FORCE ROW LEVEL SECURITY;


ALTER TABLE public.pedido_historico OWNER TO epare;

--
-- Name: TABLE pedido_historico; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.pedido_historico IS 'Histórico do pedido (faturamento, cancelamento, entrega)';


--
-- Name: COLUMN pedido_historico.tipo_historico; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.pedido_historico.tipo_historico IS '2=Cancelado, 3=Faturado, 4=Enviado transp., 5=Entregue';


--
-- Name: pedido_historico_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.pedido_historico_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pedido_historico_codigo_seq OWNER TO epare;

--
-- Name: pedido_historico_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.pedido_historico_codigo_seq OWNED BY public.pedido_historico.codigo;


--
-- Name: pedido_item; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.pedido_item (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp_empresa character varying(20),
    codigo_erp_pedido character varying(20) NOT NULL,
    nosso_codigo_item_pedido character varying(20),
    codigo_erp_item_pedido character varying(20) NOT NULL,
    codigo_erp_produto character varying(20) NOT NULL,
    codigo_erp_tabela_preco character varying(20),
    codigo_erp_moeda character varying(20),
    codigo_erp_embalagem character varying(20),
    embalagem_unidade_medida character varying(20),
    preco_venda_original_sugerido numeric(15,4) DEFAULT 0,
    preco_venda_praticado_digitado numeric(15,4) DEFAULT 0,
    quantidade_informada numeric(15,4) DEFAULT 0,
    fator_conversao numeric(15,4) DEFAULT 0,
    embalagem_preco_venda_praticado numeric(15,4) DEFAULT 0,
    embalagem_quantidade numeric(15,4) DEFAULT 0,
    valor_desconto_comercial numeric(15,4) DEFAULT 0,
    percentual_desconto_comercial numeric(15,4) DEFAULT 0,
    valor_acrescimo_comercial numeric(15,4) DEFAULT 0,
    percentual_acrescimo_comercial numeric(15,4) DEFAULT 0,
    valor_total_produtos_liquido numeric(15,4),
    data_entrega date,
    observacao_item text,
    situacao_item_pedido character varying(2),
    quantidade_faturada numeric(15,4) DEFAULT 0,
    aliquota_icms numeric(15,4) DEFAULT 0,
    valor_icms numeric(15,4) DEFAULT 0,
    aliquota_ipi numeric(15,4) DEFAULT 0,
    valor_ipi numeric(15,4) DEFAULT 0,
    valor_icms_subst numeric(15,4) DEFAULT 0,
    perc_desconto_02 numeric(15,4) DEFAULT 0,
    perc_desconto_03 numeric(15,4) DEFAULT 0,
    perc_desconto_04 numeric(15,4) DEFAULT 0,
    perc_desconto_05 numeric(15,4) DEFAULT 0,
    perc_desconto_06 numeric(15,4) DEFAULT 0,
    perc_desconto_07 numeric(15,4) DEFAULT 0,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.pedido_item FORCE ROW LEVEL SECURITY;


ALTER TABLE public.pedido_item OWNER TO epare;

--
-- Name: TABLE pedido_item; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.pedido_item IS 'Itens do pedido de venda';


--
-- Name: pedido_item_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.pedido_item_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pedido_item_codigo_seq OWNER TO epare;

--
-- Name: pedido_item_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.pedido_item_codigo_seq OWNED BY public.pedido_item.codigo;


--
-- Name: ramo_atividade; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.ramo_atividade (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    descricao character varying(100),
    ativo boolean DEFAULT true,
    data_bloqueio date,
    motivo_bloqueio character varying(200),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.ramo_atividade FORCE ROW LEVEL SECURITY;


ALTER TABLE public.ramo_atividade OWNER TO epare;

--
-- Name: TABLE ramo_atividade; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.ramo_atividade IS 'Ramo de Atividade / Segmento do cliente';


--
-- Name: ramo_atividade_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.ramo_atividade_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ramo_atividade_codigo_seq OWNER TO epare;

--
-- Name: ramo_atividade_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.ramo_atividade_codigo_seq OWNED BY public.ramo_atividade.codigo;


--
-- Name: representante; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.representante (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    tipo_pessoa character(1),
    cnpj_cpf character varying(20),
    inscricao_estadual_rg character varying(20),
    nome_razao character varying(100),
    nome_fantasia character varying(100),
    estado character(2),
    email character varying(100),
    telefone_fixo character varying(20),
    ramal character varying(10),
    celular character varying(20),
    outros_telefones character varying(100),
    ativo boolean DEFAULT true,
    data_bloqueio date,
    motivo_bloqueio character varying(200),
    codigo_erp_tabela_preco character varying(20),
    codigo_erp_unidade_negocio character varying(20),
    codigo_erp_equipe_venda character varying(20),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now(),
    CONSTRAINT ck_representante_tipo CHECK (((tipo_pessoa = ANY (ARRAY['F'::bpchar, 'J'::bpchar])) OR (tipo_pessoa IS NULL)))
);

ALTER TABLE ONLY public.representante FORCE ROW LEVEL SECURITY;


ALTER TABLE public.representante OWNER TO epare;

--
-- Name: TABLE representante; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.representante IS 'Representante / Vendedor';


--
-- Name: representante_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.representante_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.representante_codigo_seq OWNER TO epare;

--
-- Name: representante_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.representante_codigo_seq OWNED BY public.representante.codigo;


--
-- Name: representante_supervisor; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.representante_supervisor (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_representante character varying(20) NOT NULL,
    codigo_erp_supervisor character varying(20) NOT NULL,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.representante_supervisor FORCE ROW LEVEL SECURITY;


ALTER TABLE public.representante_supervisor OWNER TO epare;

--
-- Name: TABLE representante_supervisor; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.representante_supervisor IS 'Vínculo representante x supervisor (N:N)';


--
-- Name: representante_supervisor_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.representante_supervisor_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.representante_supervisor_codigo_seq OWNER TO epare;

--
-- Name: representante_supervisor_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.representante_supervisor_codigo_seq OWNED BY public.representante_supervisor.codigo;


--
-- Name: representante_tipo_venda; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.representante_tipo_venda (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_representante character varying(20) NOT NULL,
    codigo_erp_tipo_venda character varying(20) NOT NULL,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.representante_tipo_venda FORCE ROW LEVEL SECURITY;


ALTER TABLE public.representante_tipo_venda OWNER TO epare;

--
-- Name: TABLE representante_tipo_venda; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.representante_tipo_venda IS 'Tipos de venda que o representante pode usar (N:N)';


--
-- Name: representante_tipo_venda_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.representante_tipo_venda_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.representante_tipo_venda_codigo_seq OWNER TO epare;

--
-- Name: representante_tipo_venda_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.representante_tipo_venda_codigo_seq OWNED BY public.representante_tipo_venda.codigo;


--
-- Name: revendedor; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.revendedor (
    cod_revendedor integer NOT NULL,
    slug character varying(50) NOT NULL,
    nome character varying(200) NOT NULL,
    cnpj character varying(18),
    email_contato character varying(200),
    telefone character varying(20),
    marca_nome character varying(100),
    marca_logo_url character varying(500),
    marca_cor_primaria character varying(7),
    marca_cor_secundaria character varying(7),
    marca_favicon_url character varying(500),
    dominio_customizado character varying(200),
    plano character varying(50) DEFAULT 'basico'::character varying,
    percentual_comissao numeric(5,2) DEFAULT 0,
    limite_tenants integer DEFAULT 10,
    ativo boolean DEFAULT true,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now(),
    observacoes text,
    CONSTRAINT ck_revendedor_slug CHECK (((slug)::text ~ '^[a-z0-9][a-z0-9-]{1,48}[a-z0-9]$'::text))
);


ALTER TABLE public.revendedor OWNER TO epare;

--
-- Name: TABLE revendedor; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.revendedor IS 'Software house que revende o sistema com marca própria (white label)';


--
-- Name: COLUMN revendedor.slug; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.revendedor.slug IS 'Identificador amigável (ex: sistema-do-ze)';


--
-- Name: COLUMN revendedor.marca_nome; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.revendedor.marca_nome IS 'Nome que o revendedor usa (ex: Sistema do Zé)';


--
-- Name: COLUMN revendedor.dominio_customizado; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.revendedor.dominio_customizado IS 'Domínio próprio do revendedor (ex: app.sistemadoze.com.br)';


--
-- Name: COLUMN revendedor.percentual_comissao; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.revendedor.percentual_comissao IS 'Percentual de comissão que você recebe do revendedor';


--
-- Name: revendedor_cod_revendedor_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.revendedor_cod_revendedor_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.revendedor_cod_revendedor_seq OWNER TO epare;

--
-- Name: revendedor_cod_revendedor_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.revendedor_cod_revendedor_seq OWNED BY public.revendedor.cod_revendedor;


--
-- Name: risco_cliente; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.risco_cliente (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    descricao character varying(100),
    controle_cliente_receber_dx integer DEFAULT 0,
    controle_cliente_receber character varying(2) DEFAULT 'N'::character varying,
    controle_limite_credito character varying(2) DEFAULT 'N'::character varying,
    controle_geral character varying(2) DEFAULT 'N'::character varying,
    controle_mensagem_padrao character varying(200),
    cor character varying(20),
    ativo boolean DEFAULT true,
    data_bloqueio date,
    motivo_bloqueio character varying(200),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.risco_cliente FORCE ROW LEVEL SECURITY;


ALTER TABLE public.risco_cliente OWNER TO epare;

--
-- Name: TABLE risco_cliente; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.risco_cliente IS 'Tipo de Risco Financeiro do Cliente (controle de crédito)';


--
-- Name: COLUMN risco_cliente.controle_cliente_receber; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.risco_cliente.controle_cliente_receber IS 'N/D/M/B/1..16 — ver doc do ERP';


--
-- Name: risco_cliente_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.risco_cliente_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.risco_cliente_codigo_seq OWNER TO epare;

--
-- Name: risco_cliente_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.risco_cliente_codigo_seq OWNED BY public.risco_cliente.codigo;


--
-- Name: rota_simples; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.rota_simples (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    descricao character varying(100),
    ativo boolean DEFAULT true,
    data_bloqueio date,
    motivo_bloqueio character varying(200),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.rota_simples FORCE ROW LEVEL SECURITY;


ALTER TABLE public.rota_simples OWNER TO epare;

--
-- Name: TABLE rota_simples; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.rota_simples IS 'Cadastro de Rota Simples (sequência de visitas)';


--
-- Name: rota_simples_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.rota_simples_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rota_simples_codigo_seq OWNER TO epare;

--
-- Name: rota_simples_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.rota_simples_codigo_seq OWNED BY public.rota_simples.codigo;


--
-- Name: tabela_preco; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.tabela_preco (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    descricao character varying(100),
    percentual_maximo_desconto numeric(15,4) DEFAULT 100,
    permitir_alterar_preco boolean DEFAULT true,
    disponibilizar_todos_clientes boolean DEFAULT false,
    ativo boolean DEFAULT true,
    data_bloqueio date,
    motivo_bloqueio character varying(200),
    dt_entrega_minima date,
    dt_entrega_maxima date,
    obrigar_digitacao_dt_entrega boolean DEFAULT false,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.tabela_preco FORCE ROW LEVEL SECURITY;


ALTER TABLE public.tabela_preco OWNER TO epare;

--
-- Name: TABLE tabela_preco; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.tabela_preco IS 'Cadastro de Tabela de Preço';


--
-- Name: tabela_preco_cliente; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.tabela_preco_cliente (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_tabela_preco character varying(20) NOT NULL,
    codigo_erp_cliente character varying(20) NOT NULL,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.tabela_preco_cliente FORCE ROW LEVEL SECURITY;


ALTER TABLE public.tabela_preco_cliente OWNER TO epare;

--
-- Name: TABLE tabela_preco_cliente; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.tabela_preco_cliente IS 'Clientes com acesso exclusivo a tabela (N:N)';


--
-- Name: tabela_preco_cliente_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.tabela_preco_cliente_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tabela_preco_cliente_codigo_seq OWNER TO epare;

--
-- Name: tabela_preco_cliente_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.tabela_preco_cliente_codigo_seq OWNED BY public.tabela_preco_cliente.codigo;


--
-- Name: tabela_preco_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.tabela_preco_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tabela_preco_codigo_seq OWNER TO epare;

--
-- Name: tabela_preco_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.tabela_preco_codigo_seq OWNED BY public.tabela_preco.codigo;


--
-- Name: tabela_preco_condicao_pagamento; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.tabela_preco_condicao_pagamento (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_tabela_preco character varying(20) NOT NULL,
    codigo_erp_condicao_pagamento character varying(20) NOT NULL,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.tabela_preco_condicao_pagamento FORCE ROW LEVEL SECURITY;


ALTER TABLE public.tabela_preco_condicao_pagamento OWNER TO epare;

--
-- Name: TABLE tabela_preco_condicao_pagamento; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.tabela_preco_condicao_pagamento IS 'Condições de pagamento permitidas por tabela (N:N)';


--
-- Name: tabela_preco_condicao_pagamento_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.tabela_preco_condicao_pagamento_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tabela_preco_condicao_pagamento_codigo_seq OWNER TO epare;

--
-- Name: tabela_preco_condicao_pagamento_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.tabela_preco_condicao_pagamento_codigo_seq OWNED BY public.tabela_preco_condicao_pagamento.codigo;


--
-- Name: tabela_preco_grupo_cliente; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.tabela_preco_grupo_cliente (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_tabela_preco character varying(20) NOT NULL,
    codigo_erp_grupo_cliente character varying(20) NOT NULL,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.tabela_preco_grupo_cliente FORCE ROW LEVEL SECURITY;


ALTER TABLE public.tabela_preco_grupo_cliente OWNER TO epare;

--
-- Name: TABLE tabela_preco_grupo_cliente; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.tabela_preco_grupo_cliente IS 'Grupos de cliente com acesso a tabela (N:N)';


--
-- Name: tabela_preco_grupo_cliente_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.tabela_preco_grupo_cliente_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tabela_preco_grupo_cliente_codigo_seq OWNER TO epare;

--
-- Name: tabela_preco_grupo_cliente_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.tabela_preco_grupo_cliente_codigo_seq OWNED BY public.tabela_preco_grupo_cliente.codigo;


--
-- Name: tabela_preco_item; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.tabela_preco_item (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp_tabela_preco character varying(20) NOT NULL,
    codigo_erp_item_tabela_preco character varying(20) NOT NULL,
    codigo_erp_item character varying(20) NOT NULL,
    quantidade_inicial numeric(15,4) DEFAULT 0,
    quantidade_final numeric(15,4) DEFAULT 999999,
    preco_venda numeric(15,4) DEFAULT 0,
    validade_inicial date,
    validade_final date,
    perc_desconto_maximo numeric(15,4) DEFAULT 100,
    preco_venda_promocao numeric(15,4) DEFAULT 0,
    validade_inicial_promocao date,
    validade_final_promocao date,
    perc_desconto_maximo_promocao numeric(15,4) DEFAULT 100,
    codigo_erp_tabela_prazo character varying(20),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.tabela_preco_item FORCE ROW LEVEL SECURITY;


ALTER TABLE public.tabela_preco_item OWNER TO epare;

--
-- Name: TABLE tabela_preco_item; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.tabela_preco_item IS 'Preço do item em cada tabela de preço';


--
-- Name: tabela_preco_item_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.tabela_preco_item_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tabela_preco_item_codigo_seq OWNER TO epare;

--
-- Name: tabela_preco_item_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.tabela_preco_item_codigo_seq OWNED BY public.tabela_preco_item.codigo;


--
-- Name: tabela_preco_representante; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.tabela_preco_representante (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_tabela_preco character varying(20) NOT NULL,
    codigo_erp_representante character varying(20) NOT NULL,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.tabela_preco_representante FORCE ROW LEVEL SECURITY;


ALTER TABLE public.tabela_preco_representante OWNER TO epare;

--
-- Name: TABLE tabela_preco_representante; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.tabela_preco_representante IS 'Representantes que podem usar cada tabela de preço (N:N)';


--
-- Name: tabela_preco_representante_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.tabela_preco_representante_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tabela_preco_representante_codigo_seq OWNER TO epare;

--
-- Name: tabela_preco_representante_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.tabela_preco_representante_codigo_seq OWNED BY public.tabela_preco_representante.codigo;


--
-- Name: tabela_preco_tipo_venda; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.tabela_preco_tipo_venda (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_tabela_preco character varying(20) NOT NULL,
    codigo_erp_tipo_venda character varying(20) NOT NULL,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.tabela_preco_tipo_venda FORCE ROW LEVEL SECURITY;


ALTER TABLE public.tabela_preco_tipo_venda OWNER TO epare;

--
-- Name: TABLE tabela_preco_tipo_venda; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.tabela_preco_tipo_venda IS 'Tipos de venda permitidos por tabela (N:N)';


--
-- Name: tabela_preco_tipo_venda_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.tabela_preco_tipo_venda_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tabela_preco_tipo_venda_codigo_seq OWNER TO epare;

--
-- Name: tabela_preco_tipo_venda_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.tabela_preco_tipo_venda_codigo_seq OWNED BY public.tabela_preco_tipo_venda.codigo;


--
-- Name: tabela_preco_unidade_negocio; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.tabela_preco_unidade_negocio (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_tabela_preco character varying(20) NOT NULL,
    codigo_erp_unidade_negocio character varying(20) NOT NULL,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.tabela_preco_unidade_negocio FORCE ROW LEVEL SECURITY;


ALTER TABLE public.tabela_preco_unidade_negocio OWNER TO epare;

--
-- Name: TABLE tabela_preco_unidade_negocio; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.tabela_preco_unidade_negocio IS 'Unidades de negócio onde a tabela está disponível (N:N)';


--
-- Name: tabela_preco_unidade_negocio_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.tabela_preco_unidade_negocio_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tabela_preco_unidade_negocio_codigo_seq OWNER TO epare;

--
-- Name: tabela_preco_unidade_negocio_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.tabela_preco_unidade_negocio_codigo_seq OWNED BY public.tabela_preco_unidade_negocio.codigo;


--
-- Name: tenant; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.tenant (
    cod_tenant integer NOT NULL,
    cod_revendedor integer NOT NULL,
    slug character varying(50),
    nome character varying(200) NOT NULL,
    cnpj character varying(18),
    email_contato character varying(200),
    telefone character varying(20),
    plano character varying(50) DEFAULT 'basico'::character varying,
    limite_empresas integer DEFAULT 1,
    limite_usuarios integer DEFAULT 5,
    ativo boolean DEFAULT true,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now(),
    dt_vencimento date,
    observacoes text
);


ALTER TABLE public.tenant OWNER TO epare;

--
-- Name: TABLE tenant; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.tenant IS 'Cliente do revendedor (quem opera o sistema no dia a dia)';


--
-- Name: COLUMN tenant.cod_revendedor; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.tenant.cod_revendedor IS 'A qual revendedor este tenant pertence';


--
-- Name: COLUMN tenant.slug; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.tenant.slug IS 'Opcional. Identificador amigável para URL (ex: distribuidora-joao)';


--
-- Name: tenant_cod_tenant_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.tenant_cod_tenant_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tenant_cod_tenant_seq OWNER TO epare;

--
-- Name: tenant_cod_tenant_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.tenant_cod_tenant_seq OWNED BY public.tenant.cod_tenant;


--
-- Name: tipo_frete; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.tipo_frete (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    descricao character varying(100),
    ativo boolean DEFAULT true,
    data_bloqueio date,
    motivo_bloqueio character varying(200),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.tipo_frete FORCE ROW LEVEL SECURITY;


ALTER TABLE public.tipo_frete OWNER TO epare;

--
-- Name: TABLE tipo_frete; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.tipo_frete IS 'Tipo de Frete (CIF, FOB, etc)';


--
-- Name: tipo_frete_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.tipo_frete_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_frete_codigo_seq OWNER TO epare;

--
-- Name: tipo_frete_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.tipo_frete_codigo_seq OWNED BY public.tipo_frete.codigo;


--
-- Name: tipo_venda; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.tipo_venda (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    descricao character varying(100),
    ativo boolean DEFAULT true,
    data_bloqueio date,
    motivo_bloqueio character varying(200),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.tipo_venda FORCE ROW LEVEL SECURITY;


ALTER TABLE public.tipo_venda OWNER TO epare;

--
-- Name: TABLE tipo_venda; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.tipo_venda IS 'Tipo de Venda (VENDA, CONSIGNAÇÃO, BONIFICAÇÃO, etc)';


--
-- Name: tipo_venda_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.tipo_venda_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_venda_codigo_seq OWNER TO epare;

--
-- Name: tipo_venda_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.tipo_venda_codigo_seq OWNED BY public.tipo_venda.codigo;


--
-- Name: tipo_venda_condicao_pagamento; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.tipo_venda_condicao_pagamento (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_tipo_venda character varying(20) NOT NULL,
    codigo_erp_condicao_pagamento character varying(20) NOT NULL,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.tipo_venda_condicao_pagamento FORCE ROW LEVEL SECURITY;


ALTER TABLE public.tipo_venda_condicao_pagamento OWNER TO epare;

--
-- Name: TABLE tipo_venda_condicao_pagamento; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.tipo_venda_condicao_pagamento IS 'Condições permitidas por tipo de venda (N:N)';


--
-- Name: tipo_venda_condicao_pagamento_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.tipo_venda_condicao_pagamento_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_venda_condicao_pagamento_codigo_seq OWNER TO epare;

--
-- Name: tipo_venda_condicao_pagamento_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.tipo_venda_condicao_pagamento_codigo_seq OWNED BY public.tipo_venda_condicao_pagamento.codigo;


--
-- Name: tipo_venda_unidade_negocio; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.tipo_venda_unidade_negocio (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    codigo_erp_tipo_venda character varying(20) NOT NULL,
    codigo_erp_unidade_negocio character varying(20) NOT NULL,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.tipo_venda_unidade_negocio FORCE ROW LEVEL SECURITY;


ALTER TABLE public.tipo_venda_unidade_negocio OWNER TO epare;

--
-- Name: TABLE tipo_venda_unidade_negocio; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.tipo_venda_unidade_negocio IS 'Unidades onde o tipo de venda está disponível (N:N)';


--
-- Name: tipo_venda_unidade_negocio_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.tipo_venda_unidade_negocio_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_venda_unidade_negocio_codigo_seq OWNER TO epare;

--
-- Name: tipo_venda_unidade_negocio_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.tipo_venda_unidade_negocio_codigo_seq OWNED BY public.tipo_venda_unidade_negocio.codigo;


--
-- Name: transportadora; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.transportadora (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    tipo_pessoa character(1),
    cnpj_cpf character varying(20),
    inscricao_estadual_rg character varying(20),
    nome_razao character varying(100),
    nome_fantasia character varying(100),
    ativo boolean DEFAULT true,
    data_bloqueio date,
    motivo_bloqueio character varying(200),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now(),
    CONSTRAINT ck_transportadora_tipo CHECK (((tipo_pessoa = ANY (ARRAY['F'::bpchar, 'J'::bpchar])) OR (tipo_pessoa IS NULL)))
);

ALTER TABLE ONLY public.transportadora FORCE ROW LEVEL SECURITY;


ALTER TABLE public.transportadora OWNER TO epare;

--
-- Name: TABLE transportadora; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.transportadora IS 'Cadastro de Transportadora';


--
-- Name: transportadora_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.transportadora_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transportadora_codigo_seq OWNER TO epare;

--
-- Name: transportadora_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.transportadora_codigo_seq OWNED BY public.transportadora.codigo;


--
-- Name: unidade_medida; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.unidade_medida (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    sigla character varying(20),
    descricao character varying(100),
    casas_decimais integer DEFAULT 0,
    tipo_leitura character varying(10),
    ativo boolean DEFAULT true,
    data_bloqueio date,
    motivo_bloqueio character varying(200),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.unidade_medida FORCE ROW LEVEL SECURITY;


ALTER TABLE public.unidade_medida OWNER TO epare;

--
-- Name: TABLE unidade_medida; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.unidade_medida IS 'Cadastro de Unidade de Medida';


--
-- Name: COLUMN unidade_medida.codigo_erp; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.unidade_medida.codigo_erp IS 'Código da unidade no ERP do cliente';


--
-- Name: COLUMN unidade_medida.ativo; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.unidade_medida.ativo IS 'NULL = usa padrão do sistema (equivalente ao ADM do ERP)';


--
-- Name: unidade_medida_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.unidade_medida_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.unidade_medida_codigo_seq OWNER TO epare;

--
-- Name: unidade_medida_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.unidade_medida_codigo_seq OWNED BY public.unidade_medida.codigo;


--
-- Name: unidade_negocio; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.unidade_negocio (
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    codigo integer NOT NULL,
    versao_layout character varying(10),
    codigo_erp character varying(20) NOT NULL,
    tipo_pessoa character(1),
    cnpj_cpf character varying(20),
    inscricao_estadual_rg character varying(20),
    nome_razao character varying(100),
    nome_fantasia character varying(100),
    cep character varying(10),
    tipo_logradouro character varying(50),
    logradouro character varying(100),
    numero_endereco character varying(20),
    complemento character varying(100),
    bairro character varying(100),
    cidade character varying(100),
    estado character(2),
    email_responsavel character varying(100),
    apelido_estoque character varying(100),
    telefone1 character varying(20),
    telefone2 character varying(20),
    ativo boolean DEFAULT true,
    data_bloqueio date,
    motivo_bloqueio character varying(200),
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now(),
    CONSTRAINT ck_unidade_negocio_tipo CHECK (((tipo_pessoa = ANY (ARRAY['F'::bpchar, 'J'::bpchar])) OR (tipo_pessoa IS NULL)))
);

ALTER TABLE ONLY public.unidade_negocio FORCE ROW LEVEL SECURITY;


ALTER TABLE public.unidade_negocio OWNER TO epare;

--
-- Name: TABLE unidade_negocio; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.unidade_negocio IS 'Unidade de Negócio (filial) do cliente';


--
-- Name: unidade_negocio_codigo_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.unidade_negocio_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.unidade_negocio_codigo_seq OWNER TO epare;

--
-- Name: unidade_negocio_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.unidade_negocio_codigo_seq OWNED BY public.unidade_negocio.codigo;


--
-- Name: usuario; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.usuario (
    cod_usuario integer NOT NULL,
    cod_tenant integer NOT NULL,
    email character varying(200) NOT NULL,
    senha_hash character varying(255) NOT NULL,
    nome character varying(200) NOT NULL,
    telefone character varying(20),
    cpf character varying(14),
    tipo character varying(20) DEFAULT 'vendedor'::character varying NOT NULL,
    ativo boolean DEFAULT true,
    ultimo_acesso timestamp with time zone,
    dt_inclusao timestamp with time zone DEFAULT now(),
    dt_alteracao timestamp with time zone DEFAULT now(),
    CONSTRAINT ck_usuario_tipo CHECK (((tipo)::text = ANY ((ARRAY['admin'::character varying, 'gerente'::character varying, 'vendedor'::character varying, 'supervisor'::character varying])::text[])))
);


ALTER TABLE public.usuario OWNER TO epare;

--
-- Name: TABLE usuario; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.usuario IS 'Usuário do app (login por email + senha)';


--
-- Name: COLUMN usuario.tipo; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.usuario.tipo IS 'admin=administra tenant, gerente=vê tudo, vendedor=opera, supervisor=equipe';


--
-- Name: usuario_cod_usuario_seq; Type: SEQUENCE; Schema: public; Owner: epare
--

CREATE SEQUENCE public.usuario_cod_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuario_cod_usuario_seq OWNER TO epare;

--
-- Name: usuario_cod_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: epare
--

ALTER SEQUENCE public.usuario_cod_usuario_seq OWNED BY public.usuario.cod_usuario;


--
-- Name: usuario_empresa; Type: TABLE; Schema: public; Owner: epare
--

CREATE TABLE public.usuario_empresa (
    cod_usuario integer NOT NULL,
    cod_tenant integer NOT NULL,
    cod_empresa integer NOT NULL,
    empresa_padrao boolean DEFAULT false,
    dt_inclusao timestamp with time zone DEFAULT now()
);


ALTER TABLE public.usuario_empresa OWNER TO epare;

--
-- Name: TABLE usuario_empresa; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON TABLE public.usuario_empresa IS 'Quais empresas cada usuário pode acessar (N:N)';


--
-- Name: COLUMN usuario_empresa.empresa_padrao; Type: COMMENT; Schema: public; Owner: epare
--

COMMENT ON COLUMN public.usuario_empresa.empresa_padrao IS 'Empresa que abre por padrão ao fazer login';


--
-- Name: categoria_item codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.categoria_item ALTER COLUMN codigo SET DEFAULT nextval('public.categoria_item_codigo_seq'::regclass);


--
-- Name: classificacao_fiscal codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.classificacao_fiscal ALTER COLUMN codigo SET DEFAULT nextval('public.classificacao_fiscal_codigo_seq'::regclass);


--
-- Name: cliente codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente ALTER COLUMN codigo SET DEFAULT nextval('public.cliente_codigo_seq'::regclass);


--
-- Name: cliente_campo_adicional codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_campo_adicional ALTER COLUMN codigo SET DEFAULT nextval('public.cliente_campo_adicional_codigo_seq'::regclass);


--
-- Name: cliente_condicao_pagamento codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_condicao_pagamento ALTER COLUMN codigo SET DEFAULT nextval('public.cliente_condicao_pagamento_codigo_seq'::regclass);


--
-- Name: cliente_conta_receber codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_conta_receber ALTER COLUMN codigo SET DEFAULT nextval('public.cliente_conta_receber_codigo_seq'::regclass);


--
-- Name: cliente_contato codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_contato ALTER COLUMN codigo SET DEFAULT nextval('public.cliente_contato_codigo_seq'::regclass);


--
-- Name: cliente_endereco_adicional codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_endereco_adicional ALTER COLUMN codigo SET DEFAULT nextval('public.cliente_endereco_adicional_codigo_seq'::regclass);


--
-- Name: cliente_forma_pagamento codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_forma_pagamento ALTER COLUMN codigo SET DEFAULT nextval('public.cliente_forma_pagamento_codigo_seq'::regclass);


--
-- Name: cliente_imposto codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_imposto ALTER COLUMN codigo SET DEFAULT nextval('public.cliente_imposto_codigo_seq'::regclass);


--
-- Name: cliente_representante codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_representante ALTER COLUMN codigo SET DEFAULT nextval('public.cliente_representante_codigo_seq'::regclass);


--
-- Name: cliente_rota_simples codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_rota_simples ALTER COLUMN codigo SET DEFAULT nextval('public.cliente_rota_simples_codigo_seq'::regclass);


--
-- Name: cliente_tabela_preco codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_tabela_preco ALTER COLUMN codigo SET DEFAULT nextval('public.cliente_tabela_preco_codigo_seq'::regclass);


--
-- Name: condicao_pagamento codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.condicao_pagamento ALTER COLUMN codigo SET DEFAULT nextval('public.condicao_pagamento_codigo_seq'::regclass);


--
-- Name: condicao_pagamento_forma codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.condicao_pagamento_forma ALTER COLUMN codigo SET DEFAULT nextval('public.condicao_pagamento_forma_codigo_seq'::regclass);


--
-- Name: condicao_pagamento_parcela codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.condicao_pagamento_parcela ALTER COLUMN codigo SET DEFAULT nextval('public.condicao_pagamento_parcela_codigo_seq'::regclass);


--
-- Name: condicao_pagamento_unidade codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.condicao_pagamento_unidade ALTER COLUMN codigo SET DEFAULT nextval('public.condicao_pagamento_unidade_codigo_seq'::regclass);


--
-- Name: customizador_dados codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.customizador_dados ALTER COLUMN codigo SET DEFAULT nextval('public.customizador_dados_codigo_seq'::regclass);


--
-- Name: embalagem_venda codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.embalagem_venda ALTER COLUMN codigo SET DEFAULT nextval('public.embalagem_venda_codigo_seq'::regclass);


--
-- Name: equipe_venda codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.equipe_venda ALTER COLUMN codigo SET DEFAULT nextval('public.equipe_venda_codigo_seq'::regclass);


--
-- Name: equipe_venda_categoria codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.equipe_venda_categoria ALTER COLUMN codigo SET DEFAULT nextval('public.equipe_venda_categoria_codigo_seq'::regclass);


--
-- Name: equipe_venda_item codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.equipe_venda_item ALTER COLUMN codigo SET DEFAULT nextval('public.equipe_venda_item_codigo_seq'::regclass);


--
-- Name: fabricante codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.fabricante ALTER COLUMN codigo SET DEFAULT nextval('public.fabricante_codigo_seq'::regclass);


--
-- Name: forma_pagamento codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.forma_pagamento ALTER COLUMN codigo SET DEFAULT nextval('public.forma_pagamento_codigo_seq'::regclass);


--
-- Name: forma_pagamento_unidade_negocio codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.forma_pagamento_unidade_negocio ALTER COLUMN codigo SET DEFAULT nextval('public.forma_pagamento_unidade_negocio_codigo_seq'::regclass);


--
-- Name: grupo_cliente codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.grupo_cliente ALTER COLUMN codigo SET DEFAULT nextval('public.grupo_cliente_codigo_seq'::regclass);


--
-- Name: item codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.item ALTER COLUMN codigo SET DEFAULT nextval('public.item_codigo_seq'::regclass);


--
-- Name: item_campo_adicional codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.item_campo_adicional ALTER COLUMN codigo SET DEFAULT nextval('public.item_campo_adicional_codigo_seq'::regclass);


--
-- Name: item_embalagem_venda codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.item_embalagem_venda ALTER COLUMN codigo SET DEFAULT nextval('public.item_embalagem_venda_codigo_seq'::regclass);


--
-- Name: item_estoque codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.item_estoque ALTER COLUMN codigo SET DEFAULT nextval('public.item_estoque_codigo_seq'::regclass);


--
-- Name: item_imposto codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.item_imposto ALTER COLUMN codigo SET DEFAULT nextval('public.item_imposto_codigo_seq'::regclass);


--
-- Name: item_unidade_negocio codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.item_unidade_negocio ALTER COLUMN codigo SET DEFAULT nextval('public.item_unidade_negocio_codigo_seq'::regclass);


--
-- Name: log_auditoria cod_log; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.log_auditoria ALTER COLUMN cod_log SET DEFAULT nextval('public.log_auditoria_cod_log_seq'::regclass);


--
-- Name: pedido codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.pedido ALTER COLUMN codigo SET DEFAULT nextval('public.pedido_codigo_seq'::regclass);


--
-- Name: pedido_historico codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.pedido_historico ALTER COLUMN codigo SET DEFAULT nextval('public.pedido_historico_codigo_seq'::regclass);


--
-- Name: pedido_item codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.pedido_item ALTER COLUMN codigo SET DEFAULT nextval('public.pedido_item_codigo_seq'::regclass);


--
-- Name: ramo_atividade codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.ramo_atividade ALTER COLUMN codigo SET DEFAULT nextval('public.ramo_atividade_codigo_seq'::regclass);


--
-- Name: representante codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.representante ALTER COLUMN codigo SET DEFAULT nextval('public.representante_codigo_seq'::regclass);


--
-- Name: representante_supervisor codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.representante_supervisor ALTER COLUMN codigo SET DEFAULT nextval('public.representante_supervisor_codigo_seq'::regclass);


--
-- Name: representante_tipo_venda codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.representante_tipo_venda ALTER COLUMN codigo SET DEFAULT nextval('public.representante_tipo_venda_codigo_seq'::regclass);


--
-- Name: revendedor cod_revendedor; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.revendedor ALTER COLUMN cod_revendedor SET DEFAULT nextval('public.revendedor_cod_revendedor_seq'::regclass);


--
-- Name: risco_cliente codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.risco_cliente ALTER COLUMN codigo SET DEFAULT nextval('public.risco_cliente_codigo_seq'::regclass);


--
-- Name: rota_simples codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.rota_simples ALTER COLUMN codigo SET DEFAULT nextval('public.rota_simples_codigo_seq'::regclass);


--
-- Name: tabela_preco codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco ALTER COLUMN codigo SET DEFAULT nextval('public.tabela_preco_codigo_seq'::regclass);


--
-- Name: tabela_preco_cliente codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco_cliente ALTER COLUMN codigo SET DEFAULT nextval('public.tabela_preco_cliente_codigo_seq'::regclass);


--
-- Name: tabela_preco_condicao_pagamento codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco_condicao_pagamento ALTER COLUMN codigo SET DEFAULT nextval('public.tabela_preco_condicao_pagamento_codigo_seq'::regclass);


--
-- Name: tabela_preco_grupo_cliente codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco_grupo_cliente ALTER COLUMN codigo SET DEFAULT nextval('public.tabela_preco_grupo_cliente_codigo_seq'::regclass);


--
-- Name: tabela_preco_item codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco_item ALTER COLUMN codigo SET DEFAULT nextval('public.tabela_preco_item_codigo_seq'::regclass);


--
-- Name: tabela_preco_representante codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco_representante ALTER COLUMN codigo SET DEFAULT nextval('public.tabela_preco_representante_codigo_seq'::regclass);


--
-- Name: tabela_preco_tipo_venda codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco_tipo_venda ALTER COLUMN codigo SET DEFAULT nextval('public.tabela_preco_tipo_venda_codigo_seq'::regclass);


--
-- Name: tabela_preco_unidade_negocio codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco_unidade_negocio ALTER COLUMN codigo SET DEFAULT nextval('public.tabela_preco_unidade_negocio_codigo_seq'::regclass);


--
-- Name: tenant cod_tenant; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tenant ALTER COLUMN cod_tenant SET DEFAULT nextval('public.tenant_cod_tenant_seq'::regclass);


--
-- Name: tipo_frete codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tipo_frete ALTER COLUMN codigo SET DEFAULT nextval('public.tipo_frete_codigo_seq'::regclass);


--
-- Name: tipo_venda codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tipo_venda ALTER COLUMN codigo SET DEFAULT nextval('public.tipo_venda_codigo_seq'::regclass);


--
-- Name: tipo_venda_condicao_pagamento codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tipo_venda_condicao_pagamento ALTER COLUMN codigo SET DEFAULT nextval('public.tipo_venda_condicao_pagamento_codigo_seq'::regclass);


--
-- Name: tipo_venda_unidade_negocio codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tipo_venda_unidade_negocio ALTER COLUMN codigo SET DEFAULT nextval('public.tipo_venda_unidade_negocio_codigo_seq'::regclass);


--
-- Name: transportadora codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.transportadora ALTER COLUMN codigo SET DEFAULT nextval('public.transportadora_codigo_seq'::regclass);


--
-- Name: unidade_medida codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.unidade_medida ALTER COLUMN codigo SET DEFAULT nextval('public.unidade_medida_codigo_seq'::regclass);


--
-- Name: unidade_negocio codigo; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.unidade_negocio ALTER COLUMN codigo SET DEFAULT nextval('public.unidade_negocio_codigo_seq'::regclass);


--
-- Name: usuario cod_usuario; Type: DEFAULT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.usuario ALTER COLUMN cod_usuario SET DEFAULT nextval('public.usuario_cod_usuario_seq'::regclass);


--
-- Name: flyway_schema_history flyway_schema_history_pk; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.flyway_schema_history
    ADD CONSTRAINT flyway_schema_history_pk PRIMARY KEY (installed_rank);


--
-- Name: log_auditoria log_auditoria_pkey; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.log_auditoria
    ADD CONSTRAINT log_auditoria_pkey PRIMARY KEY (cod_log);


--
-- Name: categoria_item pk_categoria_item; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.categoria_item
    ADD CONSTRAINT pk_categoria_item PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: classificacao_fiscal pk_classificacao_fiscal; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.classificacao_fiscal
    ADD CONSTRAINT pk_classificacao_fiscal PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: cliente pk_cliente; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT pk_cliente PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: cliente_campo_adicional pk_cliente_campo_adic; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_campo_adicional
    ADD CONSTRAINT pk_cliente_campo_adic PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: cliente_condicao_pagamento pk_cliente_cond_pag; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_condicao_pagamento
    ADD CONSTRAINT pk_cliente_cond_pag PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: cliente_conta_receber pk_cliente_conta_receber; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_conta_receber
    ADD CONSTRAINT pk_cliente_conta_receber PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: cliente_contato pk_cliente_contato; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_contato
    ADD CONSTRAINT pk_cliente_contato PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: cliente_endereco_adicional pk_cliente_endereco; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_endereco_adicional
    ADD CONSTRAINT pk_cliente_endereco PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: cliente_forma_pagamento pk_cliente_forma_pag; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_forma_pagamento
    ADD CONSTRAINT pk_cliente_forma_pag PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: cliente_imposto pk_cliente_imposto; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_imposto
    ADD CONSTRAINT pk_cliente_imposto PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: cliente_representante pk_cliente_representante; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_representante
    ADD CONSTRAINT pk_cliente_representante PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: cliente_rota_simples pk_cliente_rota; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_rota_simples
    ADD CONSTRAINT pk_cliente_rota PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: cliente_tabela_preco pk_cliente_tabela_preco; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_tabela_preco
    ADD CONSTRAINT pk_cliente_tabela_preco PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: condicao_pagamento_forma pk_cond_forma; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.condicao_pagamento_forma
    ADD CONSTRAINT pk_cond_forma PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: condicao_pagamento_parcela pk_cond_parcela; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.condicao_pagamento_parcela
    ADD CONSTRAINT pk_cond_parcela PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: condicao_pagamento_unidade pk_cond_und; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.condicao_pagamento_unidade
    ADD CONSTRAINT pk_cond_und PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: condicao_pagamento pk_condicao_pagamento; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.condicao_pagamento
    ADD CONSTRAINT pk_condicao_pagamento PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: customizador_dados pk_customizador_dados; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.customizador_dados
    ADD CONSTRAINT pk_customizador_dados PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: embalagem_venda pk_embalagem_venda; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.embalagem_venda
    ADD CONSTRAINT pk_embalagem_venda PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: empresa pk_empresa; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.empresa
    ADD CONSTRAINT pk_empresa PRIMARY KEY (cod_tenant, cod_empresa);


--
-- Name: equipe_venda_categoria pk_equipe_cat; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.equipe_venda_categoria
    ADD CONSTRAINT pk_equipe_cat PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: equipe_venda_item pk_equipe_item; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.equipe_venda_item
    ADD CONSTRAINT pk_equipe_item PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: equipe_venda pk_equipe_venda; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.equipe_venda
    ADD CONSTRAINT pk_equipe_venda PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: fabricante pk_fabricante; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.fabricante
    ADD CONSTRAINT pk_fabricante PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: forma_pagamento pk_forma_pagamento; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.forma_pagamento
    ADD CONSTRAINT pk_forma_pagamento PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: forma_pagamento_unidade_negocio pk_fp_und; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.forma_pagamento_unidade_negocio
    ADD CONSTRAINT pk_fp_und PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: grupo_cliente pk_grupo_cliente; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.grupo_cliente
    ADD CONSTRAINT pk_grupo_cliente PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: item pk_item; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.item
    ADD CONSTRAINT pk_item PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: item_campo_adicional pk_item_campo_adic; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.item_campo_adicional
    ADD CONSTRAINT pk_item_campo_adic PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: item_embalagem_venda pk_item_emb_venda; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.item_embalagem_venda
    ADD CONSTRAINT pk_item_emb_venda PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: item_estoque pk_item_estoque; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.item_estoque
    ADD CONSTRAINT pk_item_estoque PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: item_imposto pk_item_imposto; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.item_imposto
    ADD CONSTRAINT pk_item_imposto PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: item_unidade_negocio pk_item_und_neg; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.item_unidade_negocio
    ADD CONSTRAINT pk_item_und_neg PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: pedido pk_pedido; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.pedido
    ADD CONSTRAINT pk_pedido PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: pedido_historico pk_pedido_historico; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.pedido_historico
    ADD CONSTRAINT pk_pedido_historico PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: pedido_item pk_pedido_item; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.pedido_item
    ADD CONSTRAINT pk_pedido_item PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: ramo_atividade pk_ramo_atividade; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.ramo_atividade
    ADD CONSTRAINT pk_ramo_atividade PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: representante_supervisor pk_rep_supervisor; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.representante_supervisor
    ADD CONSTRAINT pk_rep_supervisor PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: representante_tipo_venda pk_rep_tipo_venda; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.representante_tipo_venda
    ADD CONSTRAINT pk_rep_tipo_venda PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: representante pk_representante; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.representante
    ADD CONSTRAINT pk_representante PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: risco_cliente pk_risco_cliente; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.risco_cliente
    ADD CONSTRAINT pk_risco_cliente PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: rota_simples pk_rota_simples; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.rota_simples
    ADD CONSTRAINT pk_rota_simples PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: tabela_preco_cliente pk_tab_cliente; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco_cliente
    ADD CONSTRAINT pk_tab_cliente PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: tabela_preco_condicao_pagamento pk_tab_cond_pag; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco_condicao_pagamento
    ADD CONSTRAINT pk_tab_cond_pag PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: tabela_preco_grupo_cliente pk_tab_grupo_cli; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco_grupo_cliente
    ADD CONSTRAINT pk_tab_grupo_cli PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: tabela_preco_representante pk_tab_preco_rep; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco_representante
    ADD CONSTRAINT pk_tab_preco_rep PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: tabela_preco_tipo_venda pk_tab_tipo_venda; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco_tipo_venda
    ADD CONSTRAINT pk_tab_tipo_venda PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: tabela_preco_unidade_negocio pk_tab_und_neg; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco_unidade_negocio
    ADD CONSTRAINT pk_tab_und_neg PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: tabela_preco pk_tabela_preco; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco
    ADD CONSTRAINT pk_tabela_preco PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: tabela_preco_item pk_tabela_preco_item; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco_item
    ADD CONSTRAINT pk_tabela_preco_item PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: tipo_frete pk_tipo_frete; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tipo_frete
    ADD CONSTRAINT pk_tipo_frete PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: tipo_venda pk_tipo_venda; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tipo_venda
    ADD CONSTRAINT pk_tipo_venda PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: transportadora pk_transportadora; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.transportadora
    ADD CONSTRAINT pk_transportadora PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: tipo_venda_condicao_pagamento pk_tv_cond; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tipo_venda_condicao_pagamento
    ADD CONSTRAINT pk_tv_cond PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: tipo_venda_unidade_negocio pk_tv_und; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tipo_venda_unidade_negocio
    ADD CONSTRAINT pk_tv_und PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: unidade_medida pk_unidade_medida; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.unidade_medida
    ADD CONSTRAINT pk_unidade_medida PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: unidade_negocio pk_unidade_negocio; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.unidade_negocio
    ADD CONSTRAINT pk_unidade_negocio PRIMARY KEY (cod_tenant, cod_empresa, codigo);


--
-- Name: usuario_empresa pk_usuario_empresa; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.usuario_empresa
    ADD CONSTRAINT pk_usuario_empresa PRIMARY KEY (cod_usuario, cod_tenant, cod_empresa);


--
-- Name: revendedor revendedor_pkey; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.revendedor
    ADD CONSTRAINT revendedor_pkey PRIMARY KEY (cod_revendedor);


--
-- Name: tenant tenant_pkey; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tenant
    ADD CONSTRAINT tenant_pkey PRIMARY KEY (cod_tenant);


--
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (cod_usuario);


--
-- Name: flyway_schema_history_s_idx; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX flyway_schema_history_s_idx ON public.flyway_schema_history USING btree (success);


--
-- Name: idx_categoria_item_pai; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_categoria_item_pai ON public.categoria_item USING btree (cod_tenant, cod_empresa, codigo_erp_pai);


--
-- Name: idx_cli_camp_cliente; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cli_camp_cliente ON public.cliente_campo_adicional USING btree (cod_tenant, cod_empresa, codigo_erp_cliente);


--
-- Name: idx_cli_cond_cliente; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cli_cond_cliente ON public.cliente_condicao_pagamento USING btree (cod_tenant, cod_empresa, codigo_erp_cliente);


--
-- Name: idx_cli_cond_cond; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cli_cond_cond ON public.cliente_condicao_pagamento USING btree (cod_tenant, cod_empresa, codigo_erp_condicao_pagamento);


--
-- Name: idx_cli_cont_cliente; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cli_cont_cliente ON public.cliente_contato USING btree (cod_tenant, cod_empresa, codigo_erp_cliente);


--
-- Name: idx_cli_end_cliente; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cli_end_cliente ON public.cliente_endereco_adicional USING btree (cod_tenant, cod_empresa, codigo_erp_cliente);


--
-- Name: idx_cli_forma_cliente; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cli_forma_cliente ON public.cliente_forma_pagamento USING btree (cod_tenant, cod_empresa, codigo_erp_cliente);


--
-- Name: idx_cli_forma_forma; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cli_forma_forma ON public.cliente_forma_pagamento USING btree (cod_tenant, cod_empresa, codigo_erp_forma_pagamento);


--
-- Name: idx_cli_imp_cliente; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cli_imp_cliente ON public.cliente_imposto USING btree (cod_tenant, cod_empresa, codigo_erp_cliente);


--
-- Name: idx_cli_rep_cliente; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cli_rep_cliente ON public.cliente_representante USING btree (cod_tenant, cod_empresa, codigo_erp_cliente);


--
-- Name: idx_cli_rep_representante; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cli_rep_representante ON public.cliente_representante USING btree (cod_tenant, cod_empresa, codigo_erp_representante);


--
-- Name: idx_cli_rota_cliente; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cli_rota_cliente ON public.cliente_rota_simples USING btree (cod_tenant, cod_empresa, codigo_erp_cliente);


--
-- Name: idx_cli_tab_cliente; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cli_tab_cliente ON public.cliente_tabela_preco USING btree (cod_tenant, cod_empresa, codigo_erp_cliente);


--
-- Name: idx_cli_tab_tabela; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cli_tab_tabela ON public.cliente_tabela_preco USING btree (cod_tenant, cod_empresa, codigo_erp_tabela_preco);


--
-- Name: idx_cliente_ativo; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cliente_ativo ON public.cliente USING btree (cod_tenant, cod_empresa, ativo);


--
-- Name: idx_cliente_cnpj; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cliente_cnpj ON public.cliente USING btree (cod_tenant, cod_empresa, cnpj_cpf);


--
-- Name: idx_cliente_cr_cliente; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cliente_cr_cliente ON public.cliente_conta_receber USING btree (cod_tenant, cod_empresa, codigo_erp_cliente);


--
-- Name: idx_cliente_cr_vencimento; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cliente_cr_vencimento ON public.cliente_conta_receber USING btree (cod_tenant, cod_empresa, data_vencimento);


--
-- Name: idx_cliente_grupo; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cliente_grupo ON public.cliente USING btree (cod_tenant, cod_empresa, codigo_erp_grupo_cliente);


--
-- Name: idx_cliente_nome; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cliente_nome ON public.cliente USING btree (cod_tenant, cod_empresa, nome_razao_social);


--
-- Name: idx_cliente_ramo; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cliente_ramo ON public.cliente USING btree (cod_tenant, cod_empresa, codigo_erp_ramo_atividade);


--
-- Name: idx_cond_forma_cond; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cond_forma_cond ON public.condicao_pagamento_forma USING btree (cod_tenant, cod_empresa, codigo_erp_condicao_pagamento);


--
-- Name: idx_cond_parc_cond; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cond_parc_cond ON public.condicao_pagamento_parcela USING btree (cod_tenant, cod_empresa, codigo_erp_condicao_pagamento);


--
-- Name: idx_cond_und_cond; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_cond_und_cond ON public.condicao_pagamento_unidade USING btree (cod_tenant, cod_empresa, codigo_erp_condicao_pagamento);


--
-- Name: idx_customizador_representante; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_customizador_representante ON public.customizador_dados USING btree (cod_tenant, cod_empresa, codigo_erp_representante);


--
-- Name: idx_empresa_ativo; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_empresa_ativo ON public.empresa USING btree (cod_tenant, ativo) WHERE (ativo = true);


--
-- Name: idx_empresa_tenant; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_empresa_tenant ON public.empresa USING btree (cod_tenant);


--
-- Name: idx_equipe_cat_equipe; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_equipe_cat_equipe ON public.equipe_venda_categoria USING btree (cod_tenant, cod_empresa, codigo_erp_equipe_venda);


--
-- Name: idx_equipe_item_equipe; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_equipe_item_equipe ON public.equipe_venda_item USING btree (cod_tenant, cod_empresa, codigo_erp_equipe_venda);


--
-- Name: idx_fp_und_forma; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_fp_und_forma ON public.forma_pagamento_unidade_negocio USING btree (cod_tenant, cod_empresa, codigo_erp_forma_pagamento);


--
-- Name: idx_item_ativo; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_item_ativo ON public.item USING btree (cod_tenant, cod_empresa, ativo);


--
-- Name: idx_item_camp_item; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_item_camp_item ON public.item_campo_adicional USING btree (cod_tenant, cod_empresa, codigo_erp_item);


--
-- Name: idx_item_categoria1; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_item_categoria1 ON public.item USING btree (cod_tenant, cod_empresa, codigo_erp_categoria_nivel1);


--
-- Name: idx_item_categoria2; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_item_categoria2 ON public.item USING btree (cod_tenant, cod_empresa, codigo_erp_categoria_nivel2);


--
-- Name: idx_item_emb_item; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_item_emb_item ON public.item_embalagem_venda USING btree (cod_tenant, cod_empresa, codigo_erp_item);


--
-- Name: idx_item_estoque_item; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_item_estoque_item ON public.item_estoque USING btree (cod_tenant, cod_empresa, codigo_erp_item);


--
-- Name: idx_item_estoque_unidade; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_item_estoque_unidade ON public.item_estoque USING btree (cod_tenant, cod_empresa, codigo_erp_unidade_negocio);


--
-- Name: idx_item_fabricante; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_item_fabricante ON public.item USING btree (cod_tenant, cod_empresa, codigo_erp_fabricante);


--
-- Name: idx_item_imp_item; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_item_imp_item ON public.item_imposto USING btree (cod_tenant, cod_empresa, codigo_erp_item);


--
-- Name: idx_item_und_item; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_item_und_item ON public.item_unidade_negocio USING btree (cod_tenant, cod_empresa, codigo_erp_item);


--
-- Name: idx_item_und_und; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_item_und_und ON public.item_unidade_negocio USING btree (cod_tenant, cod_empresa, codigo_erp_unidade_negocio);


--
-- Name: idx_item_unidade_medida; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_item_unidade_medida ON public.item USING btree (cod_tenant, cod_empresa, codigo_erp_unidade_medida);


--
-- Name: idx_log_acao; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_log_acao ON public.log_auditoria USING btree (acao, dt_evento DESC);


--
-- Name: idx_log_tabela; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_log_tabela ON public.log_auditoria USING btree (tabela, registro_id);


--
-- Name: idx_log_tenant; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_log_tenant ON public.log_auditoria USING btree (cod_tenant, dt_evento DESC);


--
-- Name: idx_log_usuario; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_log_usuario ON public.log_auditoria USING btree (cod_usuario, dt_evento DESC);


--
-- Name: idx_ped_hist_pedido; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_ped_hist_pedido ON public.pedido_historico USING btree (cod_tenant, cod_empresa, codigo_erp_pedido);


--
-- Name: idx_ped_item_pedido; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_ped_item_pedido ON public.pedido_item USING btree (cod_tenant, cod_empresa, codigo_erp_pedido);


--
-- Name: idx_ped_item_produto; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_ped_item_produto ON public.pedido_item USING btree (cod_tenant, cod_empresa, codigo_erp_produto);


--
-- Name: idx_pedido_cliente; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_pedido_cliente ON public.pedido USING btree (cod_tenant, cod_empresa, codigo_erp_cliente);


--
-- Name: idx_pedido_data_emissao; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_pedido_data_emissao ON public.pedido USING btree (cod_tenant, cod_empresa, data_emissao);


--
-- Name: idx_pedido_representante; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_pedido_representante ON public.pedido USING btree (cod_tenant, cod_empresa, codigo_erp_representante);


--
-- Name: idx_pedido_situacao; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_pedido_situacao ON public.pedido USING btree (cod_tenant, cod_empresa, situacao_pedido);


--
-- Name: idx_rep_sup_rep; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_rep_sup_rep ON public.representante_supervisor USING btree (cod_tenant, cod_empresa, codigo_erp_representante);


--
-- Name: idx_rep_tv_rep; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_rep_tv_rep ON public.representante_tipo_venda USING btree (cod_tenant, cod_empresa, codigo_erp_representante);


--
-- Name: idx_representante_cnpj; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_representante_cnpj ON public.representante USING btree (cod_tenant, cod_empresa, cnpj_cpf);


--
-- Name: idx_revendedor_ativo; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_revendedor_ativo ON public.revendedor USING btree (ativo) WHERE (ativo = true);


--
-- Name: idx_tab_cli_tabela; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_tab_cli_tabela ON public.tabela_preco_cliente USING btree (cod_tenant, cod_empresa, codigo_erp_tabela_preco);


--
-- Name: idx_tab_cond_tabela; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_tab_cond_tabela ON public.tabela_preco_condicao_pagamento USING btree (cod_tenant, cod_empresa, codigo_erp_tabela_preco);


--
-- Name: idx_tab_gc_tabela; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_tab_gc_tabela ON public.tabela_preco_grupo_cliente USING btree (cod_tenant, cod_empresa, codigo_erp_tabela_preco);


--
-- Name: idx_tab_preco_item_item; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_tab_preco_item_item ON public.tabela_preco_item USING btree (cod_tenant, cod_empresa, codigo_erp_item);


--
-- Name: idx_tab_preco_item_tabela; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_tab_preco_item_tabela ON public.tabela_preco_item USING btree (cod_tenant, cod_empresa, codigo_erp_tabela_preco);


--
-- Name: idx_tab_rep_tabela; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_tab_rep_tabela ON public.tabela_preco_representante USING btree (cod_tenant, cod_empresa, codigo_erp_tabela_preco);


--
-- Name: idx_tab_tv_tabela; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_tab_tv_tabela ON public.tabela_preco_tipo_venda USING btree (cod_tenant, cod_empresa, codigo_erp_tabela_preco);


--
-- Name: idx_tab_un_tabela; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_tab_un_tabela ON public.tabela_preco_unidade_negocio USING btree (cod_tenant, cod_empresa, codigo_erp_tabela_preco);


--
-- Name: idx_tenant_ativo; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_tenant_ativo ON public.tenant USING btree (ativo) WHERE (ativo = true);


--
-- Name: idx_tenant_revendedor; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_tenant_revendedor ON public.tenant USING btree (cod_revendedor);


--
-- Name: idx_transportadora_cnpj; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_transportadora_cnpj ON public.transportadora USING btree (cod_tenant, cod_empresa, cnpj_cpf);


--
-- Name: idx_tv_cond_tipo; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_tv_cond_tipo ON public.tipo_venda_condicao_pagamento USING btree (cod_tenant, cod_empresa, codigo_erp_tipo_venda);


--
-- Name: idx_tv_und_tipo; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_tv_und_tipo ON public.tipo_venda_unidade_negocio USING btree (cod_tenant, cod_empresa, codigo_erp_tipo_venda);


--
-- Name: idx_ue_empresa; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_ue_empresa ON public.usuario_empresa USING btree (cod_tenant, cod_empresa);


--
-- Name: idx_ue_usuario; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_ue_usuario ON public.usuario_empresa USING btree (cod_usuario);


--
-- Name: idx_usuario_ativo; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_usuario_ativo ON public.usuario USING btree (cod_tenant, ativo) WHERE (ativo = true);


--
-- Name: idx_usuario_tenant; Type: INDEX; Schema: public; Owner: epare
--

CREATE INDEX idx_usuario_tenant ON public.usuario USING btree (cod_tenant);


--
-- Name: uk_categoria_item_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_categoria_item_codigo_erp ON public.categoria_item USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_classificacao_fiscal_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_classificacao_fiscal_codigo_erp ON public.classificacao_fiscal USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_cliente_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_cliente_codigo_erp ON public.cliente USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_cliente_cr_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_cliente_cr_codigo_erp ON public.cliente_conta_receber USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_condicao_pagamento_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_condicao_pagamento_codigo_erp ON public.condicao_pagamento USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_embalagem_venda_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_embalagem_venda_codigo_erp ON public.embalagem_venda USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_empresa_cnpj; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_empresa_cnpj ON public.empresa USING btree (cod_tenant, cnpj);


--
-- Name: uk_empresa_slug; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_empresa_slug ON public.empresa USING btree (cod_tenant, slug) WHERE (slug IS NOT NULL);


--
-- Name: uk_equipe_venda_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_equipe_venda_codigo_erp ON public.equipe_venda USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_fabricante_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_fabricante_codigo_erp ON public.fabricante USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_forma_pagamento_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_forma_pagamento_codigo_erp ON public.forma_pagamento USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_grupo_cliente_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_grupo_cliente_codigo_erp ON public.grupo_cliente USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_item_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_item_codigo_erp ON public.item USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_item_estoque_unico; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_item_estoque_unico ON public.item_estoque USING btree (cod_tenant, cod_empresa, codigo_erp_unidade_negocio, codigo_erp_item);


--
-- Name: uk_pedido_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_pedido_codigo_erp ON public.pedido USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_ramo_atividade_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_ramo_atividade_codigo_erp ON public.ramo_atividade USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_representante_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_representante_codigo_erp ON public.representante USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_revendedor_cnpj; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_revendedor_cnpj ON public.revendedor USING btree (cnpj) WHERE (cnpj IS NOT NULL);


--
-- Name: uk_revendedor_dominio; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_revendedor_dominio ON public.revendedor USING btree (dominio_customizado) WHERE (dominio_customizado IS NOT NULL);


--
-- Name: uk_revendedor_slug; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_revendedor_slug ON public.revendedor USING btree (slug);


--
-- Name: uk_risco_cliente_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_risco_cliente_codigo_erp ON public.risco_cliente USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_rota_simples_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_rota_simples_codigo_erp ON public.rota_simples USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_tabela_preco_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_tabela_preco_codigo_erp ON public.tabela_preco USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_tenant_slug; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_tenant_slug ON public.tenant USING btree (slug) WHERE (slug IS NOT NULL);


--
-- Name: uk_tipo_frete_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_tipo_frete_codigo_erp ON public.tipo_frete USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_tipo_venda_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_tipo_venda_codigo_erp ON public.tipo_venda USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_transportadora_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_transportadora_codigo_erp ON public.transportadora USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_unidade_medida_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_unidade_medida_codigo_erp ON public.unidade_medida USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_unidade_negocio_codigo_erp; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_unidade_negocio_codigo_erp ON public.unidade_negocio USING btree (cod_tenant, cod_empresa, codigo_erp);


--
-- Name: uk_usuario_email; Type: INDEX; Schema: public; Owner: epare
--

CREATE UNIQUE INDEX uk_usuario_email ON public.usuario USING btree (cod_tenant, email);


--
-- Name: categoria_item tg_categoria_item_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_categoria_item_dt_alteracao BEFORE UPDATE ON public.categoria_item FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: classificacao_fiscal tg_classificacao_fiscal_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_classificacao_fiscal_dt_alteracao BEFORE UPDATE ON public.classificacao_fiscal FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: cliente_campo_adicional tg_cli_camp_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_cli_camp_dt_alteracao BEFORE UPDATE ON public.cliente_campo_adicional FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: cliente_condicao_pagamento tg_cli_cond_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_cli_cond_dt_alteracao BEFORE UPDATE ON public.cliente_condicao_pagamento FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: cliente_contato tg_cli_cont_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_cli_cont_dt_alteracao BEFORE UPDATE ON public.cliente_contato FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: cliente_endereco_adicional tg_cli_end_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_cli_end_dt_alteracao BEFORE UPDATE ON public.cliente_endereco_adicional FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: cliente_forma_pagamento tg_cli_forma_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_cli_forma_dt_alteracao BEFORE UPDATE ON public.cliente_forma_pagamento FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: cliente_imposto tg_cli_imp_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_cli_imp_dt_alteracao BEFORE UPDATE ON public.cliente_imposto FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: cliente_representante tg_cli_rep_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_cli_rep_dt_alteracao BEFORE UPDATE ON public.cliente_representante FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: cliente_rota_simples tg_cli_rota_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_cli_rota_dt_alteracao BEFORE UPDATE ON public.cliente_rota_simples FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: cliente_tabela_preco tg_cli_tab_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_cli_tab_dt_alteracao BEFORE UPDATE ON public.cliente_tabela_preco FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: cliente_conta_receber tg_cliente_conta_receber_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_cliente_conta_receber_dt_alteracao BEFORE UPDATE ON public.cliente_conta_receber FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: cliente tg_cliente_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_cliente_dt_alteracao BEFORE UPDATE ON public.cliente FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: condicao_pagamento_forma tg_cond_forma_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_cond_forma_dt_alteracao BEFORE UPDATE ON public.condicao_pagamento_forma FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: condicao_pagamento_parcela tg_cond_parc_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_cond_parc_dt_alteracao BEFORE UPDATE ON public.condicao_pagamento_parcela FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: condicao_pagamento_unidade tg_cond_und_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_cond_und_dt_alteracao BEFORE UPDATE ON public.condicao_pagamento_unidade FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: condicao_pagamento tg_condicao_pagamento_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_condicao_pagamento_dt_alteracao BEFORE UPDATE ON public.condicao_pagamento FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: customizador_dados tg_customizador_dados_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_customizador_dados_dt_alteracao BEFORE UPDATE ON public.customizador_dados FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: embalagem_venda tg_embalagem_venda_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_embalagem_venda_dt_alteracao BEFORE UPDATE ON public.embalagem_venda FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: empresa tg_empresa_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_empresa_dt_alteracao BEFORE UPDATE ON public.empresa FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: equipe_venda_categoria tg_equipe_cat_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_equipe_cat_dt_alteracao BEFORE UPDATE ON public.equipe_venda_categoria FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: equipe_venda_item tg_equipe_item_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_equipe_item_dt_alteracao BEFORE UPDATE ON public.equipe_venda_item FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: equipe_venda tg_equipe_venda_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_equipe_venda_dt_alteracao BEFORE UPDATE ON public.equipe_venda FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: fabricante tg_fabricante_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_fabricante_dt_alteracao BEFORE UPDATE ON public.fabricante FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: forma_pagamento tg_forma_pagamento_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_forma_pagamento_dt_alteracao BEFORE UPDATE ON public.forma_pagamento FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: forma_pagamento_unidade_negocio tg_fp_und_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_fp_und_dt_alteracao BEFORE UPDATE ON public.forma_pagamento_unidade_negocio FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: grupo_cliente tg_grupo_cliente_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_grupo_cliente_dt_alteracao BEFORE UPDATE ON public.grupo_cliente FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: item_campo_adicional tg_item_camp_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_item_camp_dt_alteracao BEFORE UPDATE ON public.item_campo_adicional FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: item tg_item_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_item_dt_alteracao BEFORE UPDATE ON public.item FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: item_embalagem_venda tg_item_emb_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_item_emb_dt_alteracao BEFORE UPDATE ON public.item_embalagem_venda FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: item_estoque tg_item_estoque_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_item_estoque_dt_alteracao BEFORE UPDATE ON public.item_estoque FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: item_imposto tg_item_imp_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_item_imp_dt_alteracao BEFORE UPDATE ON public.item_imposto FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: item_unidade_negocio tg_item_und_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_item_und_dt_alteracao BEFORE UPDATE ON public.item_unidade_negocio FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: pedido_historico tg_ped_hist_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_ped_hist_dt_alteracao BEFORE UPDATE ON public.pedido_historico FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: pedido_item tg_ped_item_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_ped_item_dt_alteracao BEFORE UPDATE ON public.pedido_item FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: pedido tg_pedido_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_pedido_dt_alteracao BEFORE UPDATE ON public.pedido FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: ramo_atividade tg_ramo_atividade_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_ramo_atividade_dt_alteracao BEFORE UPDATE ON public.ramo_atividade FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: representante_supervisor tg_rep_sup_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_rep_sup_dt_alteracao BEFORE UPDATE ON public.representante_supervisor FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: representante_tipo_venda tg_rep_tv_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_rep_tv_dt_alteracao BEFORE UPDATE ON public.representante_tipo_venda FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: representante tg_representante_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_representante_dt_alteracao BEFORE UPDATE ON public.representante FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: revendedor tg_revendedor_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_revendedor_dt_alteracao BEFORE UPDATE ON public.revendedor FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: risco_cliente tg_risco_cliente_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_risco_cliente_dt_alteracao BEFORE UPDATE ON public.risco_cliente FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: rota_simples tg_rota_simples_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_rota_simples_dt_alteracao BEFORE UPDATE ON public.rota_simples FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: tabela_preco_cliente tg_tab_cli_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_tab_cli_dt_alteracao BEFORE UPDATE ON public.tabela_preco_cliente FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: tabela_preco_condicao_pagamento tg_tab_cond_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_tab_cond_dt_alteracao BEFORE UPDATE ON public.tabela_preco_condicao_pagamento FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: tabela_preco_grupo_cliente tg_tab_gc_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_tab_gc_dt_alteracao BEFORE UPDATE ON public.tabela_preco_grupo_cliente FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: tabela_preco_representante tg_tab_rep_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_tab_rep_dt_alteracao BEFORE UPDATE ON public.tabela_preco_representante FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: tabela_preco_tipo_venda tg_tab_tv_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_tab_tv_dt_alteracao BEFORE UPDATE ON public.tabela_preco_tipo_venda FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: tabela_preco_unidade_negocio tg_tab_un_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_tab_un_dt_alteracao BEFORE UPDATE ON public.tabela_preco_unidade_negocio FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: tabela_preco tg_tabela_preco_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_tabela_preco_dt_alteracao BEFORE UPDATE ON public.tabela_preco FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: tabela_preco_item tg_tabela_preco_item_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_tabela_preco_item_dt_alteracao BEFORE UPDATE ON public.tabela_preco_item FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: tenant tg_tenant_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_tenant_dt_alteracao BEFORE UPDATE ON public.tenant FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: tipo_frete tg_tipo_frete_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_tipo_frete_dt_alteracao BEFORE UPDATE ON public.tipo_frete FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: tipo_venda tg_tipo_venda_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_tipo_venda_dt_alteracao BEFORE UPDATE ON public.tipo_venda FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: transportadora tg_transportadora_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_transportadora_dt_alteracao BEFORE UPDATE ON public.transportadora FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: tipo_venda_condicao_pagamento tg_tv_cond_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_tv_cond_dt_alteracao BEFORE UPDATE ON public.tipo_venda_condicao_pagamento FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: tipo_venda_unidade_negocio tg_tv_und_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_tv_und_dt_alteracao BEFORE UPDATE ON public.tipo_venda_unidade_negocio FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: unidade_medida tg_unidade_medida_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_unidade_medida_dt_alteracao BEFORE UPDATE ON public.unidade_medida FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: unidade_negocio tg_unidade_negocio_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_unidade_negocio_dt_alteracao BEFORE UPDATE ON public.unidade_negocio FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: usuario tg_usuario_dt_alteracao; Type: TRIGGER; Schema: public; Owner: epare
--

CREATE TRIGGER tg_usuario_dt_alteracao BEFORE UPDATE ON public.usuario FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


--
-- Name: categoria_item fk_categoria_item_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.categoria_item
    ADD CONSTRAINT fk_categoria_item_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: classificacao_fiscal fk_classificacao_fiscal_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.classificacao_fiscal
    ADD CONSTRAINT fk_classificacao_fiscal_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: cliente_campo_adicional fk_cli_camp_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_campo_adicional
    ADD CONSTRAINT fk_cli_camp_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: cliente_condicao_pagamento fk_cli_cond_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_condicao_pagamento
    ADD CONSTRAINT fk_cli_cond_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: cliente_contato fk_cli_cont_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_contato
    ADD CONSTRAINT fk_cli_cont_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: cliente_endereco_adicional fk_cli_end_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_endereco_adicional
    ADD CONSTRAINT fk_cli_end_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: cliente_forma_pagamento fk_cli_forma_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_forma_pagamento
    ADD CONSTRAINT fk_cli_forma_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: cliente_imposto fk_cli_imp_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_imposto
    ADD CONSTRAINT fk_cli_imp_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: cliente_representante fk_cli_rep_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_representante
    ADD CONSTRAINT fk_cli_rep_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: cliente_rota_simples fk_cli_rota_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_rota_simples
    ADD CONSTRAINT fk_cli_rota_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: cliente_tabela_preco fk_cli_tab_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_tabela_preco
    ADD CONSTRAINT fk_cli_tab_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: cliente_conta_receber fk_cliente_cr_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente_conta_receber
    ADD CONSTRAINT fk_cliente_cr_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: cliente fk_cliente_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT fk_cliente_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: condicao_pagamento_forma fk_cond_forma_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.condicao_pagamento_forma
    ADD CONSTRAINT fk_cond_forma_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: condicao_pagamento_parcela fk_cond_parc_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.condicao_pagamento_parcela
    ADD CONSTRAINT fk_cond_parc_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: condicao_pagamento_unidade fk_cond_und_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.condicao_pagamento_unidade
    ADD CONSTRAINT fk_cond_und_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: condicao_pagamento fk_condicao_pagamento_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.condicao_pagamento
    ADD CONSTRAINT fk_condicao_pagamento_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: customizador_dados fk_customizador_dados_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.customizador_dados
    ADD CONSTRAINT fk_customizador_dados_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: embalagem_venda fk_embalagem_venda_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.embalagem_venda
    ADD CONSTRAINT fk_embalagem_venda_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: empresa fk_empresa_tenant; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.empresa
    ADD CONSTRAINT fk_empresa_tenant FOREIGN KEY (cod_tenant) REFERENCES public.tenant(cod_tenant) ON DELETE CASCADE;


--
-- Name: equipe_venda_categoria fk_equipe_cat_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.equipe_venda_categoria
    ADD CONSTRAINT fk_equipe_cat_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: equipe_venda_item fk_equipe_item_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.equipe_venda_item
    ADD CONSTRAINT fk_equipe_item_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: equipe_venda fk_equipe_venda_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.equipe_venda
    ADD CONSTRAINT fk_equipe_venda_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: fabricante fk_fabricante_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.fabricante
    ADD CONSTRAINT fk_fabricante_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: forma_pagamento fk_forma_pagamento_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.forma_pagamento
    ADD CONSTRAINT fk_forma_pagamento_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: forma_pagamento_unidade_negocio fk_fp_und_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.forma_pagamento_unidade_negocio
    ADD CONSTRAINT fk_fp_und_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: grupo_cliente fk_grupo_cliente_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.grupo_cliente
    ADD CONSTRAINT fk_grupo_cliente_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: item_campo_adicional fk_item_camp_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.item_campo_adicional
    ADD CONSTRAINT fk_item_camp_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: item_embalagem_venda fk_item_emb_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.item_embalagem_venda
    ADD CONSTRAINT fk_item_emb_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: item fk_item_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.item
    ADD CONSTRAINT fk_item_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: item_estoque fk_item_estoque_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.item_estoque
    ADD CONSTRAINT fk_item_estoque_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: item_imposto fk_item_imp_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.item_imposto
    ADD CONSTRAINT fk_item_imp_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: item_unidade_negocio fk_item_und_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.item_unidade_negocio
    ADD CONSTRAINT fk_item_und_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: log_auditoria fk_log_tenant; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.log_auditoria
    ADD CONSTRAINT fk_log_tenant FOREIGN KEY (cod_tenant) REFERENCES public.tenant(cod_tenant) ON DELETE SET NULL;


--
-- Name: pedido_historico fk_ped_hist_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.pedido_historico
    ADD CONSTRAINT fk_ped_hist_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: pedido_item fk_ped_item_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.pedido_item
    ADD CONSTRAINT fk_ped_item_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: pedido fk_pedido_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.pedido
    ADD CONSTRAINT fk_pedido_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: ramo_atividade fk_ramo_atividade_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.ramo_atividade
    ADD CONSTRAINT fk_ramo_atividade_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: representante_supervisor fk_rep_sup_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.representante_supervisor
    ADD CONSTRAINT fk_rep_sup_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: representante_tipo_venda fk_rep_tv_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.representante_tipo_venda
    ADD CONSTRAINT fk_rep_tv_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: representante fk_representante_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.representante
    ADD CONSTRAINT fk_representante_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: risco_cliente fk_risco_cliente_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.risco_cliente
    ADD CONSTRAINT fk_risco_cliente_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: rota_simples fk_rota_simples_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.rota_simples
    ADD CONSTRAINT fk_rota_simples_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: tabela_preco_cliente fk_tab_cli_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco_cliente
    ADD CONSTRAINT fk_tab_cli_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: tabela_preco_condicao_pagamento fk_tab_cond_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco_condicao_pagamento
    ADD CONSTRAINT fk_tab_cond_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: tabela_preco_grupo_cliente fk_tab_gc_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco_grupo_cliente
    ADD CONSTRAINT fk_tab_gc_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: tabela_preco_representante fk_tab_rep_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco_representante
    ADD CONSTRAINT fk_tab_rep_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: tabela_preco_tipo_venda fk_tab_tv_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco_tipo_venda
    ADD CONSTRAINT fk_tab_tv_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: tabela_preco_unidade_negocio fk_tab_un_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco_unidade_negocio
    ADD CONSTRAINT fk_tab_un_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: tabela_preco fk_tabela_preco_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco
    ADD CONSTRAINT fk_tabela_preco_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: tabela_preco_item fk_tabela_preco_item_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tabela_preco_item
    ADD CONSTRAINT fk_tabela_preco_item_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: tenant fk_tenant_revendedor; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tenant
    ADD CONSTRAINT fk_tenant_revendedor FOREIGN KEY (cod_revendedor) REFERENCES public.revendedor(cod_revendedor) ON DELETE RESTRICT;


--
-- Name: tipo_frete fk_tipo_frete_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tipo_frete
    ADD CONSTRAINT fk_tipo_frete_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: tipo_venda fk_tipo_venda_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tipo_venda
    ADD CONSTRAINT fk_tipo_venda_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: transportadora fk_transportadora_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.transportadora
    ADD CONSTRAINT fk_transportadora_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: tipo_venda_condicao_pagamento fk_tv_cond_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tipo_venda_condicao_pagamento
    ADD CONSTRAINT fk_tv_cond_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: tipo_venda_unidade_negocio fk_tv_und_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.tipo_venda_unidade_negocio
    ADD CONSTRAINT fk_tv_und_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: usuario_empresa fk_ue_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.usuario_empresa
    ADD CONSTRAINT fk_ue_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: usuario_empresa fk_ue_usuario; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.usuario_empresa
    ADD CONSTRAINT fk_ue_usuario FOREIGN KEY (cod_usuario) REFERENCES public.usuario(cod_usuario) ON DELETE CASCADE;


--
-- Name: unidade_medida fk_unidade_medida_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.unidade_medida
    ADD CONSTRAINT fk_unidade_medida_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: unidade_negocio fk_unidade_negocio_empresa; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.unidade_negocio
    ADD CONSTRAINT fk_unidade_negocio_empresa FOREIGN KEY (cod_tenant, cod_empresa) REFERENCES public.empresa(cod_tenant, cod_empresa) ON DELETE CASCADE;


--
-- Name: usuario fk_usuario_tenant; Type: FK CONSTRAINT; Schema: public; Owner: epare
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT fk_usuario_tenant FOREIGN KEY (cod_tenant) REFERENCES public.tenant(cod_tenant) ON DELETE CASCADE;


--
-- Name: categoria_item; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.categoria_item ENABLE ROW LEVEL SECURITY;

--
-- Name: classificacao_fiscal; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.classificacao_fiscal ENABLE ROW LEVEL SECURITY;

--
-- Name: cliente; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.cliente ENABLE ROW LEVEL SECURITY;

--
-- Name: cliente_campo_adicional; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.cliente_campo_adicional ENABLE ROW LEVEL SECURITY;

--
-- Name: cliente_condicao_pagamento; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.cliente_condicao_pagamento ENABLE ROW LEVEL SECURITY;

--
-- Name: cliente_conta_receber; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.cliente_conta_receber ENABLE ROW LEVEL SECURITY;

--
-- Name: cliente_contato; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.cliente_contato ENABLE ROW LEVEL SECURITY;

--
-- Name: cliente_endereco_adicional; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.cliente_endereco_adicional ENABLE ROW LEVEL SECURITY;

--
-- Name: cliente_forma_pagamento; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.cliente_forma_pagamento ENABLE ROW LEVEL SECURITY;

--
-- Name: cliente_imposto; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.cliente_imposto ENABLE ROW LEVEL SECURITY;

--
-- Name: cliente_representante; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.cliente_representante ENABLE ROW LEVEL SECURITY;

--
-- Name: cliente_rota_simples; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.cliente_rota_simples ENABLE ROW LEVEL SECURITY;

--
-- Name: cliente_tabela_preco; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.cliente_tabela_preco ENABLE ROW LEVEL SECURITY;

--
-- Name: condicao_pagamento; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.condicao_pagamento ENABLE ROW LEVEL SECURITY;

--
-- Name: condicao_pagamento_forma; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.condicao_pagamento_forma ENABLE ROW LEVEL SECURITY;

--
-- Name: condicao_pagamento_parcela; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.condicao_pagamento_parcela ENABLE ROW LEVEL SECURITY;

--
-- Name: condicao_pagamento_unidade; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.condicao_pagamento_unidade ENABLE ROW LEVEL SECURITY;

--
-- Name: customizador_dados; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.customizador_dados ENABLE ROW LEVEL SECURITY;

--
-- Name: embalagem_venda; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.embalagem_venda ENABLE ROW LEVEL SECURITY;

--
-- Name: equipe_venda; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.equipe_venda ENABLE ROW LEVEL SECURITY;

--
-- Name: equipe_venda_categoria; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.equipe_venda_categoria ENABLE ROW LEVEL SECURITY;

--
-- Name: equipe_venda_item; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.equipe_venda_item ENABLE ROW LEVEL SECURITY;

--
-- Name: fabricante; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.fabricante ENABLE ROW LEVEL SECURITY;

--
-- Name: forma_pagamento; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.forma_pagamento ENABLE ROW LEVEL SECURITY;

--
-- Name: forma_pagamento_unidade_negocio; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.forma_pagamento_unidade_negocio ENABLE ROW LEVEL SECURITY;

--
-- Name: grupo_cliente; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.grupo_cliente ENABLE ROW LEVEL SECURITY;

--
-- Name: item; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.item ENABLE ROW LEVEL SECURITY;

--
-- Name: item_campo_adicional; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.item_campo_adicional ENABLE ROW LEVEL SECURITY;

--
-- Name: item_embalagem_venda; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.item_embalagem_venda ENABLE ROW LEVEL SECURITY;

--
-- Name: item_estoque; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.item_estoque ENABLE ROW LEVEL SECURITY;

--
-- Name: item_imposto; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.item_imposto ENABLE ROW LEVEL SECURITY;

--
-- Name: item_unidade_negocio; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.item_unidade_negocio ENABLE ROW LEVEL SECURITY;

--
-- Name: pedido; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.pedido ENABLE ROW LEVEL SECURITY;

--
-- Name: pedido_historico; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.pedido_historico ENABLE ROW LEVEL SECURITY;

--
-- Name: pedido_item; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.pedido_item ENABLE ROW LEVEL SECURITY;

--
-- Name: ramo_atividade; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.ramo_atividade ENABLE ROW LEVEL SECURITY;

--
-- Name: representante; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.representante ENABLE ROW LEVEL SECURITY;

--
-- Name: representante_supervisor; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.representante_supervisor ENABLE ROW LEVEL SECURITY;

--
-- Name: representante_tipo_venda; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.representante_tipo_venda ENABLE ROW LEVEL SECURITY;

--
-- Name: risco_cliente; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.risco_cliente ENABLE ROW LEVEL SECURITY;

--
-- Name: rota_simples; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.rota_simples ENABLE ROW LEVEL SECURITY;

--
-- Name: tabela_preco; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.tabela_preco ENABLE ROW LEVEL SECURITY;

--
-- Name: tabela_preco_cliente; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.tabela_preco_cliente ENABLE ROW LEVEL SECURITY;

--
-- Name: tabela_preco_condicao_pagamento; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.tabela_preco_condicao_pagamento ENABLE ROW LEVEL SECURITY;

--
-- Name: tabela_preco_grupo_cliente; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.tabela_preco_grupo_cliente ENABLE ROW LEVEL SECURITY;

--
-- Name: tabela_preco_item; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.tabela_preco_item ENABLE ROW LEVEL SECURITY;

--
-- Name: tabela_preco_representante; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.tabela_preco_representante ENABLE ROW LEVEL SECURITY;

--
-- Name: tabela_preco_tipo_venda; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.tabela_preco_tipo_venda ENABLE ROW LEVEL SECURITY;

--
-- Name: tabela_preco_unidade_negocio; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.tabela_preco_unidade_negocio ENABLE ROW LEVEL SECURITY;

--
-- Name: categoria_item tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.categoria_item USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: classificacao_fiscal tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.classificacao_fiscal USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: cliente tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.cliente USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: cliente_campo_adicional tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.cliente_campo_adicional USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: cliente_condicao_pagamento tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.cliente_condicao_pagamento USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: cliente_conta_receber tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.cliente_conta_receber USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: cliente_contato tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.cliente_contato USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: cliente_endereco_adicional tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.cliente_endereco_adicional USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: cliente_forma_pagamento tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.cliente_forma_pagamento USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: cliente_imposto tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.cliente_imposto USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: cliente_representante tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.cliente_representante USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: cliente_rota_simples tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.cliente_rota_simples USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: cliente_tabela_preco tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.cliente_tabela_preco USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: condicao_pagamento tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.condicao_pagamento USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: condicao_pagamento_forma tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.condicao_pagamento_forma USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: condicao_pagamento_parcela tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.condicao_pagamento_parcela USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: condicao_pagamento_unidade tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.condicao_pagamento_unidade USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: customizador_dados tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.customizador_dados USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: embalagem_venda tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.embalagem_venda USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: equipe_venda tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.equipe_venda USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: equipe_venda_categoria tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.equipe_venda_categoria USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: equipe_venda_item tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.equipe_venda_item USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: fabricante tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.fabricante USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: forma_pagamento tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.forma_pagamento USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: forma_pagamento_unidade_negocio tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.forma_pagamento_unidade_negocio USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: grupo_cliente tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.grupo_cliente USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: item tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.item USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: item_campo_adicional tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.item_campo_adicional USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: item_embalagem_venda tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.item_embalagem_venda USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: item_estoque tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.item_estoque USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: item_imposto tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.item_imposto USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: item_unidade_negocio tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.item_unidade_negocio USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: pedido tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.pedido USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: pedido_historico tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.pedido_historico USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: pedido_item tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.pedido_item USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: ramo_atividade tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.ramo_atividade USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: representante tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.representante USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: representante_supervisor tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.representante_supervisor USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: representante_tipo_venda tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.representante_tipo_venda USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: risco_cliente tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.risco_cliente USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: rota_simples tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.rota_simples USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: tabela_preco tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.tabela_preco USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: tabela_preco_cliente tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.tabela_preco_cliente USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: tabela_preco_condicao_pagamento tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.tabela_preco_condicao_pagamento USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: tabela_preco_grupo_cliente tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.tabela_preco_grupo_cliente USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: tabela_preco_item tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.tabela_preco_item USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: tabela_preco_representante tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.tabela_preco_representante USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: tabela_preco_tipo_venda tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.tabela_preco_tipo_venda USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: tabela_preco_unidade_negocio tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.tabela_preco_unidade_negocio USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: tipo_frete tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.tipo_frete USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: tipo_venda tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.tipo_venda USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: tipo_venda_condicao_pagamento tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.tipo_venda_condicao_pagamento USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: tipo_venda_unidade_negocio tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.tipo_venda_unidade_negocio USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: transportadora tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.transportadora USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: unidade_medida tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.unidade_medida USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: unidade_negocio tenant_isolation; Type: POLICY; Schema: public; Owner: epare
--

CREATE POLICY tenant_isolation ON public.unidade_negocio USING (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa())))) WITH CHECK (((cod_tenant = public.fn_current_tenant()) AND ((public.fn_current_empresa() IS NULL) OR (cod_empresa = public.fn_current_empresa()))));


--
-- Name: tipo_frete; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.tipo_frete ENABLE ROW LEVEL SECURITY;

--
-- Name: tipo_venda; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.tipo_venda ENABLE ROW LEVEL SECURITY;

--
-- Name: tipo_venda_condicao_pagamento; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.tipo_venda_condicao_pagamento ENABLE ROW LEVEL SECURITY;

--
-- Name: tipo_venda_unidade_negocio; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.tipo_venda_unidade_negocio ENABLE ROW LEVEL SECURITY;

--
-- Name: transportadora; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.transportadora ENABLE ROW LEVEL SECURITY;

--
-- Name: unidade_medida; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.unidade_medida ENABLE ROW LEVEL SECURITY;

--
-- Name: unidade_negocio; Type: ROW SECURITY; Schema: public; Owner: epare
--

ALTER TABLE public.unidade_negocio ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

\unrestrict B7pCuJmFY92L9jfcpLZ6ZgE4EpOK5ISE2ecnYXeSTuiXSBzJnkvC3m7vGdoOwFG

