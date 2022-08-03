CREATE DOMAIN qsl AS char(1)
    CONSTRAINT valid_qsl_request CHECK (VALUE IN ('Y', 'N', 'R'));
