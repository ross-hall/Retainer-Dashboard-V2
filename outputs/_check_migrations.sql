-- Paste into the Supabase SQL editor. One row per thing, "yes"/"NO" per column.
-- Purely a read — changes nothing.
select
  to_regclass('public.rs_members')            is not null                          as members_table,
  (select count(*) from information_schema.columns
    where table_name='rs_members' and column_name='email')            = 1          as v39_members_email,
  (select count(*) from rs_members where email is not null)                        as members_with_a_login_email,
  (select count(*) from information_schema.columns
    where table_name='rs_proj_tasks' and column_name='estimated_hours') = 1        as v42_estimated_hours,
  (select count(*) from information_schema.columns
    where table_name='rs_clients' and column_name='show_estimates')     = 1        as v42_show_estimates,
  (select count(*) from information_schema.columns
    where table_name='rs_proj_tasks' and column_name='assigned_admin_ids') = 1     as v43_assigned_admin_ids,
  (select count(*) from rs_members where is_admin)                                 as admins_ticked;

-- Who is linked to which login (v39). Anyone with a null email is unidentified
-- in the app as of v0.78.0 — no greeting, no holiday balance, no admin rights.
select name, email, is_admin, can_design, can_review, can_animate
  from rs_members where active order by name;
