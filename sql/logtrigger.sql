CREATE OR REPLACE FUNCTION logtrigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  ts timestamptz;
BEGIN

  -- fixed
  IF NEW.mycall = 'DF7CB' THEN
    IF NEW.myqth IS NULL THEN NEW.myqth := 'Krefeld'; END IF;
    IF NEW.myqth = 'Krefeld' THEN
      IF NEW.myloc IS NULL THEN NEW.myloc := 'JO31HI'; END IF;
    END IF;

    -- shortwave
    IF NEW.qrg < 60 THEN
      IF NEW.mode IS NULL THEN NEW.mode := 'CW'; END IF;
      IF NEW.mytrx IS NULL THEN NEW.mytrx := 'IC7610'; END IF;
      --IF NEW.mytrx IS NULL THEN NEW.mytrx := 'IC706'; END IF;
      IF NEW.myant IS NULL THEN
        IF NEW.qrg >= 14 THEN
          NEW.myant := 'Spiderbeam';
        ELSIF NEW.qrg between 7 and 7.2 THEN
          NEW.myant := 'Rotary dipole';
        ELSE
          NEW.myant := 'FD4';
        END IF;
      END IF;
      IF NEW.mypwr IS NULL THEN
        NEW.mypwr := CASE NEW.qrg::band
          WHEN '60m' THEN 15
          ELSE 100
        END;
      END IF;

    -- 2m
    ELSIF NEW.qrg::band IN ('2m', '70cm') THEN
      IF NEW.mode = 'FM' THEN
        IF NEW.mytrx IS NULL THEN NEW.mytrx := 'TM733'; END IF;
        IF NEW.mypwr IS NULL THEN NEW.mypwr := '5'; END IF;
      --ELSE
      --  IF NEW.mytrx IS NULL THEN NEW.mytrx := 'IC706'; END IF;
      --  IF NEW.mypwr IS NULL THEN NEW.mypwr := '10'; END IF;
      END IF;
      IF NEW.myant IS NULL THEN NEW.myant := 'X200'; END IF;

    -- 13cm/QO100
    ELSIF NEW.qrg BETWEEN 2400 AND 2450 THEN
      IF NEW.mytrx IS NULL THEN NEW.mytrx := 'LimeSDR'; END IF;
      IF NEW.mypwr IS NULL THEN NEW.mypwr := '1'; END IF;
      IF NEW.myant IS NULL THEN NEW.myant := '1m dish'; END IF;
      IF NEW.qso_via IS NULL THEN NEW.qso_via := 'QO100'; END IF;
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

  -- Canada
  ELSIF NEW.mycall = 'VE7/DF7CB' THEN
    IF NEW.qrg < 60 THEN
      IF NEW.myqth IS NULL THEN NEW.myqth := 'North Vancouver'; END IF;
      IF NEW.myloc IS NULL THEN NEW.myloc := 'CN89KH'; END IF;
      IF NEW.mytrx IS NULL THEN NEW.mytrx := 'IC705'; END IF;
      IF NEW.myant IS NULL THEN NEW.myant := 'LW'; END IF;
      IF NEW.mypwr IS NULL THEN NEW.mypwr := '5'; END IF;
    END IF;

  -- Romania
  ELSIF NEW.mycall = 'YO/DF7CB' THEN
    IF NEW.qrg < 60 THEN
      IF NEW.myqth IS NULL THEN NEW.myqth := 'Brasov'; END IF;
      IF NEW.myloc IS NULL THEN NEW.myloc := 'KN25sp'; END IF;
      IF NEW.mytrx IS NULL THEN NEW.mytrx := 'IC705'; END IF;
      IF NEW.myant IS NULL THEN NEW.myant := 'Magloop'; END IF;
      IF NEW.mypwr IS NULL THEN NEW.mypwr := '5'; END IF;
    END IF;

  END IF;

  -- RST
  IF NEW.rsttx IS NULL THEN
    NEW.rsttx := CASE
      WHEN NEW.mode IN ('CW', 'RTTY', 'HELL') THEN 599
      WHEN NEW.qso_via IS NOT NULL THEN '5'
      ELSE '59' END;
  END IF;
  IF NEW.rstrx IS NULL THEN
    NEW.rstrx := CASE
      WHEN NEW.mode IN ('CW', 'RTTY', 'HELL') THEN 599
      WHEN NEW.qso_via IS NOT NULL THEN '5'
      ELSE '59' END;
  END IF;

  -- cty
  IF NEW.cty IS NULL THEN
    NEW.cty = public.call2cty(NEW.call);
  END IF;
  IF NEW.cq IS NULL THEN
    NEW.cq = public.cq(NEW.call);
  END IF;
  IF NEW.itu IS NULL THEN
    NEW.itu = public.itu(NEW.call);
  END IF;

  -- comment: note new bandpoints
  if new.comment is null and new.cty is not null then
    select start into ts from log where cty = new.cty limit 1;
    if not found then
      new.comment = 'ATNO';
    end if;
  end if;
  if new.comment is null and new.cty is not null then
    select start into ts from log where cty = new.cty and qrg::band = new.qrg::band and major_mode(mode) = major_mode(new.mode) limit 1;
    if not found then
      new.comment = 'new bandpoint';
    end if;
  end if;

  RETURN NEW;
END;$$;
