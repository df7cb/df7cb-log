CREATE OR REPLACE FUNCTION logtrigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN

  -- fixed
  IF NEW.mycall = 'DF7CB' THEN
    IF NEW.myqth IS NULL THEN NEW.myqth := 'Krefeld'; END IF;
    IF NEW.myqth = 'Krefeld' THEN
      IF NEW.myloc IS NULL THEN NEW.myloc := 'JO31HI'; END IF;
    END IF;

    -- shortwave
    IF NEW.qrg < 60 THEN
      IF NEW.mode IS NULL THEN NEW.mode := 'CW'; END IF;
      IF NEW.mytrx IS NULL THEN NEW.mytrx := 'IC706'; END IF;
      IF NEW.myant IS NULL THEN NEW.myant := 'FD4'; END IF;
      IF NEW.mypwr IS NULL THEN
        NEW.mypwr := CASE NEW.qrg::band
          WHEN '60m' THEN 15
          WHEN '6m' THEN 50
          ELSE 100
        END;
      END IF;

    -- 2m
    ELSIF NEW.qrg::band IN ('2m', '70cm') THEN
      IF NEW.mode = 'FM' THEN
        IF NEW.mytrx IS NULL THEN NEW.mytrx := 'TM733'; END IF;
        IF NEW.mypwr IS NULL THEN NEW.mypwr := '5'; END IF;
      ELSE
        IF NEW.mytrx IS NULL THEN NEW.mytrx := 'IC706'; END IF;
        IF NEW.mypwr IS NULL THEN NEW.mypwr := '10'; END IF;
      END IF;
      IF NEW.myant IS NULL THEN NEW.myant := 'X200'; END IF;

    -- 13cm/QO100
    ELSIF NEW.qrg::band IN ('13cm') THEN
      IF NEW.mytrx IS NULL THEN NEW.mytrx := 'LimeSDR'; END IF;
      IF NEW.mypwr IS NULL THEN NEW.mypwr := '3'; END IF;
      IF NEW.myant IS NULL THEN NEW.myant := '1m dish'; END IF;
    END IF;

  -- mobile
  ELSIF NEW.mycall = 'DF7CB/M' THEN
    IF NEW.qrg::band IN ('2m', '70cm') THEN
      IF NEW.myloc IS NULL THEN NEW.myloc := 'JO31'; END IF;
      IF NEW.mytrx IS NULL THEN NEW.mytrx := 'FT7900'; END IF;
      IF NEW.myant IS NULL THEN NEW.myant := 'GP'; END IF;
      IF NEW.mypwr IS NULL THEN NEW.mypwr := '20'; END IF;
    END IF;

  -- portable
  ELSIF NEW.mycall = 'DF7CB/P' THEN
    IF NEW.qrg::band IN ('2m', '70cm') THEN
      IF NEW.myloc IS NULL THEN NEW.myloc := 'JO31'; END IF;
      IF NEW.mytrx IS NULL THEN NEW.mytrx := 'Baofeng 5V'; END IF;
      --IF NEW.myant IS NULL THEN NEW.myant := 'GP'; END IF;
      IF NEW.mypwr IS NULL THEN NEW.mypwr := '5'; END IF;
    END IF;
  END IF;

  IF NEW.cty IS NULL THEN
    NEW.cty = cty(NEW.call);
  END IF;

  RETURN NEW;
END;$$;
