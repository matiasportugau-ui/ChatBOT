-- AUTO-ATC Playbook v3 - Database Schema
-- Esquema completo para chatbot auto-ATC con mensajería, knowledge base y analytics

-- ==========================================
-- CORE TABLES
-- ==========================================

-- Tabla de usuarios/ clientes
CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY,
  external_id TEXT UNIQUE, -- ID de WhatsApp, web, etc.
  platform TEXT NOT NULL, -- whatsapp, web, telegram
  phone_number TEXT,
  email TEXT,
  name TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Tabla de conversaciones
CREATE TABLE IF NOT EXISTS conversations (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  external_conversation_id TEXT UNIQUE, -- ID de Chatwoot
  platform TEXT NOT NULL,
  status TEXT DEFAULT 'active', -- active, closed, pending
  priority TEXT DEFAULT 'normal', -- low, normal, high, urgent
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now(),
  closed_at TIMESTAMP
);

-- Tabla de mensajes
CREATE TABLE IF NOT EXISTS messages (
  id BIGSERIAL PRIMARY KEY,
  conversation_id BIGINT REFERENCES conversations(id) ON DELETE CASCADE,
  external_message_id TEXT UNIQUE, -- ID de WhatsApp/Chatwoot
  direction TEXT NOT NULL, -- inbound, outbound
  message_type TEXT DEFAULT 'text', -- text, image, file, location
  content TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT now()
);

-- Tabla de productos/servicios para knowledge base
CREATE TABLE IF NOT EXISTS products (
  id BIGSERIAL PRIMARY KEY,
  sku TEXT UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT,
  price DECIMAL(10,2),
  currency TEXT DEFAULT 'USD',
  stock_quantity INTEGER DEFAULT 0,
  metadata JSONB DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Tabla de cotizaciones
CREATE TABLE IF NOT EXISTS quotes (
  id BIGSERIAL PRIMARY KEY,
  conversation_id BIGINT REFERENCES conversations(id) ON DELETE CASCADE,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'draft', -- draft, sent, accepted, rejected, expired
  products JSONB DEFAULT '[]', -- Array de productos con cantidades
  total_amount DECIMAL(10,2),
  currency TEXT DEFAULT 'USD',
  valid_until TIMESTAMP,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- ==========================================
-- KNOWLEDGE BASE TABLES
-- ==========================================

-- Tabla de documentos de knowledge base
CREATE TABLE IF NOT EXISTS kb_documents (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT,
  content_type TEXT DEFAULT 'text', -- text, markdown, html
  category TEXT,
  tags TEXT[] DEFAULT '{}',
  embedding_vector VECTOR(1536), -- Para OpenAI embeddings
  metadata JSONB DEFAULT '{}',
  source_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Tabla de sugerencias de knowledge base (para feedback del usuario)
CREATE TABLE IF NOT EXISTS kb_suggestions (
  id BIGSERIAL PRIMARY KEY,
  title TEXT,
  content TEXT,
  suggested_by BIGINT REFERENCES users(id),
  status TEXT DEFAULT 'pending', -- pending, approved, rejected, implemented
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT now(),
  reviewed_at TIMESTAMP,
  reviewed_by TEXT
);

-- ==========================================
-- ANALYTICS TABLES
-- ==========================================

-- Tabla de interacciones (legacy support)
CREATE TABLE IF NOT EXISTS interactions(
  id BIGSERIAL PRIMARY KEY,
  conversation_id TEXT,
  resumen TEXT,
  productos JSONB,
  created_at TIMESTAMP DEFAULT now()
);

-- Tabla de métricas de rendimiento
CREATE TABLE IF NOT EXISTS performance_metrics (
  id BIGSERIAL PRIMARY KEY,
  metric_name TEXT NOT NULL,
  metric_value DECIMAL(10,4),
  metric_unit TEXT,
  metadata JSONB DEFAULT '{}',
  recorded_at TIMESTAMP DEFAULT now()
);

-- Tabla de logs de errores
CREATE TABLE IF NOT EXISTS error_logs (
  id BIGSERIAL PRIMARY KEY,
  error_type TEXT NOT NULL,
  error_message TEXT,
  stack_trace TEXT,
  context JSONB DEFAULT '{}',
  resolved BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT now()
);

-- ==========================================
-- INDEXES FOR PERFORMANCE
-- ==========================================

-- Users indexes
CREATE INDEX IF NOT EXISTS idx_users_external_id ON users(external_id);
CREATE INDEX IF NOT EXISTS idx_users_platform ON users(platform);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- Conversations indexes
CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_external_id ON conversations(external_conversation_id);
CREATE INDEX IF NOT EXISTS idx_conversations_status ON conversations(status);
CREATE INDEX IF NOT EXISTS idx_conversations_created_at ON conversations(created_at);

-- Messages indexes
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_direction ON messages(direction);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);
CREATE INDEX IF NOT EXISTS idx_messages_content_gin ON messages USING gin(to_tsvector('spanish', content));

-- Products indexes
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_name_gin ON products USING gin(to_tsvector('spanish', name));
CREATE INDEX IF NOT EXISTS idx_products_description_gin ON products USING gin(to_tsvector('spanish', description));

-- Quotes indexes
CREATE INDEX IF NOT EXISTS idx_quotes_conversation_id ON quotes(conversation_id);
CREATE INDEX IF NOT EXISTS idx_quotes_user_id ON quotes(user_id);
CREATE INDEX IF NOT EXISTS idx_quotes_status ON quotes(status);
CREATE INDEX IF NOT EXISTS idx_quotes_created_at ON quotes(created_at);

-- KB Documents indexes
CREATE INDEX IF NOT EXISTS idx_kb_documents_category ON kb_documents(category);
CREATE INDEX IF NOT EXISTS idx_kb_documents_tags ON kb_documents USING gin(tags);
CREATE INDEX IF NOT EXISTS idx_kb_documents_title_gin ON kb_documents USING gin(to_tsvector('spanish', title));
CREATE INDEX IF NOT EXISTS idx_kb_documents_content_gin ON kb_documents USING gin(to_tsvector('spanish', content));
CREATE INDEX IF NOT EXISTS idx_kb_documents_embedding_vector ON kb_documents USING ivfflat (embedding_vector vector_cosine_ops);

-- KB Suggestions indexes
CREATE INDEX IF NOT EXISTS idx_kb_suggestions_status ON kb_suggestions(status);
CREATE INDEX IF NOT EXISTS idx_kb_suggestions_created_at ON kb_suggestions(created_at);

-- Performance metrics indexes
CREATE INDEX IF NOT EXISTS idx_performance_metrics_name ON performance_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_recorded_at ON performance_metrics(recorded_at);

-- Error logs indexes
CREATE INDEX IF NOT EXISTS idx_error_logs_type ON error_logs(error_type);
CREATE INDEX IF NOT EXISTS idx_error_logs_resolved ON error_logs(resolved);
CREATE INDEX IF NOT EXISTS idx_error_logs_created_at ON error_logs(created_at);

-- ==========================================
-- TRIGGERS FOR UPDATED_AT
-- ==========================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Aplicar triggers a tablas con updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON conversations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_quotes_updated_at BEFORE UPDATE ON quotes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_kb_documents_updated_at BEFORE UPDATE ON kb_documents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

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
