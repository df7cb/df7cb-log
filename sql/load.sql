BEGIN;
\ir country.sql
\ir locator.sql
\ir log.sql
COMMIT;
--\! shp2pgsql -DIs 4326 ne_10m_admin_0_map_subunits/ne_10m_admin_0_map_subunits > ne_10m_admin_0_map_subunits.sql
\ir ne_10m_admin_0_map_subunits.sql
\ir map.sql

create function error(message text) returns text as $$begin raise exception '%', message; return null; end;$$ language plpgsql;
