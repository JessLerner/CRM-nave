```sql
-- ============================================================
-- CRM DE LEADS - SUPABASE MVP v1.1
-- ============================================================
-- Arquitectura:
-- Empresa -> Sucursal -> Equipo -> Usuarios -> Leads
--
-- Este schema está pensado para:
-- - MVP inicial de 1 equipo
-- - Escalar posteriormente a Peugeot + Jeep
-- - 40/50+ vendedores
-- - RLS real en Supabase
-- - Trazabilidad de leads y asignaciones
-- ============================================================


-- ============================================================
-- 0. EXTENSIONES
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- ============================================================
-- 1. TIPOS / ENUMS
-- ============================================================

CREATE TYPE public.user_role AS ENUM (
  'admin',
  'supervisor',
  'salesperson'
);

CREATE TYPE public.lead_status AS ENUM (
  'new',
  'assigned',
  'contacting',
  'contacted',
  'interested',
  'follow_up',
  'interview_scheduled',
  'interview_done',
  'negotiation',
  'sold',
  'lost',
  'not_contacted',
  'invalid_data'
);

CREATE TYPE public.interaction_type AS ENUM (
  'call',
  'whatsapp',
  'note',
  'status_change',
  'reassignment'
);


-- ============================================================
-- 2. EMPRESAS
-- ============================================================

CREATE TABLE public.companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 3. SUCURSALES
-- ============================================================

CREATE TABLE public.branches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  company_id UUID NOT NULL
    REFERENCES public.companies(id)
    ON DELETE CASCADE,

  name TEXT NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_branches_company_id
ON public.branches(company_id);


-- ============================================================
-- 4. EQUIPOS
-- ============================================================

CREATE TABLE public.teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  branch_id UUID NOT NULL
    REFERENCES public.branches(id)
    ON DELETE CASCADE,

  name TEXT NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_teams_branch_id
ON public.teams(branch_id);


-- ============================================================
-- 5. PERFILES DE USUARIO
-- ============================================================

CREATE TABLE public.profiles (
  id UUID PRIMARY KEY
    REFERENCES auth.users(id)
    ON DELETE CASCADE,

  email TEXT NOT NULL,

  first_name TEXT,
  last_name TEXT,

  role public.user_role NOT NULL
    DEFAULT 'salesperson',

  team_id UUID
    REFERENCES public.teams(id)
    ON DELETE SET NULL,

  active BOOLEAN NOT NULL DEFAULT TRUE,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profiles_team_id
ON public.profiles(team_id);

CREATE INDEX idx_profiles_role
ON public.profiles(role);


-- ============================================================
-- 6. CREACIÓN AUTOMÁTICA DEL PERFIL
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN

  INSERT INTO public.profiles (
    id,
    email,
    first_name,
    last_name,
    role
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    'salesperson'
  );

  RETURN NEW;

END;
$$;


CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();


-- ============================================================
-- 7. FUENTES DE LEADS
-- ============================================================

CREATE TABLE public.lead_sources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  name TEXT NOT NULL,

  active BOOLEAN NOT NULL DEFAULT TRUE,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 8. MOTIVOS DE PÉRDIDA
-- ============================================================

CREATE TABLE public.loss_reasons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  name TEXT NOT NULL,

  active BOOLEAN NOT NULL DEFAULT TRUE,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 9. LEADS
-- ============================================================

CREATE TABLE public.leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  team_id UUID
    REFERENCES public.teams(id)
    ON DELETE SET NULL,

  first_name TEXT,
  last_name TEXT,

  phone TEXT,
  email TEXT,

  location TEXT,

  notes TEXT,

  source_id UUID
    REFERENCES public.lead_sources(id)
    ON DELETE SET NULL,

  source TEXT,

  campaign TEXT,
  ad_set TEXT,
  ad_name TEXT,

  status public.lead_status NOT NULL
    DEFAULT 'new',

  assigned_to UUID
    REFERENCES public.profiles(id)
    ON DELETE SET NULL,

  assigned_at TIMESTAMPTZ,

  first_contact_attempt_at TIMESTAMPTZ,

  first_contact_at TIMESTAMPTZ,

  loss_reason_id UUID
    REFERENCES public.loss_reasons(id)
    ON DELETE SET NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_leads_team_id
ON public.leads(team_id);

CREATE INDEX idx_leads_assigned_to
ON public.leads(assigned_to);

CREATE INDEX idx_leads_status
ON public.leads(status);

CREATE INDEX idx_leads_created_at
ON public.leads(created_at);

CREATE INDEX idx_leads_phone
ON public.leads(phone);


-- ============================================================
-- 10. HISTORIAL DE ASIGNACIONES
-- ============================================================

CREATE TABLE public.lead_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  lead_id UUID NOT NULL
    REFERENCES public.leads(id)
    ON DELETE CASCADE,

  from_user_id UUID
    REFERENCES public.profiles(id)
    ON DELETE SET NULL,

  to_user_id UUID
    REFERENCES public.profiles(id)
    ON DELETE SET NULL,

  assigned_by UUID
    REFERENCES public.profiles(id)
    ON DELETE SET NULL,

  assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  reason TEXT
);

CREATE INDEX idx_lead_assignments_lead_id
ON public.lead_assignments(lead_id);

CREATE INDEX idx_lead_assignments_to_user
ON public.lead_assignments(to_user_id);


-- ============================================================
-- 11. ACTIVIDADES
-- ============================================================

CREATE TABLE public.lead_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  lead_id UUID NOT NULL
    REFERENCES public.leads(id)
    ON DELETE CASCADE,

  user_id UUID
    REFERENCES public.profiles(id)
    ON DELETE SET NULL,

  type public.interaction_type NOT NULL,

  notes TEXT,

  old_status public.lead_status,

  new_status public.lead_status,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lead_activities_lead_id
ON public.lead_activities(lead_id);

CREATE INDEX idx_lead_activities_user_id
ON public.lead_activities(user_id);

CREATE INDEX idx_lead_activities_created_at
ON public.lead_activities(created_at);


-- ============================================================
-- 12. SEGUIMIENTOS
-- ============================================================

CREATE TABLE public.follow_ups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  lead_id UUID NOT NULL
    REFERENCES public.leads(id)
    ON DELETE CASCADE,

  user_id UUID NOT NULL
    REFERENCES public.profiles(id)
    ON DELETE CASCADE,

  scheduled_for TIMESTAMPTZ NOT NULL,

  completed BOOLEAN NOT NULL DEFAULT FALSE,

  completed_at TIMESTAMPTZ,

  notes TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_follow_ups_lead_id
ON public.follow_ups(lead_id);

CREATE INDEX idx_follow_ups_user_id
ON public.follow_ups(user_id);

CREATE INDEX idx_follow_ups_scheduled_for
ON public.follow_ups(scheduled_for);


-- ============================================================
-- 13. ACTUALIZACIÓN AUTOMÁTICA DE updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

  NEW.updated_at = NOW();

  RETURN NEW;

END;
$$;


CREATE TRIGGER set_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();


CREATE TRIGGER set_leads_updated_at
BEFORE UPDATE ON public.leads
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();


-- ============================================================
-- 14. FUNCIONES AUXILIARES DE SEGURIDAD
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_user_role(user_uid UUID)
RETURNS public.user_role
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT role
  FROM public.profiles
  WHERE id = user_uid;
$$;


CREATE OR REPLACE FUNCTION public.get_user_team(user_uid UUID)
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT team_id
  FROM public.profiles
  WHERE id = user_uid;
$$;


-- ============================================================
-- 15. ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lead_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loss_reasons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lead_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lead_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follow_ups ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- 16. COMPANIES
-- ============================================================

CREATE POLICY "authenticated_users_can_view_companies"
ON public.companies
FOR SELECT
TO authenticated
USING (TRUE);


CREATE POLICY "admins_can_manage_companies"
ON public.companies
FOR ALL
TO authenticated
USING (
  public.get_user_role(auth.uid()) = 'admin'
)
WITH CHECK (
  public.get_user_role(auth.uid()) = 'admin'
);


-- ============================================================
-- 17. BRANCHES
-- ============================================================

CREATE POLICY "authenticated_users_can_view_branches"
ON public.branches
FOR SELECT
TO authenticated
USING (TRUE);


CREATE POLICY "admins_can_manage_branches"
ON public.branches
FOR ALL
TO authenticated
USING (
  public.get_user_role(auth.uid()) = 'admin'
)
WITH CHECK (
  public.get_user_role(auth.uid()) = 'admin'
);


-- ============================================================
-- 18. TEAMS
-- ============================================================

CREATE POLICY "authenticated_users_can_view_teams"
ON public.teams
FOR SELECT
TO authenticated
USING (TRUE);


CREATE POLICY "admins_can_manage_teams"
ON public.teams
FOR ALL
TO authenticated
USING (
  public.get_user_role(auth.uid()) = 'admin'
)
WITH CHECK (
  public.get_user_role(auth.uid()) = 'admin'
);


-- ============================================================
-- 19. PROFILES
-- ============================================================

CREATE POLICY "users_can_view_relevant_profiles"
ON public.profiles
FOR SELECT
TO authenticated
USING (
  public.get_user_role(auth.uid()) = 'admin'
  OR id = auth.uid()
  OR team_id = public.get_user_team(auth.uid())
);


CREATE POLICY "admins_can_update_profiles"
ON public.profiles
FOR UPDATE
TO authenticated
USING (
  public.get_user_role(auth.uid()) = 'admin'
)
WITH CHECK (
  public.get_user_role(auth.uid()) = 'admin'
);


-- ============================================================
-- 20. LEAD SOURCES
-- ============================================================

CREATE POLICY "authenticated_users_can_view_lead_sources"
ON public.lead_sources
FOR SELECT
TO authenticated
USING (TRUE);


CREATE POLICY "admins_can_manage_lead_sources"
ON public.lead_sources
FOR ALL
TO authenticated
USING (
  public.get_user_role(auth.uid()) = 'admin'
)
WITH CHECK (
  public.get_user_role(auth.uid()) = 'admin'
);


-- ============================================================
-- 21. LOSS REASONS
-- ============================================================

CREATE POLICY "authenticated_users_can_view_loss_reasons"
ON public.loss_reasons
FOR SELECT
TO authenticated
USING (TRUE);


CREATE POLICY "admins_can_manage_loss_reasons"
ON public.loss_reasons
FOR ALL
TO authenticated
USING (
  public.get_user_role(auth.uid()) = 'admin'
)
WITH CHECK (
  public.get_user_role(auth.uid()) = 'admin'
);


-- ============================================================
-- 22. LEADS - ADMIN
-- ============================================================

CREATE POLICY "admins_can_view_all_leads"
ON public.leads
FOR SELECT
TO authenticated
USING (
  public.get_user_role(auth.uid()) = 'admin'
);


CREATE POLICY "admins_can_insert_leads"
ON public.leads
FOR INSERT
TO authenticated
WITH CHECK (
  public.get_user_role(auth.uid()) = 'admin'
);


CREATE POLICY "admins_can_update_all_leads"
ON public.leads
FOR UPDATE
TO authenticated
USING (
  public.get_user_role(auth.uid()) = 'admin'
)
WITH CHECK (
  public.get_user_role(auth.uid()) = 'admin'
);


-- ============================================================
-- 23. LEADS - SUPERVISOR
-- ============================================================

CREATE POLICY "supervisors_can_view_team_leads"
ON public.leads
FOR SELECT
TO authenticated
USING (
  public.get_user_role(auth.uid()) = 'supervisor'
  AND team_id = public.get_user_team(auth.uid())
);


CREATE POLICY "supervisors_can_insert_team_leads"
ON public.leads
FOR INSERT
TO authenticated
WITH CHECK (
  public.get_user_role(auth.uid()) = 'supervisor'
  AND team_id = public.get_user_team(auth.uid())
);


CREATE POLICY "supervisors_can_update_team_leads"
ON public.leads
FOR UPDATE
TO authenticated
USING (
  public.get_user_role(auth.uid()) = 'supervisor'
  AND team_id = public.get_user_team(auth.uid())
)
WITH CHECK (
  public.get_user_role(auth.uid()) = 'supervisor'
  AND team_id = public.get_user_team(auth.uid())
);


-- ============================================================
-- 24. LEADS - VENDEDOR
-- ============================================================

CREATE POLICY "salespeople_can_view_own_leads"
ON public.leads
FOR SELECT
TO authenticated
USING (
  public.get_user_role(auth.uid()) = 'salesperson'
  AND assigned_to = auth.uid()
);


CREATE POLICY "salespeople_can_insert_leads"
ON public.leads
FOR INSERT
TO authenticated
WITH CHECK (
  public.get_user_role(auth.uid()) = 'salesperson'
  AND team_id = public.get_user_team(auth.uid())
  AND assigned_to = auth.uid()
);


CREATE POLICY "salespeople_can_update_own_leads"
ON public.leads
FOR UPDATE
TO authenticated
USING (
  public.get_user_role(auth.uid()) = 'salesperson'
  AND assigned_to = auth.uid()
)
WITH CHECK (
  public.get_user_role(auth.uid()) = 'salesperson'
  AND assigned_to = auth.uid()
);


-- ============================================================
-- 25. LEAD ASSIGNMENTS
-- ============================================================

CREATE POLICY "users_can_view_relevant_assignments"
ON public.lead_assignments
FOR SELECT
TO authenticated
USING (
  public.get_user_role(auth.uid()) = 'admin'
  OR from_user_id = auth.uid()
  OR to_user_id = auth.uid()
  OR assigned_by = auth.uid()
);


CREATE POLICY "admins_can_create_assignments"
ON public.lead_assignments
FOR INSERT
TO authenticated
WITH CHECK (
  public.get_user_role(auth.uid()) = 'admin'
);


CREATE POLICY "supervisors_can_create_assignments"
ON public.lead_assignments
FOR INSERT
TO authenticated
WITH CHECK (
  public.get_user_role(auth.uid()) = 'supervisor'
  AND (
    to_user_id IN (
      SELECT id
      FROM public.profiles
      WHERE team_id = public.get_user_team(auth.uid())
    )
  )
);


-- ============================================================
-- 26. ACTIVIDADES
-- ============================================================

CREATE POLICY "users_can_view_relevant_activities"
ON public.lead_activities
FOR SELECT
TO authenticated
USING (
  public.get_user_role(auth.uid()) = 'admin'
  OR user_id = auth.uid()
  OR lead_id IN (
    SELECT id
    FROM public.leads
    WHERE assigned_to = auth.uid()
       OR team_id = public.get_user_team(auth.uid())
  )
);


CREATE POLICY "users_can_insert_own_activities"
ON public.lead_activities
FOR INSERT
TO authenticated
WITH CHECK (
  user_id = auth.uid()
  AND lead_id IN (
    SELECT id
    FROM public.leads
    WHERE assigned_to = auth.uid()
       OR team_id = public.get_user_team(auth.uid())
       OR public.get_user_role(auth.uid()) = 'admin'
  )
);


-- ============================================================
-- 27. FOLLOW UPS
-- ============================================================

CREATE POLICY "users_can_view_relevant_follow_ups"
ON public.follow_ups
FOR SELECT
TO authenticated
USING (
  public.get_user_role(auth.uid()) = 'admin'
  OR user_id = auth.uid()
  OR lead_id IN (
    SELECT id
    FROM public.leads
    WHERE team_id = public.get_user_team(auth.uid())
  )
);


CREATE POLICY "users_can_create_own_follow_ups"
ON public.follow_ups
FOR INSERT
TO authenticated
WITH CHECK (
  user_id = auth.uid()
  AND lead_id IN (
    SELECT id
    FROM public.leads
    WHERE assigned_to = auth.uid()
       OR team_id = public.get_user_team(auth.uid())
  )
);


CREATE POLICY "users_can_update_own_follow_ups"
ON public.follow_ups
FOR UPDATE
TO authenticated
USING (
  user_id = auth.uid()
)
WITH CHECK (
  user_id = auth.uid()
);


-- ============================================================
-- 28. DATOS INICIALES
-- ============================================================

INSERT INTO public.lead_sources (name)
VALUES
  ('Meta'),
  ('Web'),
  ('WhatsApp'),
  ('Referido'),
  ('Importación'),
  ('Manual'),
  ('Otro');


INSERT INTO public.loss_reasons (name)
VALUES
  ('Sin dinero'),
  ('Sin ingreso'),
  ('No responde'),
  ('Compró en otro lugar'),
  ('No interesado'),
  ('Precio'),
  ('Cuota'),
  ('Financiación'),
  ('Producto no adecuado'),
  ('Datos inválidos'),
  ('Duplicado'),
  ('Otro');


-- ============================================================
-- FIN DEL SCHEMA
-- ============================================================
```

