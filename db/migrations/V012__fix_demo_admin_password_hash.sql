-- Replace the placeholder hash seeded for the demo administrator.
UPDATE public.usuario
SET senha_hash = crypt('123456', gen_salt('bf', 12))
WHERE lower(email) = lower('admin@epare.com.br')
  AND senha_hash = '$2b$12$EXEMPLO_HASH';
