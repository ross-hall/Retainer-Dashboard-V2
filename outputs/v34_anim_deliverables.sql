-- v34: adds rs_anim_deliverable_columns + rs_anim_deliverables
--
-- Rewritten before its first run (nothing depends on the original fixed-
-- column version yet) to make the Deliverables table's columns themselves
-- user-editable — rename any column or add a new one from Settings, no
-- migration required per change. Same precedent as v23's mid-session
-- rewrite documented elsewhere in this project.
--
-- rs_anim_deliverable_columns is a GLOBAL, editable list — same pattern as
-- rs_task_statuses / rs_departments / rs_anim_cell_statuses: one shared set
-- of columns across every project's Deliverables tab, not per-project, so
-- adding a column applies everywhere at once. Managed from Settings >
-- "Deliverable columns".
create table if not exists rs_anim_deliverable_columns (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  label text not null,
  type text not null default 'text' check (type in ('text','textarea','boolean','status')),
  position integer not null default 0
);

-- Deliverable rows. Field values live in `data` (jsonb, {column_key: value})
-- rather than named SQL columns, so a column can be renamed/added/removed
-- from Settings with zero schema change. project_id/position stay real
-- columns since every deliverable needs them regardless of which fields
-- exist.
create table if not exists rs_anim_deliverables (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references rs_projects(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  position integer not null default 0,
  created_at timestamptz not null default now()
);

alter table rs_anim_deliverable_columns disable row level security;
alter table rs_anim_deliverables disable row level security;

-- Seeds the same 10 columns the feature originally shipped with, so a fresh
-- install matches the client-supplied spec table out of the box.
insert into rs_anim_deliverable_columns (key,label,type,position) values
  ('deliverable','Deliverable','text',0),
  ('code','Code','text',1),
  ('page','Page','text',2),
  ('description','Description','text',3),
  ('format','Format','text',4),
  ('specs','Specs / Dimensions','text',5),
  ('duration','Duration','text',6),
  ('alpha_delivered','Alpha Delivered','boolean',7),
  ('notes','Notes','textarea',8),
  ('status','Status','status',9)
on conflict (key) do nothing;
