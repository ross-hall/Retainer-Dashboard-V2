-- v38: adds rs_client_contacts
--
-- Multiple named contacts per client — distinct from rs_clients.dash_contact_name/
-- dash_contact_role (v31), which is a single point-of-contact shown on the
-- PUBLIC client dashboard's nav. This table is internal-only: a "Contact info"
-- button on the Graphics client page (renderProjClientProjects) opens a modal
-- listing every contact for that client, and the "New client" intake form
-- (openNewClientModal) can seed one or more contacts at creation time.

create table if not exists rs_client_contacts (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references rs_clients(id) on delete cascade,
  name text not null,
  role text,
  email text,
  phone text,
  position integer not null default 0,
  created_at timestamptz not null default now()
);

-- RLS: enable + the standard authenticated-only policy, matching v41.
-- This file originally ended with `disable row level security` — correct under
-- the old convention, but actively harmful now that v41 has run: it would have
-- re-opened this table to the anon key. Safe to run before or after v41.
alter table rs_client_contacts enable row level security;
drop policy if exists rs_authenticated_all on rs_client_contacts;
create policy rs_authenticated_all on rs_client_contacts
  for all to authenticated using (true) with check (true);
revoke all on rs_client_contacts from anon;
