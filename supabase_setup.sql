-- ============================================================
-- LOGITURNOS — Script de criação do banco de dados (Supabase)
-- Cole este script inteiro no SQL Editor do Supabase e clique em Run
-- ============================================================


-- ── 1. TABELA DE PERFIS ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id         UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nome       TEXT NOT NULL,
  email      TEXT,
  telefone   TEXT,
  role       TEXT NOT NULL DEFAULT 'entregador' CHECK (role IN ('admin', 'entregador')),
  score      NUMERIC(5,2) NOT NULL DEFAULT 70,
  criado_em  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 2. TABELA DE TURNOS ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.turnos (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome            TEXT NOT NULL,
  horario_inicio  TIME NOT NULL,
  horario_fim     TIME NOT NULL,
  vagas           INTEGER NOT NULL DEFAULT 5,
  criado_em       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 3. TABELA DE SOLICITAÇÕES ────────────────────────────────
CREATE TABLE IF NOT EXISTS public.solicitacoes (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  turno_id     UUID NOT NULL REFERENCES public.turnos(id) ON DELETE CASCADE,
  dia_semana   INTEGER NOT NULL CHECK (dia_semana BETWEEN 0 AND 6),
  status       TEXT NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','aprovado','recusado')),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(usuario_id, turno_id, dia_semana)
);

-- ── 4. TABELA DE PERFORMANCE ─────────────────────────────────
CREATE TABLE IF NOT EXISTS public.performance (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id          UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  mes                 TEXT NOT NULL,           -- formato: "2024-01"
  entregas_prazo      NUMERIC(5,2) NOT NULL,   -- percentual 0-100
  avaliacao_cliente   NUMERIC(4,2) NOT NULL,   -- nota 0-10
  assiduidade         NUMERIC(5,2) NOT NULL,   -- percentual 0-100
  score               NUMERIC(5,2) NOT NULL,   -- calculado
  criado_em           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(usuario_id, mes)
);


-- ============================================================
-- SEGURANÇA: Row Level Security (RLS)
-- Protege os dados para que cada usuário veja apenas o que deve
-- ============================================================

ALTER TABLE public.profiles     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.turnos       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.solicitacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance  ENABLE ROW LEVEL SECURITY;

-- ── PROFILES ─────────────────────────────────────────────────
-- Usuário vê seu próprio perfil; admin vê todos
CREATE POLICY "profiles: usuario vê o próprio" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "profiles: admin vê todos" ON public.profiles
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "profiles: admin gerencia" ON public.profiles
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ── TURNOS ───────────────────────────────────────────────────
-- Todos os autenticados veem os turnos; só admin gerencia
CREATE POLICY "turnos: todos veem" ON public.turnos
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "turnos: admin gerencia" ON public.turnos
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ── SOLICITAÇÕES ─────────────────────────────────────────────
CREATE POLICY "solicitacoes: entregador vê as próprias" ON public.solicitacoes
  FOR SELECT USING (auth.uid() = usuario_id);

CREATE POLICY "solicitacoes: entregador insere" ON public.solicitacoes
  FOR INSERT WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "solicitacoes: admin vê todas" ON public.solicitacoes
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "solicitacoes: admin atualiza" ON public.solicitacoes
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "solicitacoes: todos veem aprovadas (para contar vagas)" ON public.solicitacoes
  FOR SELECT USING (status = 'aprovado');

-- ── PERFORMANCE ──────────────────────────────────────────────
CREATE POLICY "performance: entregador vê a própria" ON public.performance
  FOR SELECT USING (auth.uid() = usuario_id);

CREATE POLICY "performance: admin gerencia" ON public.performance
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );


-- ============================================================
-- TRIGGER: cria o perfil automaticamente quando um usuário
-- se registra via auth (para não precisar fazer isso manualmente)
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, nome, email, role, score)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'nome', split_part(NEW.email, '@', 1)),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'entregador'),
    70
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ============================================================
-- DADOS INICIAIS: Turnos padrão para começar
-- (você pode deletar ou editar pelo painel admin depois)
-- ============================================================

INSERT INTO public.turnos (nome, horario_inicio, horario_fim, vagas) VALUES
  ('Manhã',    '08:00:00', '14:00:00', 5),
  ('Tarde',    '14:00:00', '20:00:00', 5),
  ('Noite',    '20:00:00', '02:00:00', 3),
  ('Integral', '08:00:00', '18:00:00', 2)
ON CONFLICT DO NOTHING;


-- ============================================================
-- APÓS RODAR ESTE SCRIPT:
--
-- 1. Vá em Authentication > Users > Invite User
-- 2. Use seu e-mail para criar o primeiro usuário
-- 3. Rode o SQL abaixo (SUBSTITUA pelo seu email):
--
--    UPDATE public.profiles
--    SET role = 'admin', nome = 'Seu Nome Aqui'
--    WHERE email = 'seu@email.com';
--
-- 4. Acesse o sistema, logue e comece a cadastrar entregadores!
-- ============================================================
