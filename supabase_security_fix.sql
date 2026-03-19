-- ============================================
-- PARCHE DE SEGURIDAD - COMPRAS BCN
-- CRITICO: Corrige vulnerabilidad de escalada
-- de privilegios en la tabla profiles
-- ============================================

-- PROBLEMA: La politica "Usuario actualiza su perfil" permite
-- a cualquier usuario autenticado cambiar su propio campo "role"
-- a "admin", obteniendo acceso total al sistema.
--
-- SOLUCION: Reemplazar la politica para que los usuarios solo
-- puedan actualizar full_name y email, NO role ni department_id.
-- Solo los admins pueden cambiar roles y departamentos.

-- 1. Eliminar la politica vulnerable
DROP POLICY IF EXISTS "Usuario actualiza su perfil" ON profiles;

-- 2. Crear politica segura: usuarios solo actualizan campos seguros
-- (full_name, email) y NO pueden modificar role ni department_id
CREATE POLICY "Usuario actualiza datos basicos de su perfil" ON profiles
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id
    AND role = (SELECT p.role FROM profiles p WHERE p.id = auth.uid())
    AND department_id IS NOT DISTINCT FROM (SELECT p.department_id FROM profiles p WHERE p.id = auth.uid())
  );

-- 3. Verificar que la politica de admin sigue intacta
-- (Solo admin puede cambiar role y department_id)
-- Esta politica ya existe pero la recreamos por seguridad
DROP POLICY IF EXISTS "Admin actualiza cualquier perfil" ON profiles;
CREATE POLICY "Admin actualiza cualquier perfil" ON profiles
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
  );

-- ============================================
-- NOTA: Ejecutar este SQL en Supabase SQL Editor
-- Es CRITICO para entornos corporativos vigilados
-- ============================================
