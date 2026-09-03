-- v36: adds rs_clients.rollover_hours + rs_clients.retainer_paused
--
-- Backs the new "Retainer settings" modal (client detail page > Retainer
-- settings button) — two independent toggles, both default off/false so
-- every existing retainer client behaves exactly as before until someone
-- deliberately turns one on:
--   rollover_hours  — unused hours from the previous cycle top up this
--                      cycle's allowance (clientUsage()'s effectiveHours),
--                      clamped at 0 so an over-budget cycle never carries
--                      a negative balance forward.
--   retainer_paused — purely presentational: hides the usage meter (client
--                      card + client detail header) behind a "Paused"
--                      status line/badge instead. Does not affect billing
--                      math or task counting.

alter table rs_clients add column if not exists rollover_hours boolean not null default false;
alter table rs_clients add column if not exists retainer_paused boolean not null default false;

alter table rs_clients disable row level security;
