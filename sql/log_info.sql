CREATE OR REPLACE FUNCTION major_mode(mode text)
  RETURNS text
  LANGUAGE SQL
  IMMUTABLE
AS $$SELECT CASE WHEN mode = 'CW' THEN 'CW'
WHEN mode IN ('SSB', 'FM') THEN 'PHONE'
ELSE 'DATA' END$$;

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

CREATE OR REPLACE VIEW qso_info AS
SELECT
  (SELECT jsonb_agg(DISTINCT extract(year from start) ORDER BY extract(year from start) desc)) AS years,
  (SELECT jsonb_agg(DISTINCT qrg::band)) AS bands,
  (SELECT jsonb_agg(DISTINCT mode)) AS modes,
  (SELECT jsonb_agg(DISTINCT mycall)) AS mycalls
FROM log;

CREATE OR REPLACE VIEW contest_info(contests) AS
WITH contest_list AS (
  SELECT week(start), dayspan(min(start::date), max(start::date)), contest
  FROM log
  WHERE contest IS NOT NULL
  GROUP BY 1, 3
  ORDER BY 1 DESC, 3 DESC
)
SELECT jsonb_agg(jsonb_build_object('week', week, 'dayspan', dayspan, 'contest', contest))
  FROM contest_list;

CREATE OR REPLACE VIEW log_info(info) AS
SELECT jsonb_build_object(
  'years', years,
  'bands', bands,
  'modes', modes,
  'mycalls', mycalls,
  'contests', contests
) FROM qso_info, contest_info;

GRANT SELECT ON qso_info, contest_info, log_info TO public;
