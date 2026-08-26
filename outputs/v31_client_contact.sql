-- v31: adds an optional named contact + role to rs_clients
--
-- Backs the new contact card pinned to the bottom of the public dashboard's
-- left nav — previously the only way a client could see who's handling
-- their account was a bare "Contact email" field with no name attached.
-- Both are free text and purely presentational; nothing else reads them.

alter table rs_clients add column if not exists dash_contact_name text;
alter table rs_clients add column if not exists dash_contact_role text;
