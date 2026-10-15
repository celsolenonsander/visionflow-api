-- V007__pedido_situacao_app.sql
-- Adiciona campo de fase do pedido no Força de Vendas,
-- distinto de situacao_pedido (status do ERP).

ALTER TABLE public.pedido
    ADD COLUMN situacao_app varchar(20) NOT NULL DEFAULT 'em_digitacao';

ALTER TABLE public.pedido
    ADD CONSTRAINT ck_pedido_situacao_app
    CHECK (situacao_app IN (
        'em_digitacao',
        'aguardando_aprovacao',
        'aprovado',
        'cancelado'
    ));

COMMENT ON COLUMN public.pedido.situacao_app IS
    'Fase do pedido no Força de Vendas. Distinto de situacao_pedido (status do ERP).';

-- Migração de dados: pedidos que vieram do ERP já estão aprovados
UPDATE public.pedido
SET situacao_app = 'aprovado'
WHERE situacao_pedido IS NOT NULL;

-- Índice para filtros por status no app
CREATE INDEX idx_pedido_situacao_app
    ON public.pedido (cod_tenant, cod_empresa, situacao_app);

-- RLS: a coluna herda a policy existente da tabela pedido, nada a fazer.
-- Trigger dt_alteracao: já existe na tabela, cobre automaticamente.