-- v26: let a stage's due date be hidden from the client-facing dashboard
-- Lets a PM keep an internal target date on a stage while showing nothing to
-- the client — useful when dates are provisional or the team wants more
-- flexibility than "whatever's in the system is what the client sees".
-- Toggled from the public dashboard's admin view (?client=slug&admin=1), via
-- a "Hide"/"Show" button next to each stage's date. Only affects that one
-- display — every internal view (project page, Milestones, Gantt, Discord
-- summary, etc.) keeps showing the real date regardless of this flag.

alter table rs_project_stages add column if not exists hide_due_date_from_client boolean not null default false;
