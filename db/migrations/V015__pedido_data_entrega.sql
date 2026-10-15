-- Adiciona data_entrega no cabeçalho do pedido.
-- Item com data própria sobrescreve. Item sem data herda do cabeçalho.

ALTER TABLE public.pedido
    ADD COLUMN data_entrega date;

COMMENT ON COLUMN public.pedido.data_entrega IS
    'Data de entrega prevista do pedido. Item com data própria sobrescreve.';