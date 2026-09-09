-- v41: enable RLS on every rs_* table and cut anon off from direct table access.
--
-- ⚠️  STEP 3 OF 3, AND THE ONE THAT ACTUALLY CHANGES BEHAVIOUR. RUN LAST.
--
-- BEFORE RUNNING THIS, ALL OF THE FOLLOWING MUST BE TRUE:
--   1. v39 has run, and at least one rs_members row has an `email` set.
--   2. A matching user exists in Supabase > Authentication > Users (with a
--      password). You cannot sign in otherwise — and after this migration the
--      internal app is unusable signed out. Verify you can sign in FIRST.
--   3. v40 has run and the deployed app is on a build that calls client_portal()
--      (v0.72.x or later). Otherwise every client portal breaks the moment this
--      runs, because the portal still reads tables directly as anon.
--
-- Verify 3 by loading a client portal and confirming the browser console does
-- NOT log "client_portal() not available". If it does, the app is still on the
-- legacy path and this migration will take those portals offline.
--
-- WHAT THIS DOES
-- Every signed-in team member gets full access to everything (explicit product
-- decision — nine trusted people, no per-role split). `anon` keeps nothing but
-- EXECUTE on client_portal(), which is what keeps the public portals working.
--
-- ROLLBACK, if something is wrong: see the commented block at the bottom.

do $$
declare t record;
begin
  -- Loop rather than a hand-written list: this picks up every rs_* table
  -- including ones from migrations not yet run when this was written, and it's
  -- safely re-runnable if a later migration adds a table.
  for t in
    select tablename from pg_tables
     where schemaname = 'public' and tablename like 'rs\_%'
     order by tablename
  loop
    execute format('alter table public.%I enable row level security', t.tablename);

    -- One policy per table: any authenticated user, all four verbs.
    -- `with check (true)` as well as `using (true)` — without the former,
    -- SELECT/DELETE would work but INSERT/UPDATE would silently fail.
    execute format('drop policy if exists rs_authenticated_all on public.%I', t.tablename);
    execute format(
      'create policy rs_authenticated_all on public.%I for all to authenticated using (true) with check (true)',
      t.tablename);

    -- Belt and braces. RLS with no anon policy already yields zero rows, but
    -- revoking the grant means a future accidental `to public` policy can't
    -- quietly re-open the table either.
    execute format('revoke all on public.%I from anon', t.tablename);
  end loop;
end $$;

-- The portal's one door stays open (v40 grants this too; repeated here so this
-- file is self-sufficient if the two are ever run out of order).
grant execute on function public.client_portal(text) to anon, authenticated;

-- Sanity check — every rs_* table should come back rowsecurity = true.
-- select tablename, rowsecurity from pg_tables
--  where schemaname='public' and tablename like 'rs\_%' order by tablename;

-- ── ROLLBACK ────────────────────────────────────────────────────────────────
-- Puts things back exactly as they were before this file. Use it if the team
-- gets locked out; it re-opens the database to the anon key, so treat it as an
-- emergency measure and re-run v41 once the cause is fixed.
--
-- do $$
-- declare t record;
-- begin
--   for t in select tablename from pg_tables
--             where schemaname='public' and tablename like 'rs\_%'
--   loop
--     execute format('drop policy if exists rs_authenticated_all on public.%I', t.tablename);
--     execute format('alter table public.%I disable row level security', t.tablename);
--     execute format('grant all on public.%I to anon', t.tablename);
--   end loop;
-- end $$;
