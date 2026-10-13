-- ============================================================
-- V006 — Índices únicos adicionais (suporte a ON CONFLICT)
-- ============================================================
-- Por que: o V001 criou "slug" como nullable e sem UNIQUE.
-- Isso impede o uso de ON CONFLICT (slug) em seeds idempotentes.
-- Solução: adicionar índice único parcial (WHERE slug IS NOT NULL),
-- que já era a intenção original.
-- ============================================================

-- Revendedor: slug único
CREATE UNIQUE INDEX IF NOT EXISTS uk_revendedor_slug
    ON revendedor (slug)
    WHERE slug IS NOT NULL;

-- Tenant: slug único (global, não por revendedor)
CREATE UNIQUE INDEX IF NOT EXISTS uk_tenant_slug
    ON tenant (slug)
    WHERE slug IS NOT NULL;

-- Empresa: slug único dentro do tenant
CREATE UNIQUE INDEX IF NOT EXISTS uk_empresa_slug
    ON empresa (cod_tenant, slug)
    WHERE slug IS NOT NULL;

-- Usuario: email único dentro do tenant
CREATE UNIQUE INDEX IF NOT EXISTS uk_usuario_email
    ON usuario (cod_tenant, email);

-- Usuario_empresa: chave composta para ON CONFLICT DO NOTHING
-- (já tem PK, então ON CONFLICT DO NOTHING funciona sem coluna)