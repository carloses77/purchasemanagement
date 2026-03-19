-- ============================================
-- SCHEMA DE BASE DE DATOS PARA COMPRAS BCN
-- Ejecutar en Supabase SQL Editor en orden
-- ============================================

-- 1. EXTENSIONES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TABLA DE DEPARTAMENTOS
CREATE TABLE departments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TABLA DE PERFILES DE USUARIO
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT,
  department_id UUID REFERENCES departments(id) ON SET NULL,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TABLA DE PETICIONES DE COMPRA
CREATE TABLE purchase_requests (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  estimated_cost NUMERIC(12,2) DEFAULT 0,
  needed_by DATE,
  admin_notes TEXT,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. TABLA DE ARTÍCULOS DE CADA PETICIÓN
CREATE TABLE request_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  request_id UUID NOT NULL REFERENCES purchase_requests(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price NUMERIC(12,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. ÍNDICES PARA RENDIMIENTO
CREATE INDEX idx_profiles_department ON profiles(department_id);
CREATE INDEX idx_purchase_requests_user ON purchase_requests(user_id);
CREATE INDEX idx_purchase_requests_department ON purchase_requests(department_id);
CREATE INDEX idx_purchase_requests_status ON purchase_requests(status);
CREATE INDEX idx_purchase_requests_created ON purchase_requests(created_at DESC);
CREATE INDEX idx_request_items_request ON request_items(request_id);

-- 7. FUNCIÓN PARA ACTUALIZAR updated_at AUTOMÁTICAMENTE
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_purchase_requests_updated_at
  BEFORE UPDATE ON purchase_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 8. FUNCIÓN PARA CREAR PERFIL AUTOMÁTICAMENTE AL REGISTRARSE
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, full_name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Usuario'),
    NEW.email
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, profiles.full_name);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 9. ROW LEVEL SECURITY (RLS)
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE request_items ENABLE ROW LEVEL SECURITY;

-- Departamentos: todos pueden leer, solo admin puede modificar
CREATE POLICY "Departamentos visibles para todos" ON departments
  FOR SELECT USING (true);

CREATE POLICY "Admin puede gestionar departamentos" ON departments
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
  );

-- Perfiles: usuario ve el suyo, admin ve todos
CREATE POLICY "Usuario ve su perfil" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Admin ve todos los perfiles" ON profiles
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
  );

CREATE POLICY "Usuario actualiza su perfil" ON profiles
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Admin actualiza cualquier perfil" ON profiles
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
  );

CREATE POLICY "Permitir inserción de perfil propio" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Peticiones: usuario ve las suyas, admin ve todas
CREATE POLICY "Usuario ve sus peticiones" ON purchase_requests
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admin ve todas las peticiones" ON purchase_requests
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
  );

CREATE POLICY "Usuario crea peticiones" ON purchase_requests
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admin actualiza peticiones" ON purchase_requests
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
  );

-- Artículos: visibles si ves la petición
CREATE POLICY "Ver artículos de tus peticiones" ON request_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM purchase_requests pr
      WHERE pr.id = request_items.request_id
      AND (pr.user_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin'))
    )
  );

CREATE POLICY "Insertar artículos en tus peticiones" ON request_items
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM purchase_requests pr
      WHERE pr.id = request_items.request_id AND pr.user_id = auth.uid()
    )
  );

-- 10. DATOS INICIALES: DEPARTAMENTOS DE BARCELONA
INSERT INTO departments (name) VALUES
  ('Operaciones'),
  ('Administración'),
  ('Comercial'),
  ('Recursos Humanos'),
  ('IT / Tecnología'),
  ('Finanzas'),
  ('Logística'),
  ('Almacén'),
  ('Dirección'),
  ('Marketing'),
  ('Atención al Cliente'),
  ('Calidad');

-- ============================================
-- NOTA: Después de ejecutar este SQL, crea un
-- usuario admin manualmente:
--
-- 1. Regístrate en la app normalmente
-- 2. En Supabase SQL Editor ejecuta:
--
-- UPDATE profiles
-- SET role = 'admin'
-- WHERE email = 'tu-email@ejemplo.com';
--
-- ============================================
