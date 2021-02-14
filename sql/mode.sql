CREATE OR REPLACE FUNCTION adif_mode(mode text)
RETURNS text LANGUAGE SQL
AS $$SELECT CASE mode
WHEN 'FT4' THEN 'MFSK'
WHEN 'JS8' THEN 'MFSK'
WHEN 'PSK31' THEN 'PSK'
WHEN 'PSK63' THEN 'PSK'
WHEN 'PSK125' THEN 'PSK'
ELSE mode
END$$;