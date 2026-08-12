-- v27: public client dashboard zones
--      (Welcome & Pulse / Creative Engine & Proofing / Vault)
--
-- Restructures the ?client=slug dashboard into three named zones. A category
-- now declares which zone it belongs to; every existing category defaults to
-- 'general' so it keeps rendering in the stage "Files & links" panel exactly
-- as it does today. Nothing on a live client page moves until someone
-- deliberately re-tags a category from the admin view — this migration is a
-- no-op visually.
--
-- client_id becomes the always-present owner of a category. Until now a
-- category could only hang off a stage or a project, so a pure-retainer client
-- with zero rs_projects rows could not own any categories at all — the public
-- fetch's .or(stage_id.in..., project_id.in...) filter matched nothing AND the
-- whole assets UI was gated behind `projects.length`. stage_id / project_id
-- keep their existing meaning as optional narrowing scopes.
--
-- Checked before writing this: rs_stage_links.category_id already cascades on
-- delete (verified empirically against the live DB), so no FK fix is needed.

alter table rs_stage_categories
  add column if not exists zone text not null default 'general',
  add column if not exists client_id uuid references rs_clients(id) on delete cascade;

alter table rs_stage_categories drop constraint if exists rs_stage_categories_zone_check;
alter table rs_stage_categories add constraint rs_stage_categories_zone_check
  check (zone in ('general','proofing','brief','vault'));

-- Backfill client_id: project-scoped categories first, then stage-scoped ones.
-- Left nullable rather than NOT NULL so a category orphaned by a hard-deleted
-- stage/project can't abort the whole migration. The app keeps a legacy
-- fallback for null rows for one release; tighten in a later migration once
--   select count(*) from rs_stage_categories where client_id is null
-- returns 0.
update rs_stage_categories c
   set client_id = p.client_id
  from rs_projects p
 where c.project_id = p.id
   and c.client_id is null;

update rs_stage_categories c
   set client_id = p.client_id
  from rs_project_stages s
  join rs_projects p on p.id = s.project_id
 where c.stage_id = s.id
   and c.client_id is null;

create index if not exists rs_stage_categories_client_id_idx
  on rs_stage_categories (client_id);

-- Opt-OUT for inline proofing embeds, so an admin can force a Figma/Loom URL
-- to render as a plain link card instead. Only ever consulted for
-- zone = 'proofing'; ignored everywhere else.
alter table rs_stage_links
  add column if not exists embed boolean not null default true;

-- Zone 1 quick actions. dash_message_url is optional — when blank the button
-- falls back to mailto: dash_contact_email, which already exists.
alter table rs_clients
  add column if not exists dash_booking_url text,
  add column if not exists dash_request_url text,
  add column if not exists dash_message_url text;

-- No new tables here, but Supabase re-enables RLS on tables touched via the
-- SQL editor and this has bitten the project twice (v21, v23). Every table in
-- this app runs with RLS off so the anon key can read/write freely — re-assert
-- it for the three tables this migration alters. Idempotent, safe to re-run.
alter table rs_stage_categories disable row level security;
alter table rs_stage_links disable row level security;
alter table rs_clients disable row level security;
