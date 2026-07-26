-- ============================================================
-- Wuffly — lista de espera con posición en cola + referidos
-- Copia y pega TODO este archivo en Supabase → SQL Editor → Run
-- ============================================================

create extension if not exists pgcrypto;

create table if not exists waitlist (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  referral_code text unique not null,
  referred_by text references waitlist(referral_code) on delete set null,
  interest text default 'lista general',
  created_at timestamptz not null default now()
);

-- RLS activado y SIN políticas: esto bloquea cualquier acceso directo
-- a la tabla desde el navegador (con el anon key), incluso lectura.
-- Solo se puede entrar a través de las funciones de abajo.
alter table waitlist enable row level security;

-- Une a alguien a la lista (o, si el email ya existía, simplemente
-- devuelve su estado actual sin duplicarlo) y calcula su posición.
create or replace function join_waitlist(
  p_email text,
  p_ref text default null,
  p_interest text default 'lista general'
)
returns table(referral_code text, position bigint, referral_count bigint)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text := lower(trim(p_email));
  v_code text;
begin
  if v_email is null or v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'Email no válido';
  end if;

  v_code := substr(encode(gen_random_bytes(6), 'hex'), 1, 8);

  insert into waitlist(email, referral_code, referred_by, interest)
  values (v_email, v_code, nullif(trim(p_ref), ''), coalesce(p_interest, 'lista general'))
  on conflict (email) do nothing;

  return query select * from get_status(v_email);
end;
$$;

-- Calcula la posición actual de un email: por orden de llegada,
-- pero cada referido confirmado sube 3 puestos (con suelo en el puesto 1).
create or replace function get_status(p_email text)
returns table(referral_code text, position bigint, referral_count bigint)
language sql
security definer
set search_path = public
as $$
  with ranked as (
    select
      w.email,
      w.referral_code,
      row_number() over (order by w.created_at asc)
        - 3 * (select count(*) from waitlist r where r.referred_by = w.referral_code) as raw_position,
      (select count(*) from waitlist r where r.referred_by = w.referral_code) as referral_count
    from waitlist w
  )
  select
    referral_code,
    greatest(raw_position, 1) as position,
    referral_count
  from ranked
  where email = lower(trim(p_email));
$$;

-- Solo estas dos funciones son accesibles públicamente (desde el
-- anon key del navegador). La tabla en sí sigue bloqueada.
revoke all on function join_waitlist(text, text, text) from public;
revoke all on function get_status(text) from public;
grant execute on function join_waitlist(text, text, text) to anon, authenticated;
grant execute on function get_status(text) to anon, authenticated;

-- ============================================================
-- Consultas útiles para ti (ejecútalas cuando quieras revisar datos,
-- desde el SQL Editor — con tu usuario, no con el anon key, así que
-- esto SÍ puede saltarse el bloqueo de RLS si entras como admin):
--
--   select email, interest, created_at from waitlist order by created_at desc;
--   select count(*) from waitlist;
--   select referred_by, count(*) from waitlist where referred_by is not null group by referred_by order by 2 desc;
-- ============================================================
