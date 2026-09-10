-- v39: adds rs_members.email — the link between a Supabase Auth user and a
-- team member row.
--
-- STEP 1 OF 3 in turning on RLS properly. Run this one FIRST; it is completely
-- non-breaking on its own (the app keeps working signed-out until v41 lands).
--   v39 (this file) — add the email link + the app's login screen
--   v40             — the client-portal RPC that replaces anon table reads
--   v41             — enable RLS and revoke anon.  RUN LAST, see its header.
--
-- Why email rather than a uuid FK to auth.users: the app matches the signed-in
-- session's email against this column (currentUser() in index.html), so a member
-- can be linked from the Settings > Team members screen without anyone having to
-- copy auth uuids around. The trade-off is that changing someone's login email
-- means changing it here too — acceptable for a team of nine.
--
-- Nullable on purpose. Until a member has an email set, currentUser() falls back
-- to the old CURRENT_USER_NAME name-match, so filling these in can happen at
-- leisure rather than being a hard cutover.

alter table rs_members add column if not exists email text;

-- Case-insensitive uniqueness: two members must never claim the same login, but
-- nulls are free (a member who doesn't need app access simply has no email).
create unique index if not exists rs_members_email_unique
  on rs_members (lower(email))
  where email is not null;

-- RLS: enable + the standard authenticated-only policy, matching v41.
-- This file originally ended with `alter table rs_members disable row level
-- security;` — correct under the old convention, but actively harmful now that
-- v41 has run: it would have re-opened rs_members to the anon key. Every
-- migration from here on uses this block instead. Safe to run before or after
-- v41; it's idempotent either way.
alter table rs_members enable row level security;
drop policy if exists rs_authenticated_all on rs_members;
create policy rs_authenticated_all on rs_members
  for all to authenticated using (true) with check (true);
revoke all on rs_members from anon;

-- ⚠️ THIS IS NO LONGER OPTIONAL, AND THIS FILE IS NO LONGER SAFE TO SKIP.
-- As of v0.78.0 currentUser() has NO name fallback: a signed-in session with no
-- matching email here resolves to nobody, and the app shows an unidentified
-- state (no Home greeting, no holiday balance, no time-off admin rights). That
-- is the point — the old fallback silently resolved any new teammate's first
-- login to Ross, handing them his tasks and his approval rights. The trade-off
-- is that until this column exists and holds your address, nobody is
-- identified, including you.
--
-- So this file now links the row itself rather than leaving it commented out.
-- Change the address if you sign in as something else, and add a line per
-- teammate as they get logins (or use Settings > Team members > Login email).
update rs_members set email = 'r.hall@reciprocal.space'
 where name = 'Ross Hall' and email is null;
