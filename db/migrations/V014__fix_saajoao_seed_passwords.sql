-- Corrige hashes placeholder dos usuários de demonstração do tenant saajoao.
-- Idempotente: só atua se o hash ainda for o placeholder (< 60 chars).

UPDATE public.usuario
SET senha_hash = crypt('123456', gen_salt('bf', 12))
WHERE email LIKE '%@saajoao.com.br'
  AND length(senha_hash) < 60;

COMMENT ON COLUMN public.usuario.senha_hash IS
    'Hash bcrypt via pgcrypto. Usuários de demo usam 123456.';
