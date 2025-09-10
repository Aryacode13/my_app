-- SQL untuk membuat tabel registrations di Supabase
-- Jalankan di Supabase SQL Editor

create table if not exists registrations (
  id bigserial primary key,
  order_id text unique not null,
  name text not null,
  email text not null,
  phone text,
  amount bigint not null,
  status text not null default 'pending',
  payment_token text,
  payment_redirect_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Index untuk performa
create index if not exists registrations_order_idx on registrations(order_id);
create index if not exists registrations_email_idx on registrations(email);
create index if not exists registrations_status_idx on registrations(status);

-- Function untuk auto-update updated_at
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Trigger untuk auto-update updated_at
drop trigger if exists set_registrations_updated_at on registrations;
create trigger set_registrations_updated_at
before update on registrations
for each row execute procedure set_updated_at();

-- Row Level Security (RLS) - optional
alter table registrations enable row level security;

-- Policy untuk allow all operations (sesuaikan dengan kebutuhan)
create policy "Allow all operations" on registrations
for all using (true);
