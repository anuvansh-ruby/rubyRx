-- =====================================================
-- Probabilistic Fuzzy Search Setup for Medicine Database
-- Uses PostgreSQL pg_trgm extension for intelligent similarity matching
-- =====================================================

-- STEP 1: Enable pg_trgm extension
-- This extension provides functions for determining the similarity of text based on trigram matching
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Verify extension is installed
SELECT * FROM pg_extension WHERE extname = 'pg_trgm';

-- =====================================================
-- STEP 2: Create GIN Indexes for Fast Trigram Search
-- =====================================================

-- Index on med_details table
-- Combines brand name + all composition names + strengths for comprehensive search
DROP INDEX IF EXISTS idx_med_details_fuzzy_search;
CREATE INDEX idx_med_details_fuzzy_search
ON med_details USING gin ((
    LOWER(med_brand_name) || ' ' ||
    COALESCE(LOWER(med_composition_name_1), '') || ' ' || COALESCE(med_composition_strength_1, '') || ' ' ||
    COALESCE(LOWER(med_composition_name_2), '') || ' ' || COALESCE(med_composition_strength_2, '') || ' ' ||
    COALESCE(LOWER(med_composition_name_3), '') || ' ' || COALESCE(med_composition_strength_3, '') || ' ' ||
    COALESCE(LOWER(med_composition_name_4), '') || ' ' || COALESCE(med_composition_strength_4, '') || ' ' ||
    COALESCE(LOWER(med_composition_name_5), '') || ' ' || COALESCE(med_composition_strength_5, '')
) gin_trgm_ops);

-- Index on brand name for faster brand-specific searches
DROP INDEX IF EXISTS idx_med_details_brand_trgm;
CREATE INDEX idx_med_details_brand_trgm
ON med_details USING gin (LOWER(med_brand_name) gin_trgm_ops);

-- Index on manufacturer name for manufacturer searches
DROP INDEX IF EXISTS idx_med_details_manufacturer_trgm;
CREATE INDEX idx_med_details_manufacturer_trgm
ON med_details USING gin (LOWER(med_manufacturer_name) gin_trgm_ops);

-- Index on generic_drug table for generic name searches
DROP INDEX IF EXISTS idx_generic_drug_name_trgm;
CREATE INDEX idx_generic_drug_name_trgm
ON generic_drug USING gin (LOWER(generic_drug_name) gin_trgm_ops);

-- Index on unique_drugs table for composition searches
DROP INDEX IF EXISTS idx_unique_drugs_name_trgm;
CREATE INDEX idx_unique_drugs_name_trgm
ON unique_drugs USING gin (LOWER(drug_name) gin_trgm_ops);

-- =====================================================
-- STEP 3: Create Additional Performance Indexes
-- =====================================================

-- Index for active medicines filter (used in every query)
CREATE INDEX IF NOT EXISTS idx_med_details_active_status
ON med_details (is_active, is_deactivated)
WHERE is_active = 1 AND is_deactivated = 0;

-- Index for price range queries
CREATE INDEX IF NOT EXISTS idx_med_details_price
ON med_details (CAST(med_price AS DECIMAL))
WHERE is_active = 1 AND is_deactivated = 0;

-- Index for medicine type filter
CREATE INDEX IF NOT EXISTS idx_med_details_type
ON med_details (med_type)
WHERE is_active = 1 AND is_deactivated = 0;

-- Index for weightage sorting
CREATE INDEX IF NOT EXISTS idx_med_details_weightage
ON med_details (med_weightage DESC NULLS LAST)
WHERE is_active = 1 AND is_deactivated = 0;

-- Composite index for generic_id join optimization
CREATE INDEX IF NOT EXISTS idx_med_details_generic_id
ON med_details (CAST(med_generic_id AS INTEGER))
WHERE is_active = 1;

-- =====================================================
-- STEP 4: Set Default Similarity Threshold (Optional)
-- =====================================================

-- Global setting for similarity threshold (can be overridden per query)
-- Default: 0.3 (30% similarity required)
-- Lower values = more results but less precise
-- Higher values = fewer results but more precise
ALTER DATABASE medicine_db SET pg_trgm.similarity_threshold = 0.3;

-- =====================================================
-- STEP 5: Verify Indexes
-- =====================================================

-- Check all trigram indexes
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE indexdef LIKE '%gin_trgm_ops%'
ORDER BY tablename, indexname;

-- =====================================================
-- STEP 6: Performance Optimization Settings
-- =====================================================

-- Increase shared_buffers for better index caching (adjust based on your server)
-- Uncomment and run if you have DBA access:
-- ALTER SYSTEM SET shared_buffers = '256MB';
-- ALTER SYSTEM SET effective_cache_size = '1GB';
-- ALTER SYSTEM SET maintenance_work_mem = '128MB';

-- After making changes, reload configuration:
-- SELECT pg_reload_conf();

-- =====================================================
-- STEP 7: Test Queries
-- =====================================================

-- Test 1: Simple fuzzy search
SET pg_trgm.similarity_threshold = 0.2;

SELECT 
    med_brand_name,
    similarity(LOWER(med_brand_name), 'paracetamol') AS score
FROM med_details
WHERE LOWER(med_brand_name) % 'paracetamol'
ORDER BY score DESC
LIMIT 5;

-- Test 2: Composition-based search
WITH med_text AS (
    SELECT
        med_id,
        med_brand_name,
        (
            LOWER(med_brand_name) || ' ' ||
            COALESCE(LOWER(med_composition_name_1), '') || ' ' ||
            COALESCE(LOWER(med_composition_name_2), '')
        ) AS full_text
    FROM med_details
    WHERE is_active = 1 AND is_deactivated = 0
)
SELECT
    med_id,
    med_brand_name,
    similarity(full_text, 'paracetamol 500') AS score
FROM med_text
WHERE full_text % 'paracetamol 500'
ORDER BY score DESC
LIMIT 10;

-- Test 3: Multi-word search with word_similarity
SELECT 
    med_brand_name,
    med_composition_name_1,
    word_similarity('diclofenac', LOWER(med_brand_name || ' ' || COALESCE(med_composition_name_1, ''))) AS word_score,
    similarity(LOWER(med_brand_name || ' ' || COALESCE(med_composition_name_1, '')), 'diclofenac paracetamol') AS overall_score
FROM med_details
WHERE (LOWER(med_brand_name) || ' ' || COALESCE(LOWER(med_composition_name_1), '')) % 'diclofenac paracetamol'
ORDER BY overall_score DESC
LIMIT 10;

-- =====================================================
-- MAINTENANCE COMMANDS
-- =====================================================

-- Rebuild indexes if needed (run during low traffic)
-- REINDEX INDEX CONCURRENTLY idx_med_details_fuzzy_search;

-- Update table statistics for better query planning
-- ANALYZE med_details;
-- ANALYZE generic_drug;
-- ANALYZE unique_drugs;

-- Check index usage statistics
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE indexname LIKE '%trgm%'
ORDER BY idx_scan DESC;

-- =====================================================
-- NOTES
-- =====================================================
-- 1. Run ANALYZE after creating indexes for accurate query plans
-- 2. Monitor index usage with pg_stat_user_indexes
-- 3. Adjust similarity_threshold based on your data quality
-- 4. Consider partitioning if med_details table exceeds 1M rows
-- 5. GIN indexes require more disk space but provide faster searches
-- 6. Rebuild indexes periodically in production (monthly recommended)
