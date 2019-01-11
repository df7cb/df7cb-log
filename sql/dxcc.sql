CREATE TABLE dxcc_import (
  prefix text,
  country text,
  continent text,
  itu text,
  cq text,
  tz text,
  lat text,
  lon text,
  itu_prefixes text,
  amateur_prefxes text
);

\copy dxcc_import from 'dxcc.txt' (format csv, delimiter ':')

DELETE FROM dxcc_import WHERE prefix IS NULL OR prefix LIKE '%*%';

SELECT string_agg(''',''', prefix) AS prefix0 FROM dxcc_import \gset
SELECT regexp_replace(:'prefix0', '^'',|,''$', '', 'g') AS prefix \gset

--CREATE TYPE prefix AS ENUM(:prefix);
