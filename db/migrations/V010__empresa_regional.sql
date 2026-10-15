-- V010__empresa_regional.sql
-- Adiciona coluna "regional" na tabela empresa.
-- O front (ShellEmpresa.Regional) já consome esse campo.

ALTER TABLE public.empresa
    ADD COLUMN regional varchar(100);

COMMENT ON COLUMN public.empresa.regional IS
    'Regional comercial da empresa (ex: Sul, Sudeste, Nordeste).';