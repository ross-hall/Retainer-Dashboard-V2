-- v33: adds rs_projects.requires_animation
--
-- Lets a project whose main type isn't an animation type (Website, Deck,
-- Branding, ...) still get its own shot/step pipeline — for the case where
-- a client needs embedded animation/renders inside a differently-typed
-- deliverable, not a full standalone 60-120s animation project. Shows up
-- on the Animation page under a separate "Embedded Animation Work" heading
-- from full animation-type projects.
--
-- A boolean column rather than another project_type string check, matching
-- this project's standing convention (see rs_stage_categories.zone) of
-- avoiding branching on a user-editable type name — that's the exact bug
-- class documented elsewhere in this codebase for the "Deck projects"
-- rename and the Website brief-summary rename.

alter table rs_projects add column if not exists requires_animation boolean not null default false;

alter table rs_projects disable row level security;
