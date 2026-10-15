-- V009__agenda_tarefa.sql
-- Tabelas de agenda (visitas/compromissos) e tarefas do usuário.

-- ───────────────────────────── AGENDA ─────────────────────────────

CREATE SEQUENCE public.agenda_codigo_seq
    AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

ALTER SEQUENCE public.agenda_codigo_seq OWNER TO epare;

CREATE TABLE public.agenda (
    cod_tenant         integer      NOT NULL,
    cod_empresa        integer      NOT NULL,
    codigo             integer      NOT NULL DEFAULT nextval('public.agenda_codigo_seq'::regclass),
    cod_usuario        integer      NOT NULL,
    codigo_erp_cliente varchar(20),
    titulo             varchar(200) NOT NULL,
    descricao          text,
    data_agendada      date         NOT NULL,
    hora_agendada      time,
    concluida          boolean      NOT NULL DEFAULT false,
    dt_inclusao        timestamptz  NOT NULL DEFAULT now(),
    dt_alteracao       timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT pk_agenda PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT fk_agenda_empresa
        FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES public.empresa (cod_tenant, cod_empresa) ON DELETE CASCADE,
    CONSTRAINT fk_agenda_usuario
        FOREIGN KEY (cod_usuario)
        REFERENCES public.usuario (cod_usuario) ON DELETE CASCADE
);

ALTER SEQUENCE public.agenda_codigo_seq OWNED BY public.agenda.codigo;
ALTER TABLE public.agenda OWNER TO epare;

COMMENT ON TABLE public.agenda IS
    'Agenda de visitas/compromissos do representante.';

CREATE INDEX idx_agenda_usuario_data
    ON public.agenda (cod_tenant, cod_empresa, cod_usuario, data_agendada);

CREATE INDEX idx_agenda_concluida
    ON public.agenda (cod_tenant, cod_empresa, concluida);

ALTER TABLE public.agenda ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agenda FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON public.agenda
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

CREATE TRIGGER tg_agenda_dt_alteracao
    BEFORE UPDATE ON public.agenda
    FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();


-- ───────────────────────────── TAREFA ─────────────────────────────

CREATE SEQUENCE public.tarefa_codigo_seq
    AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

ALTER SEQUENCE public.tarefa_codigo_seq OWNER TO epare;

CREATE TABLE public.tarefa (
    cod_tenant    integer      NOT NULL,
    cod_empresa   integer      NOT NULL,
    codigo        integer      NOT NULL DEFAULT nextval('public.tarefa_codigo_seq'::regclass),
    cod_usuario   integer      NOT NULL,
    titulo        varchar(200) NOT NULL,
    descricao     text,
    prazo         date,
    prioridade    varchar(20)  NOT NULL DEFAULT 'media',
    concluida     boolean      NOT NULL DEFAULT false,
    dt_inclusao   timestamptz  NOT NULL DEFAULT now(),
    dt_alteracao  timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT pk_tarefa PRIMARY KEY (cod_tenant, cod_empresa, codigo),
    CONSTRAINT ck_tarefa_prioridade
        CHECK (prioridade IN ('baixa', 'media', 'alta')),
    CONSTRAINT fk_tarefa_empresa
        FOREIGN KEY (cod_tenant, cod_empresa)
        REFERENCES public.empresa (cod_tenant, cod_empresa) ON DELETE CASCADE,
    CONSTRAINT fk_tarefa_usuario
        FOREIGN KEY (cod_usuario)
        REFERENCES public.usuario (cod_usuario) ON DELETE CASCADE
);

ALTER SEQUENCE public.tarefa_codigo_seq OWNED BY public.tarefa.codigo;
ALTER TABLE public.tarefa OWNER TO epare;

COMMENT ON TABLE public.tarefa IS
    'Tarefas do usuário (a fazer, prazo, prioridade).';

CREATE INDEX idx_tarefa_usuario_prazo
    ON public.tarefa (cod_tenant, cod_empresa, cod_usuario, prazo);

CREATE INDEX idx_tarefa_concluida
    ON public.tarefa (cod_tenant, cod_empresa, concluida);

ALTER TABLE public.tarefa ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tarefa FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON public.tarefa
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

CREATE TRIGGER tg_tarefa_dt_alteracao
    BEFORE UPDATE ON public.tarefa
    FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_dt_alteracao();