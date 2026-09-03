-- v36: adds rs_clients.rollover_hours + rollover_overage + retainer_paused
--
-- Backs the "Retainer settings" modal (client detail page > Retainer
-- settings button) — three independent toggles, all default off/false so
-- every existing retainer client behaves exactly as before until someone
-- deliberately turns one on:
--   rollover_hours   — unused hours from the previous cycle top up this
--                       cycle's allowance (clientUsage()'s effectiveHours).
--   rollover_overage — hours OVER the allowance last cycle are instead
--                       deducted from this cycle's allowance, so an
--                       over-budget month isn't billed separately — noted
--                       on the current cycle's row in the Monthly Allowance
--                       tab. A cycle is never both under and over budget at
--                       once, so rollover_hours/rollover_overage never both
--                       apply to the same previous cycle even if both are on.
--   retainer_paused  — purely presentational: hides the usage meter (client
--                       card + client detail header) behind a "Paused"
--                       status line/badge instead. Does not affect billing
--                       math or task counting.
-- Both rollover directions clamp effectiveHours at 0 — neither a bumper
-- unused-hours credit nor a bad month's overage can push the allowance
-- negative.
--
-- rollover_overage added before this migration's first run (extending
-- rollover_hours/retainer_paused rather than a separate v37) — same
-- precedent as v23/v34's mid-session rewrites documented elsewhere in this
-- project for not-yet-run migrations.

alter table rs_clients add column if not exists rollover_hours boolean not null default false;
alter table rs_clients add column if not exists rollover_overage boolean not null default false;
alter table rs_clients add column if not exists retainer_paused boolean not null default false;

alter table rs_clients disable row level security;
