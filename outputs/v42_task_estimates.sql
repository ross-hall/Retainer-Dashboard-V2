-- v42: time estimates on tasks + a per-client toggle for showing them.
--
-- rs_proj_tasks.estimated_hours — planned effort for a task, distinct from the
-- hours actually logged against it (rs_proj_task_entries, and recorded_hours for
-- non-retainer clients). Nullable: a task with no estimate simply contributes
-- nothing, rather than being treated as a zero-hour task.
--
-- rs_clients.show_estimates — per-client, defaults true, controls whether the
-- estimate band is drawn on that client's retainer usage bars. Lives on the
-- client (not app-wide) because it's toggled from the per-client "Retainer
-- settings" modal alongside rollover_hours/rollover_overage/retainer_paused.
--
-- Written post-v41, so it ENABLES RLS and adds the standard policy rather than
-- disabling it — see the flipped-convention warning at the top of CLAUDE.md.

alter table rs_proj_tasks add column if not exists estimated_hours numeric;
alter table rs_clients   add column if not exists show_estimates boolean not null default true;

alter table rs_proj_tasks enable row level security;
drop policy if exists rs_authenticated_all on rs_proj_tasks;
create policy rs_authenticated_all on rs_proj_tasks
  for all to authenticated using (true) with check (true);
revoke all on rs_proj_tasks from anon;

alter table rs_clients enable row level security;
drop policy if exists rs_authenticated_all on rs_clients;
create policy rs_authenticated_all on rs_clients
  for all to authenticated using (true) with check (true);
revoke all on rs_clients from anon;

-- ⚠️ RE-RUN v40 AFTER THIS ONE.
-- The client portal reads tasks through client_portal() (v40), which returned
-- whole task rows — so estimated_hours would have been shipped to every client's
-- browser the moment this migration ran. v40 has been updated to strip
-- estimated_hours / recorded_hours / counts_toward_retainer from the task
-- payload; it's `create or replace`, so re-running it is safe and idempotent.
-- Estimates are internal planning data, same reasoning as retainer_hours.
