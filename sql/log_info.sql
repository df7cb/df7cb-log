CREATE OR REPLACE FUNCTION week(ts timestamptz)
  RETURNS text
  LANGUAGE SQL
  STABLE
AS $$SELECT extract(year from ts) || '-' || to_char(extract(week from ts), 'FM00')$$;

CREATE OR REPLACE VIEW log_info(info) AS
  WITH
  years(years) AS (
    SELECT jsonb_agg(DISTINCT extract(year from start)) FROM log
  ),
  bands(bands) AS (
    SELECT jsonb_agg(DISTINCT qrg::band) FROM log
  ),
  modes(modes) AS (
    SELECT jsonb_agg(DISTINCT mode) FROM log
  ),
  mycalls(mycalls) AS (
    SELECT jsonb_agg(DISTINCT mycall) FROM log
  ),
  contests AS (
    SELECT DISTINCT week(start), contest
    FROM log WHERE contest IS NOT NULL ORDER BY 1 DESC, 2 DESC
  ),
  contestlist(contestlist) AS (
    SELECT jsonb_agg(week || ' ' || contest) FROM contests
  )
  SELECT
    jsonb_build_object(
      'years', years,
      'bands', bands,
      'modes', modes,
      'mycalls', mycalls,
      'contests', contestlist
    )
    FROM years, bands, modes, mycalls, contestlist;

GRANT SELECT ON log_info TO public;
