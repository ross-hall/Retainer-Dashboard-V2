-- v19: Add "Animator" as a third assignment category alongside Designer and Reviewer
-- Run this once in the Supabase SQL editor before the Animator UI will work.

-- Per-member eligibility flag, mirrors can_design / can_review
alter table rs_members
  add column if not exists can_animate boolean default true;

-- Per-task assignment array, mirrors assigned_designer_ids / assigned_reviewer_ids
alter table rs_proj_tasks
  add column if not exists assigned_animator_ids uuid[] default '{}';
