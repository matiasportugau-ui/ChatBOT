CREATE TABLE IF NOT EXISTS interactions(
  id BIGSERIAL PRIMARY KEY,
  conversation_id TEXT,
  resumen TEXT,
  productos JSONB,
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS kb_suggestions(
  id BIGSERIAL PRIMARY KEY,
  title TEXT,
  content TEXT,
  metadata JSONB,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT now()
);

# EXPORT_SEAL v1
# project: auto-atc
# prompt_id: db-schema-v3
# version: 3.0.0
# file: db/schema.sql
# lang: sql
# created_at: 2025-10-31T00:10:55Z
# author: GPT-5 Thinking
# origin: db-impl
# body_sha256: 0b2bcfa0ee788a3ff8e8ff4560845673782774cf01fdb44ff1987584e369b752
