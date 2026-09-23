-- Run this in Supabase Dashboard -> SQL Editor.
-- Safe to re-run for an existing table with the same column definitions.

create extension if not exists pgcrypto;

create table if not exists public.passwords (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  title text not null,
  username text not null,
  password text not null,
  website text not null default '',
  notes text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists passwords_user_id_idx
  on public.passwords (user_id);

alter table public.passwords enable row level security;

drop policy if exists "Users can view their own passwords" on public.passwords;
create policy "Users can view their own passwords"
  on public.passwords for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert their own passwords" on public.passwords;
create policy "Users can insert their own passwords"
  on public.passwords for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own passwords" on public.passwords;
create policy "Users can update their own passwords"
  on public.passwords for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own passwords" on public.passwords;
create policy "Users can delete their own passwords"
  on public.passwords for delete
  using (auth.uid() = user_id);
