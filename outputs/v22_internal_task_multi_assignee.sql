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
-- RLS: enable + the standard authenticated-only policy, matching v41.
-- This file originally ended with `disable row level security` — correct under
-- the old convention, but actively harmful now that v41 has run: it would have
-- re-opened this table to the anon key. Safe to run before or after v41.
alter table rs_internal_tasks enable row level security;
drop policy if exists rs_authenticated_all on rs_internal_tasks;
create policy rs_authenticated_all on rs_internal_tasks
  for all to authenticated using (true) with check (true);
revoke all on rs_internal_tasks from anon;
