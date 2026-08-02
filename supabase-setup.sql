-- ============================================================
-- Wuffly — lista de espera con posición en cola + referidos
-- Copia y pega TODO este archivo en Supabase → SQL Editor → Run
-- ============================================================

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
returns table(referral_code text, queue_position bigint, referral_count bigint)
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

  v_code := substr(md5(random()::text || clock_timestamp()::text), 1, 8);

  insert into waitlist(email, referral_code, referred_by, interest)
  values (v_email, v_code, nullif(trim(p_ref), ''), coalesce(p_interest, 'lista general'))
  on conflict (email) do nothing;

  return query select * from get_status(v_email);
end;
$$;

-- Calcula la posición actual de un email: por orden de llegada,
-- pero cada referido confirmado sube 3 puestos (con suelo en el puesto 1).
create or replace function get_status(p_email text)
returns table(referral_code text, queue_position bigint, referral_count bigint)
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
    greatest(raw_position, 1) as queue_position,
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

-- ============================================================
-- AÑADIDO: validar con la lista de espera real la señal de un
-- Typeform antiguo (n=5, ~1 año) que apuntaba a preferencia
-- trimestral y mayor tolerancia de precio. Pega SOLO este bloque
-- de aquí abajo en el SQL Editor si ya ejecutaste el archivo antes.
-- ============================================================

alter table waitlist add column if not exists frequency_pref text;
alter table waitlist add column if not exists price_pref text;

create or replace function set_preferences(
  p_email text,
  p_frequency text default null,
  p_price text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update waitlist
  set frequency_pref = coalesce(p_frequency, frequency_pref),
      price_pref = coalesce(p_price, price_pref)
  where email = lower(trim(p_email));
end;
$$;

revoke all on function set_preferences(text, text, text) from public;
grant execute on function set_preferences(text, text, text) to anon, authenticated;

-- Consulta para revisar resultados más adelante:
--   select frequency_pref, count(*) from waitlist where frequency_pref is not null group by 1;
--   select price_pref, count(*) from waitlist where price_pref is not null group by 1;

-- ============================================================
-- AÑADIDO: capturar también la preferencia suscripción vs.
-- compra única (mismo patrón que frequency_pref/price_pref).
-- Pega SOLO este bloque si ya ejecutaste el archivo antes.
-- ============================================================

alter table waitlist add column if not exists purchase_pref text;

drop function if exists set_preferences(text, text, text);

create or replace function set_preferences(
  p_email text,
  p_frequency text default null,
  p_price text default null,
  p_purchase text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update waitlist
  set frequency_pref = coalesce(p_frequency, frequency_pref),
      price_pref = coalesce(p_price, price_pref),
      purchase_pref = coalesce(p_purchase, purchase_pref)
  where email = lower(trim(p_email));
end;
$$;

revoke all on function set_preferences(text, text, text, text) from public;
grant execute on function set_preferences(text, text, text, text) to anon, authenticated;

-- select purchase_pref, count(*) from waitlist where purchase_pref is not null group by 1;

-- ============================================================
-- AÑADIDO: tamaño del perro (para planificar cuánto stock S/M/L
-- comprar). Pega SOLO este bloque si ya ejecutaste el archivo antes.
-- ============================================================

alter table waitlist add column if not exists dog_size text;

drop function if exists set_preferences(text, text, text, text);

create or replace function set_preferences(
  p_email text,
  p_frequency text default null,
  p_price text default null,
  p_purchase text default null,
  p_size text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update waitlist
  set frequency_pref = coalesce(p_frequency, frequency_pref),
      price_pref = coalesce(p_price, price_pref),
      purchase_pref = coalesce(p_purchase, purchase_pref),
      dog_size = coalesce(p_size, dog_size)
  where email = lower(trim(p_email));
end;
$$;

revoke all on function set_preferences(text, text, text, text, text) from public;
grant execute on function set_preferences(text, text, text, text, text) to anon, authenticated;

-- select dog_size, count(*) from waitlist where dog_size is not null group by 1;

-- ============================================================
-- AÑADIDO: el voto de "a qué causa donar" ahora se guarda de
-- verdad (antes solo vivía en localStorage del navegador, nunca
-- llegaba a la base de datos). Es anónimo a propósito -- se puede
-- votar sin haberse apuntado aún a la lista.
-- Pega SOLO este bloque si ya ejecutaste el archivo antes.
-- ============================================================

create table if not exists impact_votes (
  id uuid primary key default gen_random_uuid(),
  cause text not null,
  other_text text,
  created_at timestamptz not null default now()
);

alter table impact_votes enable row level security;

create or replace function cast_impact_vote(p_cause text, p_other text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into impact_votes(cause, other_text) values (p_cause, nullif(trim(p_other), ''));
end;
$$;

revoke all on function cast_impact_vote(text, text) from public;
grant execute on function cast_impact_vote(text, text) to anon, authenticated;

-- select cause, count(*) from impact_votes group by 1 order by 2 desc;
-- select other_text from impact_votes where other_text is not null order by created_at desc;
