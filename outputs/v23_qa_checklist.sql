-- v23: Checklists — named, multi-per-project checklists with their own page
-- Run this once in the Supabase SQL editor before the new "Checklists"
-- section on each project's page (and the "+ New checklist" button) will work.
--
-- Supersedes an earlier draft of this migration that added a qa_checklist
-- column to rs_project_types and a flat rs_project_qa_items table — that
-- draft was never run against this database, so it's replaced outright here
-- rather than layered on top of. Checklists are no longer tied to a project
-- type template; each project can have any number of independently named
-- checklists, created on demand (optionally seeded from a starter template,
-- e.g. "Website Checklist", picked at creation time).

create table if not exists rs_checklists (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references rs_projects(id) on delete cascade,
  name text not null,
  position int not null default 0,
  created_at timestamptz not null default now()
);

-- category is an optional free-text grouping label (e.g. "Visual & Brand")
-- used to render items under a section heading; null items render flat.
-- detail is optional muted helper text shown under the item's label.
create table if not exists rs_checklist_items (
  id uuid primary key default gen_random_uuid(),
  checklist_id uuid not null references rs_checklists(id) on delete cascade,
  category text,
  label text not null,
  detail text,
  is_done boolean not null default false,
  position int not null default 0,
  created_at timestamptz not null default now()
);

-- Supabase now enables RLS by default on tables created via the SQL editor;
-- every other table in this app has RLS off so the anon key can read/write
-- freely (see CLAUDE.md) — match that here, otherwise the app's inserts and
-- selects get silently blocked (learned this the hard way in migration v21).
alter table rs_checklists disable row level security;
alter table rs_checklist_items disable row level security;
