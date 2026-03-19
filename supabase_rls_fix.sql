-- ============================================================
-- DIAGNÓSTICO + FIX COMPLETO DE RLS
-- Ejecutar en Supabase SQL Editor
-- ============================================================

-- 1. Ver qué hay en las tablas
SELECT 'purchase_requests' AS tabla, COUNT(*) AS filas FROM purchase_requests
UNION ALL
SELECT 'request_items', COUNT(*) FROM request_items
UNION ALL
SELECT 'profiles', COUNT(*) FROM profiles;

-- 2. Ver políticas actuales
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE tablename IN ('purchase_requests','request_items','profiles','admin_alerts')
ORDER BY tablename, cmd;
