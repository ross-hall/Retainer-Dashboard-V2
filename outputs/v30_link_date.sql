-- v30: adds an optional date to rs_stage_links
--
-- Backs the new "date of meeting" column on the public dashboard's Meeting
-- Notes rows (a Loom recording is usually added after the meeting happened,
-- so the date needs to be its own field, not inferred from created_at). The
-- field is generic (link_date, not meeting_date) and available on every link
-- via the ordinary link modal, but only Meeting Notes actually displays it —
-- harmless/unused on every other link.

alter table rs_stage_links add column if not exists link_date date;
