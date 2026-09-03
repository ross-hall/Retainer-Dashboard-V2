-- v35: adds rs_members.is_admin + rs_time_off_requests
--
-- Time Off page (Holiday / WFH requests, approval workflow, shared team
-- calendar). Admin approval reuses the same no-login "current user" pattern
-- the rest of the app already uses (CURRENT_USER_NAME/currentUser()) —
-- is_admin is just another per-member boolean, same shape as can_design/
-- can_review/can_animate, edited from Settings > Team members.

alter table rs_members add column if not exists is_admin boolean not null default false;

create table if not exists rs_time_off_requests (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references rs_members(id) on delete cascade,
  type text not null check (type in ('holiday','wfh')),
  start_date date not null,
  end_date date not null,
  note text,
  status text not null default 'pending' check (status in ('pending','approved','declined')),
  reviewed_by uuid references rs_members(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table rs_members disable row level security;
alter table rs_time_off_requests disable row level security;

-- One-time bootstrap so the feature is usable immediately after this
-- migration runs, per explicit request ("I, Ross, am admin") — further
-- admins are toggled from Settings > Team members going forward.
update rs_members set is_admin = true where name = 'Ross Hall';
