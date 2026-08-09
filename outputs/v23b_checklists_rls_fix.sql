-- v23b: RLS fix for the Checklists feature
-- Run this if you already ran v23_qa_checklist.sql but still get
-- "Could not create checklist" / a 42501 row-level security error when
-- trying to add a checklist. rs_checklists / rs_checklist_items exist but
-- RLS wasn't actually disabled on them (Supabase enables it by default on
-- tables created via the SQL editor — same issue hit in migration v21).
-- Safe to run even if RLS is already off.

alter table rs_checklists disable row level security;
alter table rs_checklist_items disable row level security;
