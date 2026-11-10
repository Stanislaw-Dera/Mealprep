-- Mealprep: schemat bazy w Supabase.
-- Wklej całość w Supabase → SQL Editor → New query → Run.
-- Skrypt można uruchomić drugi raz (nie psuje istniejących danych).
--
-- Zasady (docs/ETAP2.md):
-- * Każdy wiersz należy do użytkownika (user_id), a RLS wpuszcza tylko do własnych.
--   Dzięki temu klucz publishable w aplikacji nie daje dostępu do niczyich danych.
-- * updated_at ustawia aplikacja (czas zmiany na urządzeniu). Przy konflikcie wygrywa
--   nowsza zmiana: starsza wysłana później jest po cichu pomijana (wyzwalacz poniżej).
-- * synced_at ustawia serwer (czas zapisu w Supabase). Po nim aplikacja pobiera
--   „wszystko, co się zmieniło od ostatniego razu".
-- * Usunięcie sesji to deleted = true („nagrobek"), odznaczenie to checked = false.

-- ------------------------------------------------------------ tabele

create table if not exists public.settings (
  user_id    uuid primary key default auth.uid() references auth.users on delete cascade,
  data       jsonb not null,
  updated_at timestamptz not null,
  synced_at  timestamptz not null default now()
);

create table if not exists public.sessions (
  id         uuid primary key,
  user_id    uuid not null default auth.uid() references auth.users on delete cascade,
  first_day  date not null,
  data       jsonb not null,
  deleted    boolean not null default false,
  updated_at timestamptz not null,
  synced_at  timestamptz not null default now()
);

create table if not exists public.shopping_checks (
  user_id    uuid not null default auth.uid() references auth.users on delete cascade,
  session_id uuid not null,
  product_id text not null,
  checked    boolean not null,
  updated_at timestamptz not null,
  synced_at  timestamptz not null default now(),
  primary key (session_id, product_id)
);

create index if not exists sessions_user_synced on public.sessions (user_id, synced_at);
create index if not exists checks_user_synced on public.shopping_checks (user_id, synced_at);

-- ------------------------------------- nowsza zmiana wygrywa (last write wins)

create or replace function public.mealprep_lww()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and new.updated_at <= old.updated_at then
    return null; -- w bazie jest nowsza (albo ta sama) wersja: nic nie zmieniamy
  end if;
  new.synced_at := now();
  return new;
end;
$$;

drop trigger if exists lww on public.settings;
create trigger lww before insert or update on public.settings
  for each row execute function public.mealprep_lww();

drop trigger if exists lww on public.sessions;
create trigger lww before insert or update on public.sessions
  for each row execute function public.mealprep_lww();

drop trigger if exists lww on public.shopping_checks;
create trigger lww before insert or update on public.shopping_checks
  for each row execute function public.mealprep_lww();

-- --------------------------------------------- RLS: tylko własne wiersze

alter table public.settings enable row level security;
alter table public.sessions enable row level security;
alter table public.shopping_checks enable row level security;

drop policy if exists own on public.settings;
create policy own on public.settings for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists own on public.sessions;
create policy own on public.sessions for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists own on public.shopping_checks;
create policy own on public.shopping_checks for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- Dostęp przez API tylko dla zalogowanych (anon nie ma żadnych praw).
grant select, insert, update on public.settings, public.sessions, public.shopping_checks
  to authenticated;
revoke all on public.settings, public.sessions, public.shopping_checks from anon;

-- ------------------------------------- Realtime: zmiany na żywo w aplikacji

do $$
declare
  t text;
begin
  foreach t in array array['settings', 'sessions', 'shopping_checks'] loop
    if not exists (select 1 from pg_publication_tables
                   where pubname = 'supabase_realtime' and schemaname = 'public'
                     and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end;
$$;
