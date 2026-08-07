-- v22: Internal tasks — multiple assignees per task
-- Run this once in the Supabase SQL editor before the Internal Tasks page's
-- assignee picker will let you select more than one person.

alter table rs_internal_tasks add column if not exists assignee_ids uuid[] not null default '{}'::uuid[];

-- Carry any existing single assignments over into the new array column.
update rs_internal_tasks
set assignee_ids = array[assignee_id]
where assignee_id is not null and assignee_ids = '{}';

-- rs_internal_tasks.assignee_id is left in place (unused going forward) —
-- non-destructive, and safe to drop later once you're confident the data
-- migrated cleanly.

-- Match v21's RLS fix for this table (harmless if it's already off).
alter table rs_internal_tasks disable row level security;
