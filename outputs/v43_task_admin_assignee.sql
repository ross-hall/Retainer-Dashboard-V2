-- v43: rs_proj_tasks.assigned_admin_ids — Admin as a fourth assignable role on
-- a task, alongside designer / reviewer / animator.
--
-- WHY A NEW COLUMN RATHER THAN REUSING ONE
-- rs_members.is_admin (v35) says who may APPROVE time off. It is a permission,
-- not a job on a task. Putting an admin's id into assigned_designer_ids to get
-- them onto a task would make "who designed this" wrong for reporting later.
-- The four roles stay four arrays; only the UI merged them into one column.
--
-- Which people the Admin group offers is driven by rs_members.is_admin, ticked
-- in Settings > Team members — no second flag to keep in sync.
--
-- Degrades gracefully until run: the task modal's Save drops this field and
-- toasts "run migration v43", and the People popover's Admin group reverts its
-- tick and says the same, so nothing else on the task fails to save.
--
-- Written post-v41, so it ENABLES RLS and adds the standard policy rather than
-- disabling it — see the flipped-convention warning at the top of CLAUDE.md.

alter table rs_proj_tasks add column if not exists assigned_admin_ids uuid[] default '{}';

alter table rs_proj_tasks enable row level security;
drop policy if exists rs_authenticated_all on rs_proj_tasks;
create policy rs_authenticated_all on rs_proj_tasks
  for all to authenticated using (true) with check (true);
revoke all on rs_proj_tasks from anon;

-- NOTE: client_portal() (v40) strips effort/billing fields from tasks but does
-- NOT strip assignee arrays — they were already being sent, and the portal has
-- never rendered them. Nothing new is exposed by this column, but if you ever
-- want assignees hidden from clients, add the three assigned_*_ids to v40's
-- v_task_hidden array and re-run it.
