-- Adiciona coluna deletado_em nas tabelas que precisam de soft delete.
-- NULL = registro ativo. Diferente de "ativo" (estado no ERP).

ALTER TABLE public.cliente
    ADD COLUMN deletado_em timestamp with time zone;

ALTER TABLE public.cliente_endereco_adicional
    ADD COLUMN deletado_em timestamp with time zone;

ALTER TABLE public.agenda
    ADD COLUMN deletado_em timestamp with time zone;

ALTER TABLE public.tarefa
    ADD COLUMN deletado_em timestamp with time zone;

CREATE INDEX idx_cliente_deletado_em
    ON public.cliente (cod_tenant, cod_empresa, deletado_em)
    WHERE deletado_em IS NULL;

CREATE INDEX idx_cli_end_deletado_em
    ON public.cliente_endereco_adicional (cod_tenant, cod_empresa, deletado_em)
    WHERE deletado_em IS NULL;

CREATE INDEX idx_agenda_deletado_em
    ON public.agenda (cod_tenant, cod_empresa, deletado_em)
    WHERE deletado_em IS NULL;

CREATE INDEX idx_tarefa_deletado_em
    ON public.tarefa (cod_tenant, cod_empresa, deletado_em)
    WHERE deletado_em IS NULL;

COMMENT ON COLUMN public.cliente.deletado_em IS
    'Soft delete do app. NULL = ativo. Diferente de "ativo" (estado no ERP).';
