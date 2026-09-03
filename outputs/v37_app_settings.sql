-- v37: adds rs_app_settings
--
-- A small global key/value store for app-wide numbers/toggles that aren't
-- tied to any one client, project, or member — the first (and, for now,
-- only) entry is 'holiday_days_per_year', edited from Settings > Admin
-- settings (a new, deliberately separate Settings section, since every
-- other section edits a list of records rather than a single app-wide
-- value). Drives the "days left this year" line at the top of the Time Off
-- page (holidayDaysRemainingThisYear() in index.html).
--
-- Key/value rather than named columns on some other table because this is
-- expected to grow with more one-off admin settings over time, and a new
-- setting shouldn't need its own migration each time.

create table if not exists rs_app_settings (
  key text primary key,
  value text
);

alter table rs_app_settings disable row level security;

insert into rs_app_settings (key, value) values ('holiday_days_per_year', '25')
on conflict (key) do nothing;
