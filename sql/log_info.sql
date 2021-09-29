CREATE OR REPLACE FUNCTION week(ts timestamptz)
  RETURNS text
  LANGUAGE SQL
  STABLE
AS $$SELECT extract(year from ts) || '-' || to_char(extract(week from ts), 'FM00')$$;

CREATE OR REPLACE FUNCTION dayspan(date1 date, date2 date)
  RETURNS text
  LANGUAGE SQL
  IMMUTABLE
AS $$SELECT CASE WHEN date1 <> date2 THEN date1 || '..' || to_char(extract(day from date2), 'FM00') ELSE date1::text END$$;

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
    SELECT week(start), dayspan(min(start::date), max(start::date)), contest
    FROM log WHERE contest IS NOT NULL
    GROUP BY 1, 3
    ORDER BY 1 DESC, 3 DESC
  ),
  contestlist(contestlist) AS (
    SELECT jsonb_agg(jsonb_build_object('week', week, 'dayspan', dayspan, 'contest', contest)) FROM contests
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
