-- Test data: 5 requests for admin + 4 for Alejandro Langa
-- Uses hardcoded UUIDs — adjust if profiles changed
-- Run in Supabase SQL Editor

-- Step 1: Fix CHECK constraint to accept Spanish status values
ALTER TABLE purchase_requests DROP CONSTRAINT IF EXISTS purchase_requests_status_check;
ALTER TABLE purchase_requests ADD CONSTRAINT purchase_requests_status_check
  CHECK (status IN ('pendiente', 'aprobada', 'rechazada', 'completada'));

-- Step 2: Insert test data
DO $$
DECLARE
  admin_id    UUID;
  alang_id    UUID;
  req_id      UUID;
BEGIN

  -- Get user IDs by role/name
  SELECT id INTO admin_id FROM profiles WHERE role = 'admin' LIMIT 1;
  SELECT id INTO alang_id FROM profiles WHERE full_name ILIKE '%alejandro%' LIMIT 1;

  IF admin_id IS NULL THEN
    RAISE EXCEPTION 'No admin user found in profiles table';
  END IF;

  -- ───────────────────────────────────────────────
  -- ADMIN: 5 peticiones (mixed statuses)
  -- ───────────────────────────────────────────────

  -- 1. Tóner impresora - aprobada
  INSERT INTO purchase_requests (user_id, department_id, title, description, category, priority, estimated_cost, status, created_at)
  VALUES (admin_id, (SELECT department_id FROM profiles WHERE id = admin_id),
    'Reposición tóner impresora HP', 'Stock de tóner agotado en planta baja.',
    'Impresión / Papelería', 'alta', 89.90, 'aprobada', now() - interval '5 days')
  RETURNING id INTO req_id;
  INSERT INTO request_items (request_id, name, quantity, unit_price)
  VALUES (req_id, 'Tóner HP LaserJet 26A Negro', 3, 29.97);

  -- 2. Sillas ergonómicas - pendiente
  INSERT INTO purchase_requests (user_id, department_id, title, description, category, priority, estimated_cost, status, created_at)
  VALUES (admin_id, (SELECT department_id FROM profiles WHERE id = admin_id),
    'Sillas ergonómicas sala de reuniones', 'Las 4 sillas actuales están deterioradas.',
    'Mobiliario', 'media', 960.00, 'pendiente', now() - interval '3 days')
  RETURNING id INTO req_id;
  INSERT INTO request_items (request_id, name, quantity, unit_price)
  VALUES (req_id, 'Silla ergonómica con reposabrazos', 4, 240.00);

  -- 3. Café y consumibles cocina - completada
  INSERT INTO purchase_requests (user_id, department_id, title, description, category, priority, estimated_cost, status, created_at)
  VALUES (admin_id, (SELECT department_id FROM profiles WHERE id = admin_id),
    'Suministros cocina oficina', 'Café, azúcar y vasos para la sala común.',
    'Alimentación / Catering', 'baja', 47.50, 'completada', now() - interval '10 days')
  RETURNING id INTO req_id;
  INSERT INTO request_items (request_id, name, quantity, unit_price)
  VALUES
    (req_id, 'Café molido 500g', 5, 6.50),
    (req_id, 'Azúcar monodosis (caja 200u)', 2, 4.75),
    (req_id, 'Vasos de cartón 200ml (pack 100)', 3, 5.50);

  -- 4. Ratones inalámbricos - rechazada
  INSERT INTO purchase_requests (user_id, department_id, title, description, category, priority, estimated_cost, status, admin_notes, created_at)
  VALUES (admin_id, (SELECT department_id FROM profiles WHERE id = admin_id),
    'Ratones inalámbricos nuevos equipos', 'Sustitución ratones con cable por inalámbricos.',
    'Informática / Tecnología', 'baja', 119.75, 'rechazada',
    'Pendiente revisión inventario IT. Reenviar en Q3.', now() - interval '8 days')
  RETURNING id INTO req_id;
  INSERT INTO request_items (request_id, name, quantity, unit_price)
  VALUES (req_id, 'Ratón inalámbrico Logitech M185', 5, 23.95);

  -- 5. Papelería trimestral - pendiente
  INSERT INTO purchase_requests (user_id, department_id, title, description, category, priority, estimated_cost, status, needed_by, created_at)
  VALUES (admin_id, (SELECT department_id FROM profiles WHERE id = admin_id),
    'Papelería trimestral Q2', 'Reposición de material básico de oficina para el trimestre.',
    'Material de Oficina', 'media', 134.20, 'pendiente', now() + interval '7 days', now() - interval '1 day')
  RETURNING id INTO req_id;
  INSERT INTO request_items (request_id, name, quantity, unit_price)
  VALUES
    (req_id, 'Folios A4 80g (caja 5 resmas)', 2, 28.50),
    (req_id, 'Bolígrafos BIC cristal (caja 50u)', 3, 8.90),
    (req_id, 'Carpetas archivadoras A4', 10, 3.95),
    (req_id, 'Post-it 76x76mm (pack 12)', 4, 7.20);

  -- ───────────────────────────────────────────────
  -- ALEJANDRO LANGA: 4 peticiones
  -- ───────────────────────────────────────────────

  IF alang_id IS NULL THEN
    RAISE NOTICE 'Usuario Alejandro no encontrado. Omitiendo sus peticiones.';
  ELSE

    -- 1. Monitores - pendiente
    INSERT INTO purchase_requests (user_id, department_id, title, description, category, priority, estimated_cost, status, created_at)
    VALUES (alang_id, (SELECT department_id FROM profiles WHERE id = alang_id),
      'Monitores adicionales equipo comercial', '3 monitores para ampliar pantalla de trabajo.',
      'Informática / Tecnología', 'alta', 689.97, 'pendiente', now() - interval '2 days')
    RETURNING id INTO req_id;
    INSERT INTO request_items (request_id, name, quantity, unit_price)
    VALUES (req_id, 'Monitor 27" Full HD LG 27MK430H', 3, 229.99);

    -- 2. Material higiene - completada
    INSERT INTO purchase_requests (user_id, department_id, title, description, category, priority, estimated_cost, status, created_at)
    VALUES (alang_id, (SELECT department_id FROM profiles WHERE id = alang_id),
      'Material higiene zona trabajo', 'Desinfectante de manos y guantes desechables.',
      'Limpieza / Higiene', 'media', 58.40, 'completada', now() - interval '12 days')
    RETURNING id INTO req_id;
    INSERT INTO request_items (request_id, name, quantity, unit_price)
    VALUES
      (req_id, 'Gel hidroalcohólico 500ml', 6, 4.90),
      (req_id, 'Guantes nitrilo talla M (caja 100u)', 2, 14.50);

    -- 3. Pizarra blanca - aprobada
    INSERT INTO purchase_requests (user_id, department_id, title, description, category, priority, estimated_cost, status, created_at)
    VALUES (alang_id, (SELECT department_id FROM profiles WHERE id = alang_id),
      'Pizarra blanca sala reuniones planta 2', 'Necesaria para sesiones de planificación semanal.',
      'Mobiliario', 'media', 189.00, 'aprobada', now() - interval '6 days')
    RETURNING id INTO req_id;
    INSERT INTO request_items (request_id, name, quantity, unit_price)
    VALUES
      (req_id, 'Pizarra blanca magnética 120x90cm', 1, 149.00),
      (req_id, 'Kit rotuladores pizarra (4 colores)', 4, 7.50),
      (req_id, 'Borrador magnético para pizarra', 2, 6.50);

    -- 4. Cables HDMI - pendiente urgente
    INSERT INTO purchase_requests (user_id, department_id, title, description, category, priority, estimated_cost, status, needed_by, created_at)
    VALUES (alang_id, (SELECT department_id FROM profiles WHERE id = alang_id),
      'Cables HDMI y adaptadores USB-C presentaciones', 'Faltan cables para sala de reuniones principal.',
      'Informática / Tecnología', 'urgente', 73.85, 'pendiente', now() + interval '3 days', now() - interval '12 hours')
    RETURNING id INTO req_id;
    INSERT INTO request_items (request_id, name, quantity, unit_price)
    VALUES
      (req_id, 'Cable HDMI 2.0 2m', 3, 12.95),
      (req_id, 'Adaptador USB-C a HDMI', 2, 14.50),
      (req_id, 'Hub USB-C 7 en 1', 1, 34.00);

  END IF;

END $$;

-- Verify
SELECT pr.title, pr.status, pr.priority, pr.estimated_cost, p.full_name
FROM purchase_requests pr
JOIN profiles p ON p.id = pr.user_id
ORDER BY pr.created_at DESC;
