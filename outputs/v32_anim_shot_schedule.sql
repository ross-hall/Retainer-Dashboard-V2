-- v32: adds a work-date range to rs_anim_shots
--
-- Backs the new "Pipeline Timeline" tab on the Animation page — a calendar-
-- month view showing which days an animator is actually scheduled to work
-- each shot, separate from duration_seconds (which is the shot's length in
-- the final edit, not how many days it takes to animate). Both columns are
-- optional: a shot with neither set simply doesn't show a bar yet, and gets
-- a "+ Schedule" prompt in the Pipeline Timeline view instead.

alter table rs_anim_shots add column if not exists work_start_date date;
alter table rs_anim_shots add column if not exists work_end_date date;
