// Audit-event schema for the storage benchmark (phase 1).
//
// Logical model (MongoDB native types):
//   id        -> _id stored as a binary UUID (subtype 4); the mandatory _id
//                index is inherent to MongoDB and reported in the
//                data-vs-index row, not the headline.
//   timestamp -> Date (millisecond precision)
//   userId    -> Long (int64)
//   eventType -> String (TYPE_1..TYPE_50; MongoDB has no native enum type)
//   metadata  -> Object (JSON)
//
// Phase-1 fairness: full field names, native types, default WiredTiger snappy
// compression, and the mandatory (userId, timestamp) access-path index.

const auditDb = db.getSiblingDB('benchmark');

auditDb.createCollection('audit_events');

auditDb.audit_events.createIndex(
    { userId: 1, timestamp: 1 },
    { name: 'idx_userId_timestamp' }
);
