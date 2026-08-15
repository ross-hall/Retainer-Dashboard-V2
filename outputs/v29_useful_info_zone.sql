-- v29: adds 'useful' as a valid rs_stage_categories.zone value
--
-- Backs the new "Useful Information" grid on the public dashboard's new Home
-- page — a client-wide (not project/stage-scoped) grid of link/PDF cards for
-- reference material (rate cards, brand guidelines, contracts, onboarding
-- docs, etc). Purely a constraint change, same pattern as v28's 'notes' zone;
-- no existing category needs to change zone, nothing else is affected.

alter table rs_stage_categories drop constraint if exists rs_stage_categories_zone_check;
alter table rs_stage_categories add constraint rs_stage_categories_zone_check
  check (zone in ('general','proofing','brief','vault','notes','useful'));
