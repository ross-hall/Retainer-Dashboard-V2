-- v40: client_portal(slug) — the single door the public client portal reads through.
--
-- STEP 2 OF 3 in turning on RLS properly. Run AFTER v39, BEFORE v41.
-- Non-breaking on its own: the app tries this function and silently falls back
-- to its old direct-table reads if it doesn't exist yet, so running this simply
-- flips the portal onto the new path.
--
-- WHY THIS EXISTS
-- The client portal (?client=slug) has to serve visitors who are not logged in,
-- so `anon` needs *some* access. But RLS cannot express "this visitor may read
-- exactly one client" — the slug is just a query parameter the visitor controls,
-- and there's nothing in an anon request to bind it to. Any RLS policy loose
-- enough to serve the portal is loose enough to serve every client's data.
--
-- A security definer function inverts that: anon gets zero table privileges and
-- can only call this one function, which takes a slug and can only ever return
-- that one client's payload. The function body is the access rule.
--
-- SECURITY NOTES
--   * `security definer` runs as the owner, bypassing RLS — that's the point,
--     but it means the body IS the security boundary. Keep it narrow.
--   * `set search_path = public` is required, not decorative: without it a
--     caller-controlled search_path could resolve these table names elsewhere.
--   * The client row is WHITELISTED, not passed through. `select *` on
--     rs_clients was previously shipping retainer_hours, rollover_hours,
--     rollover_overage, retainer_paused, miro_link_internal and miro_link to
--     every client's browser — a client could read their own retainer usage and
--     our internal Miro board out of devtools. CLAUDE.md says retainer hours are
--     internal-only; this is where that becomes true. The whitelist is applied
--     to to_jsonb() rather than as a column list so it tolerates schema drift in
--     both directions: a column that doesn't exist yet (v31's dash_contact_*)
--     is simply absent rather than failing to create, and any column added later
--     is excluded until deliberately added here.

create or replace function public.client_portal(p_slug text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_client rs_clients%rowtype;
  -- Effort/billing fields stripped from every task before it reaches a client's
  -- browser. Same reasoning as the client whitelist below: the portal renders a
  -- task's title and date, never its hours, so shipping them is pure exposure.
  v_task_hidden text[] := array['estimated_hours','recorded_hours','counts_toward_retainer'];
  v_project_ids uuid[];
  v_stage_ids uuid[];
  v_cat_ids uuid[];
  -- Everything the portal actually reads (verified against renderPublicDashboard).
  -- Deliberately omits: retainer_hours, rollover_hours, rollover_overage,
  -- retainer_paused, miro_link_internal, miro_link, color, active, created_at,
  -- dash_logo_text.
  v_allowed text[] := array[
    'id','name','slug','is_retainer','renewal_day',
    'dash_accent_color','dash_greeting','dash_logo_url','dash_website_url',
    'dash_contact_email','dash_contact_name','dash_contact_role',
    'dash_booking_url','dash_request_url','dash_message_url',
    'miro_link_external'
  ];
begin
  select * into v_client from rs_clients where slug = p_slug and active limit 1;
  if not found then
    return null;  -- app renders its "Dashboard not found" screen
  end if;

  select coalesce(array_agg(id), '{}') into v_project_ids
    from rs_projects where client_id = v_client.id and active;

  select coalesce(array_agg(id), '{}') into v_stage_ids
    from rs_project_stages where project_id = any(v_project_ids);

  -- Mirrors the app's own category scoping: owned by the client (v27), plus any
  -- row the v27 backfill couldn't reach, still attached by stage/project.
  select coalesce(array_agg(id), '{}') into v_cat_ids
    from rs_stage_categories
   where client_id = v_client.id
      or (client_id is null
          and (stage_id = any(v_stage_ids) or project_id = any(v_project_ids)));

  return jsonb_build_object(
    'client', (select jsonb_object_agg(key, value)
                 from jsonb_each(to_jsonb(v_client))
                where key = any(v_allowed)),
    'projects', coalesce((select jsonb_agg(to_jsonb(p) order by p.name)
                            from rs_projects p where p.id = any(v_project_ids)), '[]'::jsonb),
    'stages', coalesce((select jsonb_agg(to_jsonb(s) order by s.position)
                          from rs_project_stages s where s.id = any(v_stage_ids)), '[]'::jsonb),
    'categories', coalesce((select jsonb_agg(to_jsonb(sc) order by sc.position)
                              from rs_stage_categories sc where sc.id = any(v_cat_ids)), '[]'::jsonb),
    'links', coalesce((select jsonb_agg(to_jsonb(l) order by l.position)
                         from rs_stage_links l where l.category_id = any(v_cat_ids)), '[]'::jsonb),
    -- Tasks inside this client's stages — drives stageStatus() on the portal.
    'stage_tasks', coalesce((select jsonb_agg(to_jsonb(t) - v_task_hidden)
                               from rs_proj_tasks t where t.stage_id = any(v_stage_ids)), '[]'::jsonb),
    -- Retainer to-do items (client-scoped, no project, dated). Gated on
    -- is_retainer to match the app's existing fetch exactly.
    'retainer_tasks', case when v_client.is_retainer then
        coalesce((select jsonb_agg(to_jsonb(t) - v_task_hidden) from rs_proj_tasks t
                   where t.client_id = v_client.id and t.project_id is null
                     and t.due_date is not null), '[]'::jsonb)
      else '[]'::jsonb end,
    -- Global status vocabulary; isCompleteStatus() needs it to read a stage.
    'task_statuses', coalesce((select jsonb_agg(to_jsonb(ts) order by ts.position)
                                 from rs_task_statuses ts), '[]'::jsonb)
  );
end;
$$;

-- anon may call this and nothing else. `from public` first so the default
-- EXECUTE-to-everyone grant doesn't quietly stay behind.
revoke all on function public.client_portal(text) from public;
grant execute on function public.client_portal(text) to anon, authenticated;
