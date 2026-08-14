-- v28: adds 'notes' as a valid rs_stage_categories.zone value
--
-- Backs the new "Meeting Notes" grid on the public client dashboard — a
-- second, separate flat grid of link-cards below "Stage Materials". Purely a
-- constraint change; general/proofing/brief/vault (all now flattened into one
-- "Stage Materials" grid client-side, see CLAUDE.md v0.37.0 notes) are
-- unaffected, and no existing category needs to change zone.

alter table rs_stage_categories drop constraint if exists rs_stage_categories_zone_check;
alter table rs_stage_categories add constraint rs_stage_categories_zone_check
  check (zone in ('general','proofing','brief','vault','notes'));
