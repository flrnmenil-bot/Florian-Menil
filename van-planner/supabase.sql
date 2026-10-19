-- Atelier Van : synchronisation des plans entre appareils.
-- À coller dans Supabase → SQL Editor → Run (une seule fois).
-- La table n'a aucune règle d'accès directe : on ne peut lire ou écrire un plan
-- qu'en connaissant son code, via les deux fonctions ci-dessous.

create table if not exists public.van_plans (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);
alter table public.van_plans enable row level security;

create or replace function public.van_get(p_id text)
returns table (data jsonb, updated_at timestamptz)
language sql security definer set search_path = public as $$
  select data, updated_at from public.van_plans where id = p_id;
$$;

create or replace function public.van_save(p_id text, p_data jsonb)
returns timestamptz
language plpgsql security definer set search_path = public as $$
declare t timestamptz := now();
begin
  if length(p_id) < 20 then raise exception 'code de synchronisation trop court'; end if;
  insert into public.van_plans (id, data, updated_at) values (p_id, p_data, t)
  on conflict (id) do update set data = excluded.data, updated_at = t;
  return t;
end $$;

grant execute on function public.van_get(text) to anon, authenticated;
grant execute on function public.van_save(text, jsonb) to anon, authenticated;
