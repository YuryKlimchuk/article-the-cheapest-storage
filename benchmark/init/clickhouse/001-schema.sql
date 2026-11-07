-- Audit-event schema for the storage benchmark (phase 1).
--
-- Logical model (ClickHouse native types):
--   id        -> UUID
--   timestamp -> DateTime64(3, 'UTC') (datetime with timezone, millisecond precision)
--   userId    -> Int64
--   eventType -> Enum8 (TYPE_1..TYPE_50)
--   metadata  -> String (JSON text; the JSON/Object type is experimental in 24.8)
--
-- Phase-1 fairness: full field names, native types, default MergeTree LZ4
-- column compression, and the mandatory (userId, timestamp) index expressed
-- as the MergeTree ORDER BY / PRIMARY KEY.

CREATE DATABASE IF NOT EXISTS benchmark;

CREATE TABLE benchmark.audit_events
(
    id UUID,
    `timestamp` DateTime64(3, 'UTC'),
    user_id Int64,
    event_type Enum8(
        'TYPE_1' = 1,   'TYPE_2' = 2,   'TYPE_3' = 3,   'TYPE_4' = 4,   'TYPE_5' = 5,
        'TYPE_6' = 6,   'TYPE_7' = 7,   'TYPE_8' = 8,   'TYPE_9' = 9,   'TYPE_10' = 10,
        'TYPE_11' = 11, 'TYPE_12' = 12, 'TYPE_13' = 13, 'TYPE_14' = 14, 'TYPE_15' = 15,
        'TYPE_16' = 16, 'TYPE_17' = 17, 'TYPE_18' = 18, 'TYPE_19' = 19, 'TYPE_20' = 20,
        'TYPE_21' = 21, 'TYPE_22' = 22, 'TYPE_23' = 23, 'TYPE_24' = 24, 'TYPE_25' = 25,
        'TYPE_26' = 26, 'TYPE_27' = 27, 'TYPE_28' = 28, 'TYPE_29' = 29, 'TYPE_30' = 30,
        'TYPE_31' = 31, 'TYPE_32' = 32, 'TYPE_33' = 33, 'TYPE_34' = 34, 'TYPE_35' = 35,
        'TYPE_36' = 36, 'TYPE_37' = 37, 'TYPE_38' = 38, 'TYPE_39' = 39, 'TYPE_40' = 40,
        'TYPE_41' = 41, 'TYPE_42' = 42, 'TYPE_43' = 43, 'TYPE_44' = 44, 'TYPE_45' = 45,
        'TYPE_46' = 46, 'TYPE_47' = 47, 'TYPE_48' = 48, 'TYPE_49' = 49, 'TYPE_50' = 50
    ),
    metadata String
)
ENGINE = MergeTree
ORDER BY (user_id, `timestamp`)
PRIMARY KEY (user_id, `timestamp`);
