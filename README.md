# LogiTurnos — Sistema de Gestão de Escalas

Sistema web completo para controle de turnos de entregadores com sistema de prioridade por performance.

---

## Arquivos deste projeto

| Arquivo | Descrição |
|---|---|
| `index.html` | O sistema completo (frontend + lógica) |
| `supabase_setup.sql` | Script para criar o banco de dados |
| `README.md` | Este guia de instalação |

---

## Passo 1 — Criar o banco no Supabase

1. Acesse **supabase.com** e crie uma conta gratuita
2. Clique em **New Project** → dê um nome → região **South America (São Paulo)**
3. No menu lateral, vá em **SQL Editor**
4. Cole TODO o conteúdo do arquivo `supabase_setup.sql` e clique em **Run**
5. Vá em **Settings → API** e copie:
   - `Project URL`
   - `anon public key`

---

## Passo 2 — Configurar o arquivo index.html

Abra o `index.html` em qualquer editor de texto e localize estas duas linhas (no início do `<script>`):

```js
const SUPABASE_URL = 'COLE_SUA_SUPABASE_URL_AQUI';
const SUPABASE_KEY = 'COLE_SUA_ANON_KEY_AQUI';
```

Substitua pelos valores copiados no Passo 1. Salve o arquivo.

---

## Passo 3 — Publicar no GitHub

1. Acesse **github.com** e crie uma conta
2. Clique em **New repository** → nome: `sistema-turnos` → Public → Create
3. Na página do repositório, clique em **uploading an existing file**
4. Arraste os 3 arquivos (`index.html`, `supabase_setup.sql`, `README.md`)
5. Clique em **Commit changes**

---

## Passo 4 — Hospedar na Vercel

1. Acesse **vercel.com** → **Start Deploying**
2. Faça login com sua conta GitHub
3. Clique em **Import** no repositório `sistema-turnos`
4. Em **Framework Preset** selecione **Other**
5. Clique em **Deploy** (sem variáveis de ambiente — as chaves já estão no HTML)
6. Em ~2 minutos seu site estará em `https://sistema-turnos-xxxx.vercel.app`

> **Dica:** Cada vez que você atualizar o `index.html` e subir para o GitHub, a Vercel atualiza o site automaticamente.

---

## Passo 5 — Criar o primeiro admin

1. No Supabase → **Authentication → Users → Invite user**
2. Digite seu e-mail e clique em **Send Invite**
3. Acesse o e-mail e defina sua senha
4. Volte ao Supabase → **SQL Editor** e rode:

```sql
UPDATE public.profiles
SET role = 'admin', nome = 'Seu Nome Aqui'
WHERE email = 'seu@email.com';
```

5. Acesse o site e faça login — você estará como **Administrador** ✓

---

## Passo 6 — Cadastrar entregadores

1. Faça login como admin no sistema
2. Vá em **Entregadores → Novo entregador**
3. Preencha nome, e-mail e senha temporária
4. O entregador já pode fazer login com esses dados

---

## Funcionalidades

### Painel do Entregador
- ✅ Login com e-mail e senha
- ✅ Visualizar turnos disponíveis da semana
- ✅ Selecionar dias e turnos desejados e solicitar
- ✅ Ver status das solicitações (pendente / aprovado / recusado)
- ✅ Ver histórico de performance e score atual

### Painel do Admin
- ✅ Dashboard com visão geral (pendentes, aprovados, total de entregadores)
- ✅ Aprovar ou recusar solicitações (ordenadas por score do entregador)
- ✅ Visualizar escala completa da semana
- ✅ Clicar em cada turno para ver quem está alocado
- ✅ Cadastrar novos entregadores
- ✅ Lançar performance mensal (entregas no prazo, avaliação, assiduidade)
- ✅ Score calculado automaticamente: `(entrega × 0,4) + (avaliação × 0,3) + (assiduidade × 0,3)`
- ✅ Criar e configurar turnos (horários e número de vagas)

---

## Sistema de Score (Prioridade)

| Indicador | Peso |
|---|---|
| Entregas no prazo (%) | 40% |
| Avaliação do cliente (0–10) | 30% |
| Assiduidade (%) | 30% |

As solicitações pendentes aparecem ordenadas do maior para o menor score, facilitando a decisão do admin.

---

## Custo

| Situação | Custo |
|---|---|
| Até ~50 entregadores | **R$ 0/mês** |
| Domínio próprio (opcional) | ~R$ 40/ano |
| Crescimento além do plano free do Supabase | ~R$ 130/mês |
