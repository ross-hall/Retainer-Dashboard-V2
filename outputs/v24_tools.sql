-- v24: Tools — a simple launcher list of external web tools/apps, shown as
-- its own "Tools" page in the sidebar (cards that link out via URL).
-- Run this once in the Supabase SQL editor before the Tools page will work.

create table if not exists rs_tools (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  url text not null,
  icon text,
  position int not null default 0,
  created_at timestamptz not null default now()
);

-- Supabase now enables RLS by default on tables created via the SQL editor;
-- every other table in this app has RLS off so the anon key can read/write
-- freely (see CLAUDE.md) — match that here from the start this time.
-- RLS: enable + the standard authenticated-only policy, matching v41.
-- This file originally ended with `disable row level security` — correct under
-- the old convention, but actively harmful now that v41 has run: it would have
-- re-opened this table to the anon key. Safe to run before or after v41.
alter table rs_tools enable row level security;
drop policy if exists rs_authenticated_all on rs_tools;
create policy rs_authenticated_all on rs_tools
  for all to authenticated using (true) with check (true);
revoke all on rs_tools from anon;
