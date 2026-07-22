-- Babacan PMS Mobile V1 - Supabase şeması
create extension if not exists pgcrypto;

create table if not exists public.hotels (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  license_key text unique,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.mobile_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  hotel_id uuid not null references public.hotels(id) on delete cascade,
  role text not null default 'manager' check (role in ('owner','manager','viewer')),
  created_at timestamptz not null default now()
);

create table if not exists public.mobile_rooms (
  hotel_id uuid not null references public.hotels(id) on delete cascade,
  room_no text not null,
  status text not null default 'vacant' check (status in ('vacant','occupied','cleaning','maintenance')),
  guest_name text,
  check_in date,
  check_out date,
  balance numeric(12,2) not null default 0,
  updated_at timestamptz not null default now(),
  primary key (hotel_id, room_no)
);

create table if not exists public.mobile_guests (
  id text not null,
  hotel_id uuid not null references public.hotels(id) on delete cascade,
  guest_name text not null,
  phone text,
  room_no text,
  check_in date,
  check_out date,
  total_amount numeric(12,2) not null default 0,
  paid_amount numeric(12,2) not null default 0,
  balance numeric(12,2) not null default 0,
  is_active boolean not null default true,
  updated_at timestamptz not null default now(),
  primary key (hotel_id,id)
);

create table if not exists public.mobile_cash_movements (
  id text not null,
  hotel_id uuid not null references public.hotels(id) on delete cascade,
  type text not null check (type in ('income','expense')),
  amount numeric(12,2) not null,
  description text,
  payment_method text,
  staff_name text,
  created_at timestamptz not null,
  primary key (hotel_id,id)
);

create table if not exists public.mobile_sync_status (
  hotel_id uuid primary key references public.hotels(id) on delete cascade,
  device_name text,
  app_version text,
  last_sync_at timestamptz,
  last_error text,
  is_online boolean not null default false
);

alter table public.hotels enable row level security;
alter table public.mobile_profiles enable row level security;
alter table public.mobile_rooms enable row level security;
alter table public.mobile_guests enable row level security;
alter table public.mobile_cash_movements enable row level security;
alter table public.mobile_sync_status enable row level security;

create or replace function public.my_hotel_id() returns uuid language sql stable security definer set search_path=public as $$
  select hotel_id from public.mobile_profiles where user_id=auth.uid()
$$;

create policy "profile self read" on public.mobile_profiles for select to authenticated using (user_id=auth.uid());
create policy "hotel member read" on public.hotels for select to authenticated using (id=public.my_hotel_id());
create policy "rooms member read" on public.mobile_rooms for select to authenticated using (hotel_id=public.my_hotel_id());
create policy "guests member read" on public.mobile_guests for select to authenticated using (hotel_id=public.my_hotel_id());
create policy "cash member read" on public.mobile_cash_movements for select to authenticated using (hotel_id=public.my_hotel_id());
create policy "sync member read" on public.mobile_sync_status for select to authenticated using (hotel_id=public.my_hotel_id());
