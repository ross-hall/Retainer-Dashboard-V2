-- v21: Internal Tasks page — rs_departments (editable label list) + rs_internal_tasks
-- Run this once in the Supabase SQL editor before the new "Internal Tasks" nav
-- page and the Settings > "Departments" editor will work.

-- Editable list of department/label options an internal task can be tagged
-- with (e.g. "Animation", "Graphics") — same editable-list pattern as
-- rs_task_statuses, so renaming/recolouring/reordering never breaks anything
-- since tasks reference the department by id, not name.
create table if not exists rs_departments (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  color text not null default '#8a877e',
  position int not null default 0,
  created_at timestamptz not null default now()
);

insert into rs_departments (name, color, position)
select * from (values
  ('Animation','#4C6EF5',0),
  ('Graphics','#8B5CF6',1)
) as seed(name,color,position)
where not exists (select 1 from rs_departments);

-- Internal (non-client) tasks — assigned to a team member, independent of
-- any client/project/retainer.
create table if not exists rs_internal_tasks (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  assignee_id uuid references rs_members(id) on delete set null,
  priority text not null default 'Medium',
  due_date date,
  department_id uuid references rs_departments(id) on delete set null,
  is_done boolean not null default false,
  position int not null default 0,
  created_at timestamptz not null default now()
);
