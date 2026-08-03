-- v20: Editable pipeline cell statuses + resolved flag on feedback notes
-- Run this once in the Supabase SQL editor before the new Settings > "Pipeline
-- cell statuses" editor and the Feedback tab's "Resolved" checkbox will work.

-- Editable list of statuses a shot × pipeline-step cell can be set to (was a
-- hardcoded JS object before this migration). `behavior` is the semantic flag
-- the app keys off (progress %, flag chips, overdue check) instead of the
-- display name, so renaming/recolouring a status never breaks anything:
--   'none'    — no special meaning (e.g. "Internal review")
--   'wip'     — active work in progress (flags if unassigned)
--   'waiting' — waiting on someone else's feedback
--   'retake'  — needs retakes
--   'done'    — counts as fully done/approved for that step
--   'omitted' — not applicable — excluded from overdue checks
create table if not exists rs_anim_cell_statuses (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  color text not null default '#8a877e',
  short text not null default '',
  behavior text not null default 'none',
  position int not null default 0,
  created_at timestamptz not null default now()
);

-- Seed with the exact same 7 defaults the app used before this migration, so
-- existing cell.status values keep matching and nothing changes visually
-- until you actually edit something in Settings.
insert into rs_anim_cell_statuses (name, color, short, behavior, position)
select * from (values
  ('Not started','#e7e7ee','–','none',0),
  ('In progress','#4C6EF5','WIP','wip',1),
  ('Internal review','#F0B429','IR','none',2),
  ('Client review','#15AABF','CR','waiting',3),
  ('Retakes','#E8623D','RT','retake',4),
  ('Approved','#2FB380','✓','done',5),
  ('Omitted','#cfcfd8','om','omitted',6)
) as seed(name,color,short,behavior,position)
where not exists (select 1 from rs_anim_cell_statuses);

-- Lets a feedback note be checked off as addressed, independent of the cell's
-- current status. Powers the new Animation > Feedback tab and the "Resolved"
-- checkbox under each note in the cell modal.
alter table rs_anim_feedback
  add column if not exists resolved boolean not null default false;
