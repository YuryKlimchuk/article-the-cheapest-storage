-- Audit-event schema for the storage benchmark (phase 1).
--
-- Logical model:
--   id        -> UUID
--   timestamp -> TIMESTAMPTZ (datetime with timezone, millisecond precision)
--   userId    -> BIGINT (int64)
--   eventType -> native ENUM (TYPE_1..TYPE_50)
--   metadata  -> JSONB (JSON object)
--
-- Phase-1 fairness: full field names, native types, default TOAST compression,
-- and only the mandatory (userId, timestamp) access-path index.

CREATE TYPE event_type AS ENUM (
    'TYPE_1',  'TYPE_2',  'TYPE_3',  'TYPE_4',  'TYPE_5',
    'TYPE_6',  'TYPE_7',  'TYPE_8',  'TYPE_9',  'TYPE_10',
    'TYPE_11', 'TYPE_12', 'TYPE_13', 'TYPE_14', 'TYPE_15',
    'TYPE_16', 'TYPE_17', 'TYPE_18', 'TYPE_19', 'TYPE_20',
    'TYPE_21', 'TYPE_22', 'TYPE_23', 'TYPE_24', 'TYPE_25',
    'TYPE_26', 'TYPE_27', 'TYPE_28', 'TYPE_29', 'TYPE_30',
    'TYPE_31', 'TYPE_32', 'TYPE_33', 'TYPE_34', 'TYPE_35',
    'TYPE_36', 'TYPE_37', 'TYPE_38', 'TYPE_39', 'TYPE_40',
    'TYPE_41', 'TYPE_42', 'TYPE_43', 'TYPE_44', 'TYPE_45',
    'TYPE_46', 'TYPE_47', 'TYPE_48', 'TYPE_49', 'TYPE_50'
);

CREATE TABLE audit_events (
    id UUID NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    user_id BIGINT NOT NULL,
    event_type event_type NOT NULL,
    metadata JSONB NOT NULL
);

CREATE INDEX idx_audit_user_ts ON audit_events (user_id, timestamp);
