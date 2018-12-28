SELECT log.start, log.qrg, log.call, log2.start, log2.qrg, log2.call FROM log FULL OUTER JOIN log2
  ON (log.start::date = log2.start::date AND
	(log.qrg < 7) = (log2.qrg < 7) AND
	log.call = log2.call)
  WHERE log.start::date IN ('2000-12-26', '2002-12-26')
  ORDER BY log.start;
