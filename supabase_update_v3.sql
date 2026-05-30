-- ============================================================
-- LOGITURNOS v3 — Script de atualização do banco
-- Cole no SQL Editor do Supabase e clique em Run
-- ============================================================

-- ── 1. NOVOS CAMPOS NO PERFIL ────────────────────────────────
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS cpf           TEXT,
  ADD COLUMN IF NOT EXISTS data_nascimento DATE,
  ADD COLUMN IF NOT EXISTS modal         TEXT DEFAULT 'Moto' CHECK (modal IN ('Bicicleta','Moto','Outro')),
  ADD COLUMN IF NOT EXISTS is_mei        BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS id_entregador TEXT;

-- Atualiza o check de role para incluir colaborador
ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_role_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_role_check
  CHECK (role IN ('admin','colaborador','entregador'));

-- ── 2. TABELA DE RELATÓRIOS (uploads) ────────────────────────
CREATE TABLE IF NOT EXISTS public.relatorios (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome_arquivo TEXT NOT NULL,
  data_ref     DATE NOT NULL,
  enviado_por  UUID NOT NULL REFERENCES public.profiles(id),
  criado_em    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 3. TABELA DE LINHAS DO RELATÓRIO ────────────────────────
CREATE TABLE IF NOT EXISTS public.relatorio_linhas (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  relatorio_id            UUID NOT NULL REFERENCES public.relatorios(id) ON DELETE CASCADE,
  id_entregador           TEXT,
  nome_completo           TEXT,
  data                    DATE,
  rank_entregador         NUMERIC,
  pct_tempo_online        NUMERIC,
  atribuidas              INTEGER,
  aceitas                 INTEGER,
  pct_aceitacao           NUMERIC,
  recusadas_total         INTEGER,
  recusadas_entregadores  INTEGER,
  pct_recusas_entregador  NUMERIC,
  recusadas_aut           INTEGER,
  pct_recusas_aut         NUMERIC,
  canceladas              INTEGER,
  pct_cancelamento        NUMERIC,
  entregues               INTEGER,
  pct_entregues           NUMERIC,
  pct_absenteismo         NUMERIC,
  score_performance       NUMERIC,
  classificacao_original  TEXT,
  entregas_por_hora       NUMERIC,
  entregas_por_turno      NUMERIC,
  qtd_turnos_contratados  INTEGER,
  qtd_turnos_off          INTEGER,
  qtd_turnos_to_zerado    INTEGER,
  -- Classificações calculadas pelo sistema
  nivel_tempo_online      TEXT,
  nivel_aceitacao         TEXT,
  nivel_geral             TEXT
);

-- ── 4. ATUALIZAR FUNCTION get_my_role PARA INCLUIR colaborador ──
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

-- ── 5. RLS PARA RELATÓRIOS ───────────────────────────────────

ALTER TABLE public.relatorios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.relatorio_linhas ENABLE ROW LEVEL SECURITY;

-- Admin e colaborador veem e gerenciam relatórios
CREATE POLICY "relatorios: admin e colaborador gerenciam"
  ON public.relatorios FOR ALL
  USING (public.get_my_role() IN ('admin','colaborador'));

CREATE POLICY "relatorio_linhas: admin e colaborador gerenciam"
  ON public.relatorio_linhas FOR ALL
  USING (public.get_my_role() IN ('admin','colaborador'));

-- Entregador vê apenas suas próprias linhas
CREATE POLICY "relatorio_linhas: entregador vê as próprias"
  ON public.relatorio_linhas FOR SELECT
  USING (
    id_entregador = (
      SELECT id_entregador FROM public.profiles WHERE id = auth.uid()
    )
  );

-- ── 6. RLS ATUALIZADO PARA PROFILES (inclui colaborador) ─────

DROP POLICY IF EXISTS "profiles: acesso próprio" ON public.profiles;
DROP POLICY IF EXISTS "profiles: admin acessa todos" ON public.profiles;
DROP POLICY IF EXISTS "profiles: admin gerencia todos" ON public.profiles;
DROP POLICY IF EXISTS "profiles: insert próprio" ON public.profiles;

CREATE POLICY "profiles: acesso próprio"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "profiles: admin e colaborador veem todos"
  ON public.profiles FOR SELECT
  USING (public.get_my_role() IN ('admin','colaborador'));

CREATE POLICY "profiles: admin gerencia tudo"
  ON public.profiles FOR ALL
  USING (public.get_my_role() = 'admin');

CREATE POLICY "profiles: colaborador edita entregadores"
  ON public.profiles FOR UPDATE
  USING (
    public.get_my_role() = 'colaborador'
    AND role = 'entregador'
  );

CREATE POLICY "profiles: colaborador cadastra entregadores"
  ON public.profiles FOR INSERT
  WITH CHECK (
    public.get_my_role() IN ('admin','colaborador')
    OR auth.uid() = id
  );

-- ── 7. RLS ATUALIZADO PARA SOLICITAÇÕES (colaborador aprova) ──

DROP POLICY IF EXISTS "solicitacoes: próprias" ON public.solicitacoes;
DROP POLICY IF EXISTS "solicitacoes: inserir própria" ON public.solicitacoes;
DROP POLICY IF EXISTS "solicitacoes: admin tudo" ON public.solicitacoes;
DROP POLICY IF EXISTS "solicitacoes: aprovadas visíveis" ON public.solicitacoes;

CREATE POLICY "solicitacoes: próprias"
  ON public.solicitacoes FOR SELECT
  USING (auth.uid() = usuario_id);

CREATE POLICY "solicitacoes: inserir própria"
  ON public.solicitacoes FOR INSERT
  WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "solicitacoes: admin e colaborador gerenciam"
  ON public.solicitacoes FOR ALL
  USING (public.get_my_role() IN ('admin','colaborador'));

CREATE POLICY "solicitacoes: aprovadas visíveis"
  ON public.solicitacoes FOR SELECT
  USING (status = 'aprovado');

-- ── 8. COMO CRIAR UM COLABORADOR ─────────────────────────────
-- Após criar o usuário no Supabase Auth, rode:
--
-- UPDATE public.profiles
-- SET role = 'colaborador', nome = 'Nome do Colaborador'
-- WHERE email = 'colaborador@email.com';
--
-- ── CONCLUÍDO ─────────────────────────────────────────────────
