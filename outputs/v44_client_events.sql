-- v44: rs_client_events — dated things on a client's calendar that are NOT tasks.
--
-- WHY A SEPARATE TABLE RATHER THAN A TASK FLAG
-- A task is work someone does: it has a status, an assignee, an estimate, and
-- it counts (or doesn't) toward a retainer. A client event is a fact about the
-- calendar — "their board meeting", "results announcement", "they're at ARVO
-- all week". Modelling it as a task with a special status would put non-work on
-- every to-do list, in the retainer usage maths, and in the client portal's
-- task feed. None of those are wanted, and each would need its own exclusion.
--
-- end_date is nullable: null means a single-day event. A range renders on every
-- day it spans.
--
-- INTERNAL-ONLY for now. client_portal() (v40) does not return this table, so
-- nothing here reaches a client's browser. If you later want these on the
-- client portal, that's a deliberate addition to v40 — not an accident of
-- adding the table.
--
-- Written post-v41, so it ENABLES RLS and adds the standard policy rather than
-- disabling it — see the flipped-convention warning at the top of CLAUDE.md.

create table if not exists rs_client_events (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references rs_clients(id) on delete cascade,
  title text not null,
  event_date date not null,
  end_date date,
  kind text not null default 'event',
  note text,
  created_at timestamptz not null default now()
);

-- Every read is "this client's events, in date order".
create index if not exists rs_client_events_client_date
  on rs_client_events (client_id, event_date);

alter table rs_client_events enable row level security;
drop policy if exists rs_authenticated_all on rs_client_events;
create policy rs_authenticated_all on rs_client_events
  for all to authenticated using (true) with check (true);
revoke all on rs_client_events from anon;
