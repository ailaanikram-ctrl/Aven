-- Aven cloud backup: run this ONCE in Supabase -> SQL Editor -> New query -> Run.
create table if not exists public.aven_backups (
  id          bigint generated always as identity primary key,
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  device      text not null,
  data        jsonb not null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists aven_backups_user_updated on public.aven_backups (user_id, updated_at desc);

alter table public.aven_backups enable row level security;
-- Each person can only see and change their OWN rows.
create policy "own select" on public.aven_backups for select using (auth.uid() = user_id);
create policy "own insert" on public.aven_backups for insert with check (auth.uid() = user_id);
create policy "own update" on public.aven_backups for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own delete" on public.aven_backups for delete using (auth.uid() = user_id);

create or replace function public.aven_touch() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;
drop trigger if exists aven_touch on public.aven_backups;
create trigger aven_touch before update on public.aven_backups
  for each row execute function public.aven_touch();
