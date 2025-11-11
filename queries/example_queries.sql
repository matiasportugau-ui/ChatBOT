-- ============================================
-- Example SQL Queries for ChatBOT-full Project
-- ============================================
-- These queries can be executed in SQLTools
-- Select connection: "PostgreSQL - ChatBOT (Docker)" or "PostgreSQL - ChatBOT (Local)"
-- ============================================

-- ============================================
-- 1. DATABASE INFORMATION
-- ============================================

-- List all tables
SELECT 
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Get table row counts
SELECT 
    'interactions' as table_name,
    COUNT(*) as row_count
FROM interactions
UNION ALL
SELECT 
    'knowledge_base' as table_name,
    COUNT(*) as row_count
FROM knowledge_base
UNION ALL
SELECT 
    'kb_suggestions' as table_name,
    COUNT(*) as row_count
FROM kb_suggestions;

-- ============================================
-- 2. INTERACTIONS TABLE
-- ============================================

-- View recent interactions
SELECT 
    id,
    conversation_id,
    resumen,
    productos,
    created_at
FROM interactions
ORDER BY created_at DESC
LIMIT 20;

-- Count interactions by date
SELECT 
    DATE(created_at) as date,
    COUNT(*) as interaction_count
FROM interactions
GROUP BY DATE(created_at)
ORDER BY date DESC
LIMIT 30;

-- View interactions with parsed JSON products
SELECT 
    id,
    conversation_id,
    resumen,
    jsonb_array_elements(productos) as product,
    created_at
FROM interactions
WHERE productos IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- 3. KNOWLEDGE BASE TABLE
-- ============================================

-- View all knowledge base entries
SELECT 
    id,
    topic,
    correction,
    context,
    timestamp,
    type,
    created_at
FROM knowledge_base
ORDER BY created_at DESC;

-- Search knowledge base by topic
SELECT 
    id,
    topic,
    correction,
    created_at
FROM knowledge_base
WHERE topic ILIKE '%precio%'
   OR correction ILIKE '%precio%'
ORDER BY created_at DESC;

-- Count knowledge base entries by type
SELECT 
    type,
    COUNT(*) as count
FROM knowledge_base
GROUP BY type;

-- ============================================
-- 4. KB SUGGESTIONS TABLE
-- ============================================

-- View pending suggestions
SELECT 
    id,
    title,
    content,
    metadata,
    status,
    created_at
FROM kb_suggestions
WHERE status = 'pending'
ORDER BY created_at DESC;

-- View all suggestions by status
SELECT 
    status,
    COUNT(*) as count
FROM kb_suggestions
GROUP BY status;

-- ============================================
-- 5. CURSOR EXAMPLES (for Cursor Agent)
-- ============================================

-- Example 1: Process recent interactions
-- Use this query in Cursor Agent config
SELECT 
    id,
    conversation_id,
    resumen,
    productos,
    created_at
FROM interactions
WHERE created_at > NOW() - INTERVAL '1 day'
ORDER BY created_at;

-- Example 2: Process pending knowledge base suggestions
SELECT 
    id,
    title,
    content,
    metadata,
    status
FROM kb_suggestions
WHERE status = 'pending'
ORDER BY created_at;

-- Example 3: Process knowledge base entries by topic
SELECT 
    id,
    topic,
    correction,
    context
FROM knowledge_base
WHERE topic = 'precio'
ORDER BY created_at DESC;

-- ============================================
-- 6. TEST CURSOR OPERATIONS
-- ============================================

-- Test cursor declaration and fetching
BEGIN;

DECLARE test_cursor CURSOR FOR
    SELECT id, conversation_id, resumen
    FROM interactions
    WHERE created_at > NOW() - INTERVAL '7 days'
    ORDER BY created_at;

-- Fetch first row
FETCH NEXT FROM test_cursor;

-- Fetch more rows (repeat as needed)
FETCH NEXT FROM test_cursor;
FETCH NEXT FROM test_cursor;

-- Close cursor
CLOSE test_cursor;

-- Review results before committing
-- If satisfied: COMMIT;
-- If not: ROLLBACK;
ROLLBACK; -- Change to COMMIT; when ready

-- ============================================
-- 7. MAINTENANCE QUERIES
-- ============================================

-- Check table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Find tables with most rows
SELECT 
    'interactions' as table_name,
    COUNT(*) as row_count
FROM interactions
UNION ALL
SELECT 
    'knowledge_base' as table_name,
    COUNT(*) as row_count
FROM knowledge_base
UNION ALL
SELECT 
    'kb_suggestions' as table_name,
    COUNT(*) as row_count
FROM kb_suggestions
ORDER BY row_count DESC;

-- Check for duplicate conversation_ids
SELECT 
    conversation_id,
    COUNT(*) as count
FROM interactions
GROUP BY conversation_id
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- ============================================
-- 8. ANALYTICS QUERIES
-- ============================================

-- Daily interaction statistics
SELECT 
    DATE(created_at) as date,
    COUNT(*) as total_interactions,
    COUNT(DISTINCT conversation_id) as unique_conversations
FROM interactions
GROUP BY DATE(created_at)
ORDER BY date DESC
LIMIT 30;

-- Most active conversation IDs
SELECT 
    conversation_id,
    COUNT(*) as interaction_count,
    MAX(created_at) as last_interaction
FROM interactions
GROUP BY conversation_id
ORDER BY interaction_count DESC
LIMIT 10;

-- Knowledge base growth over time
SELECT 
    DATE(created_at) as date,
    COUNT(*) as entries_added
FROM knowledge_base
GROUP BY DATE(created_at)
ORDER BY date DESC
LIMIT 30;

-- ============================================
-- 9. DATA VALIDATION QUERIES
-- ============================================

-- Check for NULL values in critical columns
SELECT 
    'interactions' as table_name,
    COUNT(*) FILTER (WHERE conversation_id IS NULL) as null_conversation_id,
    COUNT(*) FILTER (WHERE resumen IS NULL) as null_resumen
FROM interactions
UNION ALL
SELECT 
    'knowledge_base' as table_name,
    COUNT(*) FILTER (WHERE topic IS NULL) as null_topic,
    COUNT(*) FILTER (WHERE correction IS NULL) as null_correction
FROM knowledge_base;

-- Validate JSON structure in productos column
SELECT 
    id,
    conversation_id,
    productos,
    jsonb_typeof(productos) as json_type
FROM interactions
WHERE productos IS NOT NULL
LIMIT 10;

-- ============================================
-- 10. EXAMPLE PL/pgSQL FUNCTIONS FOR CURSOR AGENT
-- ============================================

-- Function to process an interaction
CREATE OR REPLACE FUNCTION process_interaction(
    p_id BIGINT,
    p_conversation_id TEXT,
    p_resumen TEXT
) RETURNS VOID AS $$
BEGIN
    -- Example: Log processed interactions
    INSERT INTO processed_interactions_log (
        interaction_id,
        conversation_id,
        resumen,
        processed_at
    ) VALUES (
        p_id,
        p_conversation_id,
        p_resumen,
        NOW()
    )
    ON CONFLICT (interaction_id) DO UPDATE
    SET processed_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Function to archive old interactions
CREATE OR REPLACE FUNCTION archive_old_interactions(
    p_days_old INTEGER DEFAULT 30
) RETURNS INTEGER AS $$
DECLARE
    archived_count INTEGER;
BEGIN
    INSERT INTO interactions_archive
    SELECT * FROM interactions
    WHERE created_at < NOW() - (p_days_old || ' days')::INTERVAL;
    
    GET DIAGNOSTICS archived_count = ROW_COUNT;
    
    DELETE FROM interactions
    WHERE created_at < NOW() - (p_days_old || ' days')::INTERVAL;
    
    RETURN archived_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- NOTES
-- ============================================
-- 1. Always test queries in SQLTools before using in Cursor Agent
-- 2. Use transactions (BEGIN/COMMIT) for data modification queries
-- 3. Review results before committing changes
-- 4. Keep queries organized in this file for easy reference
-- 5. Add new useful queries as you discover them
-- ============================================

