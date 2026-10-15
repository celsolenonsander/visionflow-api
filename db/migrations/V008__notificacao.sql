-- V008__notificacao.sql
-- Tabela de notificações/avisos do app (painel superior + Home).

CREATE SEQUENCE public.notificacao_codigo_seq
    AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

ALTER SEQUENCE public.notificacao_codigo_seq OWNER TO epare;

CREATE TABLE public.notificacao (
    cod_tenant    integer      NOT NULL,
    cod_empresa   integer      NOT NULL,
    codigo        integer      NOT NULL DEFAULT nextval('public.notificacao_codigo_seq'::regclass),
    cod_usuario   integer      NOT NULL,
    titulo        varchar(200) NOT NULL,
    mensagem      text,
    tipo          varchar(50),                 -- 'pedido_aprovado', 'titulo_vencido', etc.
    lida          boolean      NOT NULL DEFAULT false,
    data_evento   timestamptz  NOT NULL DEFAULT now(),
    origem_tabela varchar(50),                 -- ex: 'pedido', 'cliente_conta_receber'
    origem_id     integer,                     -- codigo na tabela origem
    dt_inclusao   timestamptz  NOT NULL DEFAULT now(),
    dt_alteracao  timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT pk_notificacao PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_notificacao_empresa
        FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES public.empresa (cod_tenant, cod_empresa) ON DELETE CASCADE,
    CONSTRAINT fk_notificacao_usuario
        FOREIGN KEY (cod_usuario)
        REFERENCES public.usuario (cod_usuario) ON DELETE CASCADE
);

ALTER SEQUENCE public.notificacao_codigo_seq
    OWNED BY public.notificacao.codigo;

ALTER TABLE public.notificacao OWNER TO epare;

COMMENT ON TABLE public.notificacao IS
    'Notificações/avisos exibidos no app (painel superior e Home).';

COMMENT ON COLUMN public.notificacao.lida IS
    'FALSE = não lida (aparece no contador do badge).';

-- Índices
CREATE INDEX idx_notificacao_usuario
    ON public.notificacao (cod_tenant, cod_empresa, cod_usuario, lida);

CREATE INDEX idx_notificacao_data
    ON public.notificacao (cod_tenant, cod_empresa, data_evento DESC);

-- RLS
ALTER TABLE public.notificacao ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notificacao FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON public.notificacao
    USING (
        cod_tenant = public.fn_current_tenant()
        AND (public.fn_current_empresa() IS NULL
             OR cod_empresa = public.fn_current_empresa())
    )
    WITH CHECK (
        cod_tenant = public.fn_current_tenant()
        AND (public.fn_current_empresa() IS NULL
             OR cod_empresa = public.fn_current_empresa())
    );

-- Trigger de dt_alteracao (reusa a função existente)
CREATE TRIGGER tg_notificacao_dt_alteracao
    BEFORE UPDATE ON public.notificacao
    FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();