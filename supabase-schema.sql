-- Bridge-IMP: run this once in the Supabase SQL editor (same project as Bridge-Bidding).
-- Tables are prefixed "imp_" so they don't collide with the existing "scores" table.

create table public.imp_tournaments (
  id uuid primary key default gen_random_uuid(),
  title text,
  date text,
  session_info text,
  boards jsonb not null,
  created_at timestamptz default now()
);
alter table public.imp_tournaments enable row level security;
create policy "public read" on public.imp_tournaments for select using (true);
create policy "public insert" on public.imp_tournaments for insert with check (true);

create table public.imp_entries (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid references public.imp_tournaments(id) on delete cascade,
  board_id int not null,
  pair_name text,
  contract_label text,
  ns_score int,
  imp int,
  created_at timestamptz default now()
);
alter table public.imp_entries enable row level security;
create policy "public read" on public.imp_entries for select using (true);
create policy "public insert" on public.imp_entries for insert with check (true);

alter publication supabase_realtime add table public.imp_entries;

-- RLS policies alone are not enough: tables created via the SQL editor (unlike
-- the Table Editor UI) don't automatically grant base privileges to the anon
-- role, so requests fail with "permission denied" before RLS is even checked.
grant select, insert on public.imp_tournaments to anon, authenticated;
grant select, insert on public.imp_entries to anon, authenticated;

-- ---------------------------------------------------------------------------
-- Migration 2: "activities" (a fixed pair roster playing through a tournament)
-- plus delete support everywhere. Run this once, in addition to everything above.
-- ---------------------------------------------------------------------------

create table public.imp_activities (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid references public.imp_tournaments(id) on delete cascade,
  title text,
  pairs jsonb not null,   -- [{"id":1,"name":"כהן-לוי","table":1}, ...]
  created_at timestamptz default now()
);
alter table public.imp_activities enable row level security;
create policy "public read" on public.imp_activities for select using (true);
create policy "public insert" on public.imp_activities for insert with check (true);
create policy "public delete" on public.imp_activities for delete using (true);
grant select, insert, delete on public.imp_activities to anon, authenticated;

alter table public.imp_entries add column activity_id uuid references public.imp_activities(id) on delete cascade;
alter table public.imp_entries add column table_label text;

create policy "public delete" on public.imp_entries for delete using (true);
create policy "public delete" on public.imp_tournaments for delete using (true);
grant delete on public.imp_entries to anon, authenticated;
grant delete on public.imp_tournaments to anon, authenticated;
