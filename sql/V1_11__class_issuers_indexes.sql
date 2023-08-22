CREATE INDEX IF NOT EXISTS class_issuers_issuer_idx ON class_issuers (issuer);

CREATE INDEX IF NOT EXISTS class_issuers_credit_class_id_idx ON class_issuers (class_id);

CREATE INDEX IF NOT EXISTS class_issuers_latest_idx ON class_issuers (latest);
