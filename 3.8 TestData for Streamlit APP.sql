USE WAREHOUSE SAP_COMPUTE;
USE DATABASE SAP_BDC_HORIZON_CATALOG;
USE SCHEMA AGENTS;





-- =====================================================
-- TEST DATA GENERATION FOR AGENT_AUDIT_LOG
-- 4 Months of Historical Data with Hourly Distribution
-- All test data is marked with 'TEST_AGNT_' prefix
-- Designed for hourly chart visualization
-- =====================================================

-- First, clear any existing test data (optional)
-- DELETE FROM agent_audit_log WHERE audit_id LIKE 'TEST_AGNT_%';

-- =====================================================
-- Month 1 (4 months ago) - Lower confidence, learning phase
-- Business hours: 8am-6pm, with peaks at 10am and 2pm
-- =====================================================
INSERT INTO agent_audit_log (
    audit_id,
    agent_name,
    action_type,
    material_id,
    plant,
    supplier_id,
    order_quantity,
    confidence_score,
    order_date,
    expected_delivery,
    agent_notes,
    execution_status,
    created_at,
    synced_to_sap_at
)
WITH 
days AS (
    SELECT 
        SEQ4() as day_offset,
        DATEADD(day, -day_offset, DATEADD(month, -4, CURRENT_DATE)) as order_date
    FROM TABLE(GENERATOR(ROWCOUNT => 30))  -- 30 days
),
hours AS (
    SELECT 
        SEQ4() as hour_of_day
    FROM TABLE(GENERATOR(ROWCOUNT => 11))  -- 8am to 6pm (11 hours)
    WHERE hour_of_day + 8 BETWEEN 8 AND 18  -- Business hours
),
-- Define hourly distribution weights (more decisions at peak hours)
hourly_weights AS (
    SELECT 
        hour_of_day,
        hour_of_day + 8 as actual_hour,
        CASE 
            WHEN hour_of_day + 8 = 10 THEN 5  -- 10am peak
            WHEN hour_of_day + 8 = 14 THEN 4  -- 2pm peak
            WHEN hour_of_day + 8 IN (9, 11, 13, 15) THEN 3  -- Shoulder hours
            ELSE 2  -- Early morning and late afternoon
        END as decision_weight
    FROM hours
),
-- Generate multiple records per hour based on weight
seq AS (
    SELECT SEQ4() as seq_within_hour
    FROM TABLE(GENERATOR(ROWCOUNT => 5))
),
expanded AS (
    SELECT 
        d.day_offset,
        d.order_date,
        h.actual_hour,
        h.decision_weight,
        s.seq_within_hour
    FROM days d
    CROSS JOIN hourly_weights h
    CROSS JOIN seq s
    WHERE s.seq_within_hour < h.decision_weight
)
SELECT 
    'TEST_AGNT_M1_' || TO_CHAR(order_date, 'YYYYMMDD') || '_' || 
    LPAD(actual_hour::STRING, 2, '0') || '_' || 
    LPAD(seq_within_hour::STRING, 3, '0') as audit_id,
    
    'Inventory Replenishment Agent' as agent_name,
    
    CASE 
        WHEN UNIFORM(1, 10, RANDOM()) <= 7 THEN 'AUTONOMOUS_PO_CREATION'
        WHEN UNIFORM(1, 10, RANDOM()) <= 2 THEN 'MANUAL_REVIEW_REQUIRED'
        ELSE 'ORDER_ADJUSTMENT'
    END as action_type,
    
    CASE 
        WHEN UNIFORM(1, 10, RANDOM()) <= 5 THEN 'TEST_AGNT_MAT001'
        WHEN UNIFORM(1, 10, RANDOM()) <= 3 THEN 'TEST_AGNT_MAT002'
        ELSE 'TEST_AGNT_MAT003'
    END as material_id,
    
    CASE 
        WHEN UNIFORM(1, 10, RANDOM()) <= 7 THEN 'PL01'
        WHEN UNIFORM(1, 10, RANDOM()) <= 2 THEN 'PL02'
        ELSE 'PL03'
    END as plant,
    
    CASE 
        WHEN UNIFORM(1, 10, RANDOM()) <= 4 THEN 'SUP001'
        WHEN UNIFORM(1, 10, RANDOM()) <= 3 THEN 'SUP002'
        WHEN UNIFORM(1, 10, RANDOM()) <= 2 THEN 'SUP003'
        ELSE 'SUP004'
    END as supplier_id,
    
    CASE 
        WHEN material_id = 'TEST_AGNT_MAT001' THEN ABS(RANDOM()) % 1000 + 500
        WHEN material_id = 'TEST_AGNT_MAT002' THEN ABS(RANDOM()) % 400 + 200
        ELSE ABS(RANDOM()) % 150 + 50
    END as order_quantity,
    
    0.50 + (ABS(RANDOM()) % 21 / 100.0) as confidence_score,  -- 0.50 to 0.70
    
    order_date,
    
    DATEADD(day, ABS(RANDOM()) % 7 + 3, order_date) as expected_delivery,
    
    'Early implementation - Building confidence' as agent_notes,
    
    CASE WHEN ABS(RANDOM()) % 10 <= 8 THEN 'EXECUTED' ELSE 'FAILED' END as execution_status,
    
    -- Create timestamp with specific hour
    TIMESTAMP_FROM_PARTS(
        YEAR(order_date),
        MONTH(order_date),
        DAY(order_date),
        actual_hour,
        ABS(RANDOM()) % 60,  -- Random minute
        ABS(RANDOM()) % 60   -- Random second
    ) as created_at,
    
    CASE WHEN execution_status = 'EXECUTED' 
         THEN TIMESTAMPADD(minute, ABS(RANDOM()) % 30 + 5, created_at)
         ELSE NULL 
    END as synced_to_sap_at
    
FROM expanded;

-- =====================================================
-- Month 2 (3 months ago) - Improving confidence
-- More activity, similar hourly pattern
-- =====================================================
INSERT INTO agent_audit_log (
    audit_id,
    agent_name,
    action_type,
    material_id,
    plant,
    supplier_id,
    order_quantity,
    confidence_score,
    order_date,
    expected_delivery,
    agent_notes,
    execution_status,
    created_at,
    synced_to_sap_at
)
WITH 
days AS (
    SELECT 
        SEQ4() as day_offset,
        DATEADD(day, -day_offset, DATEADD(month, -3, CURRENT_DATE)) as order_date
    FROM TABLE(GENERATOR(ROWCOUNT => 30))
),
hours AS (
    SELECT 
        SEQ4() as hour_of_day
    FROM TABLE(GENERATOR(ROWCOUNT => 11))
    WHERE hour_of_day + 8 BETWEEN 8 AND 18
),
hourly_weights AS (
    SELECT 
        hour_of_day,
        hour_of_day + 8 as actual_hour,
        CASE 
            WHEN hour_of_day + 8 = 10 THEN 6  -- Higher peak
            WHEN hour_of_day + 8 = 14 THEN 5
            WHEN hour_of_day + 8 IN (9, 11, 13, 15) THEN 4
            ELSE 3
        END as decision_weight
    FROM hours
),
seq AS (
    SELECT SEQ4() as seq_within_hour
    FROM TABLE(GENERATOR(ROWCOUNT => 6))
),
expanded AS (
    SELECT 
        d.day_offset,
        d.order_date,
        h.actual_hour,
        h.decision_weight,
        s.seq_within_hour
    FROM days d
    CROSS JOIN hourly_weights h
    CROSS JOIN seq s
    WHERE s.seq_within_hour < h.decision_weight
)
SELECT 
    'TEST_AGNT_M2_' || TO_CHAR(order_date, 'YYYYMMDD') || '_' || 
    LPAD(actual_hour::STRING, 2, '0') || '_' || 
    LPAD(seq_within_hour::STRING, 3, '0') as audit_id,
    
    'Inventory Replenishment Agent' as agent_name,
    
    CASE 
        WHEN UNIFORM(1, 10, RANDOM()) <= 8 THEN 'AUTONOMOUS_PO_CREATION'
        ELSE 'MANUAL_REVIEW_REQUIRED'
    END as action_type,
    
    CASE 
        WHEN UNIFORM(1, 10, RANDOM()) <= 5 THEN 'TEST_AGNT_MAT001'
        WHEN UNIFORM(1, 10, RANDOM()) <= 3 THEN 'TEST_AGNT_MAT002'
        WHEN UNIFORM(1, 10, RANDOM()) <= 1 THEN 'TEST_AGNT_MAT003'
        ELSE 'TEST_AGNT_MAT004'
    END as material_id,
    
    CASE 
        WHEN UNIFORM(1, 10, RANDOM()) <= 6 THEN 'PL01'
        WHEN UNIFORM(1, 10, RANDOM()) <= 3 THEN 'PL02'
        ELSE 'PL03'
    END as plant,
    
    CASE 
        WHEN UNIFORM(1, 10, RANDOM()) <= 4 THEN 'SUP001'
        WHEN UNIFORM(1, 10, RANDOM()) <= 3 THEN 'SUP002'
        WHEN UNIFORM(1, 10, RANDOM()) <= 2 THEN 'SUP003'
        ELSE 'SUP004'
    END as supplier_id,
    
    CASE 
        WHEN material_id = 'TEST_AGNT_MAT001' THEN ABS(RANDOM()) % 1200 + 600
        WHEN material_id = 'TEST_AGNT_MAT002' THEN ABS(RANDOM()) % 500 + 250
        WHEN material_id = 'TEST_AGNT_MAT003' THEN ABS(RANDOM()) % 200 + 80
        ELSE ABS(RANDOM()) % 400 + 150
    END as order_quantity,
    
    0.65 + (ABS(RANDOM()) % 21 / 100.0) as confidence_score,  -- 0.65 to 0.85
    
    order_date,
    
    DATEADD(day, ABS(RANDOM()) % 7 + 3, order_date) as expected_delivery,
    
    'Improved confidence with more data' as agent_notes,
    
    CASE WHEN ABS(RANDOM()) % 10 <= 9 THEN 'EXECUTED' ELSE 'FAILED' END as execution_status,
    
    TIMESTAMP_FROM_PARTS(
        YEAR(order_date),
        MONTH(order_date),
        DAY(order_date),
        actual_hour,
        ABS(RANDOM()) % 60,
        ABS(RANDOM()) % 60
    ) as created_at,
    
    CASE WHEN execution_status = 'EXECUTED' 
         THEN TIMESTAMPADD(minute, ABS(RANDOM()) % 30 + 5, created_at)
         ELSE NULL 
    END as synced_to_sap_at
    
FROM expanded;

-- =====================================================
-- Month 3 (2 months ago) - Good confidence
-- =====================================================
INSERT INTO agent_audit_log (
    audit_id,
    agent_name,
    action_type,
    material_id,
    plant,
    supplier_id,
    order_quantity,
    confidence_score,
    order_date,
    expected_delivery,
    agent_notes,
    execution_status,
    created_at,
    synced_to_sap_at
)
WITH 
days AS (
    SELECT 
        SEQ4() as day_offset,
        DATEADD(day, -day_offset, DATEADD(month, -2, CURRENT_DATE)) as order_date
    FROM TABLE(GENERATOR(ROWCOUNT => 30))
),
hours AS (
    SELECT 
        SEQ4() as hour_of_day
    FROM TABLE(GENERATOR(ROWCOUNT => 11))
    WHERE hour_of_day + 8 BETWEEN 8 AND 18
),
hourly_weights AS (
    SELECT 
        hour_of_day,
        hour_of_day + 8 as actual_hour,
        CASE 
            WHEN hour_of_day + 8 = 10 THEN 7
            WHEN hour_of_day + 8 = 14 THEN 6
            WHEN hour_of_day + 8 IN (9, 11, 13, 15) THEN 5
            ELSE 4
        END as decision_weight
    FROM hours
),
seq AS (
    SELECT SEQ4() as seq_within_hour
    FROM TABLE(GENERATOR(ROWCOUNT => 7))
),
expanded AS (
    SELECT 
        d.day_offset,
        d.order_date,
        h.actual_hour,
        h.decision_weight,
        s.seq_within_hour
    FROM days d
    CROSS JOIN hourly_weights h
    CROSS JOIN seq s
    WHERE s.seq_within_hour < h.decision_weight
)
SELECT 
    'TEST_AGNT_M3_' || TO_CHAR(order_date, 'YYYYMMDD') || '_' || 
    LPAD(actual_hour::STRING, 2, '0') || '_' || 
    LPAD(seq_within_hour::STRING, 3, '0') as audit_id,
    
    'Inventory Replenishment Agent' as agent_name,
    
    CASE 
        WHEN UNIFORM(1, 10, RANDOM()) <= 9 THEN 'AUTONOMOUS_PO_CREATION'
        ELSE 'ORDER_ADJUSTMENT'
    END as action_type,
    
    CASE 
        WHEN UNIFORM(1, 10, RANDOM()) <= 4 THEN 'TEST_AGNT_MAT001'
        WHEN UNIFORM(1, 10, RANDOM()) <= 3 THEN 'TEST_AGNT_MAT002'
        WHEN UNIFORM(1, 10, RANDOM()) <= 2 THEN 'TEST_AGNT_MAT003'
        ELSE 'TEST_AGNT_MAT004'
    END as material_id,
    
    CASE 
        WHEN UNIFORM(1, 10, RANDOM()) <= 5 THEN 'PL01'
        WHEN UNIFORM(1, 10, RANDOM()) <= 3 THEN 'PL02'
        WHEN UNIFORM(1, 10, RANDOM()) <= 1 THEN 'PL03'
        ELSE 'PL04'
    END as plant,
    
    CASE 
        WHEN UNIFORM(1, 10, RANDOM()) <= 4 THEN 'SUP001'
        WHEN UNIFORM(1, 10, RANDOM()) <= 3 THEN 'SUP002'
        WHEN UNIFORM(1, 10, RANDOM()) <= 2 THEN 'SUP003'
        ELSE 'SUP004'
    END as supplier_id,
    
    CASE 
        WHEN material_id = 'TEST_AGNT_MAT001' THEN ABS(RANDOM()) % 1500 + 800
        WHEN material_id = 'TEST_AGNT_MAT002' THEN ABS(RANDOM()) % 600 + 300
        WHEN material_id = 'TEST_AGNT_MAT003' THEN ABS(RANDOM()) % 250 + 100
        ELSE ABS(RANDOM()) % 500 + 200
    END as order_quantity,
    
    0.75 + (ABS(RANDOM()) % 21 / 100.0) as confidence_score,  -- 0.75 to 0.95
    
    order_date,
    
    DATEADD(day, ABS(RANDOM()) % 7 + 2, order_date) as expected_delivery,
    
    'Mature model - Good confidence' as agent_notes,
    
    CASE WHEN ABS(RANDOM()) % 10 <= 9 THEN 'EXECUTED' ELSE 'FAILED' END as execution_status,
    
    TIMESTAMP_FROM_PARTS(
        YEAR(order_date),
        MONTH(order_date),
        DAY(order_date),
        actual_hour,
        ABS(RANDOM()) % 60,
        ABS(RANDOM()) % 60
    ) as created_at,
    
    CASE WHEN execution_status = 'EXECUTED' 
         THEN TIMESTAMPADD(minute, ABS(RANDOM()) % 25 + 5, created_at)
         ELSE NULL 
    END as synced_to_sap_at
    
FROM expanded;

-- =====================================================
-- Month 4 (last month) - High confidence
-- Including some weekend activity
-- =====================================================
INSERT INTO agent_audit_log (
    audit_id,
    agent_name,
    action_type,
    material_id,
    plant,
    supplier_id,
    order_quantity,
    confidence_score,
    order_date,
    expected_delivery,
    agent_notes,
    execution_status,
    created_at,
    synced_to_sap_at
)
WITH 
days AS (
    SELECT 
        SEQ4() as day_offset,
        DATEADD(day, -day_offset, DATEADD(month, -1, CURRENT_DATE)) as order_date
    FROM TABLE(GENERATOR(ROWCOUNT => 30))
),
hours AS (
    SELECT 
        SEQ4() as hour_of_day
    FROM TABLE(GENERATOR(ROWCOUNT => 11))
    WHERE hour_of_day + 8 BETWEEN 8 AND 18
),
hourly_weights AS (
    SELECT 
        hour_of_day,
        hour_of_day + 8 as actual_hour,
        -- Adjust for weekends (less activity)
        CASE 
            WHEN DAYOFWEEK(order_date) IN (0, 6) THEN  -- Weekend
                CASE 
                    WHEN hour_of_day + 8 = 10 THEN 3
                    WHEN hour_of_day + 8 = 14 THEN 2
                    ELSE 1
                END
            ELSE  -- Weekday
                CASE 
                    WHEN hour_of_day + 8 = 10 THEN 8
                    WHEN hour_of_day + 8 = 14 THEN 7
                    WHEN hour_of_day + 8 IN (9, 11, 13, 15) THEN 6
                    ELSE 5
                END
        END as decision_weight
    FROM hours, days
),
seq AS (
    SELECT SEQ4() as seq_within_hour
    FROM TABLE(GENERATOR(ROWCOUNT => 8))
),
expanded AS (
    SELECT 
        d.day_offset,
        d.order_date,
        h.actual_hour,
        h.decision_weight,
        s.seq_within_hour
    FROM days d
    CROSS JOIN hourly_weights h
    CROSS JOIN seq s
    WHERE s.seq_within_hour < GREATEST(h.decision_weight, 1)
)
SELECT 
    'TEST_AGNT_M4_' || TO_CHAR(order_date, 'YYYYMMDD') || '_' || 
    LPAD(actual_hour::STRING, 2, '0') || '_' || 
    LPAD(seq_within_hour::STRING, 3, '0') as audit_id,
    
    'Inventory Replenishment Agent' as agent_name,
    
    CASE 
        WHEN UNIFORM(1, 10, RANDOM()) <= 9 THEN 'AUTONOMOUS_PO_CREATION'
        ELSE 'ORDER_ADJUSTMENT'
    END as action_type,
    
    CASE 
        WHEN UNIFORM(1, 10, RANDOM()) <= 4 THEN 'TEST_AGNT_MAT001'
        WHEN UNIFORM(1, 10, RANDOM()) <= 3 THEN 'TEST_AGNT_MAT002'
        WHEN UNIFORM(1, 10, RANDOM()) <= 2 THEN 'TEST_AGNT_MAT003'
        ELSE 'TEST_AGNT_MAT004'
    END as material_id,
    
    CASE 
        WHEN UNIFORM(1, 10, RANDOM()) <= 5 THEN 'PL01'
        WHEN UNIFORM(1, 10, RANDOM()) <= 3 THEN 'PL02'
        WHEN UNIFORM(1, 10, RANDOM()) <= 1 THEN 'PL03'
        ELSE 'PL04'
    END as plant,
    
    CASE 
        WHEN UNIFORM(1, 10, RANDOM()) <= 4 THEN 'SUP001'
        WHEN UNIFORM(1, 10, RANDOM()) <= 3 THEN 'SUP002'
        WHEN UNIFORM(1, 10, RANDOM()) <= 2 THEN 'SUP003'
        ELSE 'SUP004'
    END as supplier_id,
    
    CASE 
        WHEN material_id = 'TEST_AGNT_MAT001' THEN ABS(RANDOM()) % 2000 + 1000
        WHEN material_id = 'TEST_AGNT_MAT002' THEN ABS(RANDOM()) % 800 + 400
        WHEN material_id = 'TEST_AGNT_MAT003' THEN ABS(RANDOM()) % 300 + 150
        ELSE ABS(RANDOM()) % 600 + 250
    END as order_quantity,
    
    0.85 + (ABS(RANDOM()) % 16 / 100.0) as confidence_score,  -- 0.85 to 1.0
    
    order_date,
    
    DATEADD(day, ABS(RANDOM()) % 6 + 2, order_date) as expected_delivery,
    
    'Mature model - High confidence' as agent_notes,
    
    CASE WHEN ABS(RANDOM()) % 10 <= 9 THEN 'EXECUTED' ELSE 'FAILED' END as execution_status,
    
    TIMESTAMP_FROM_PARTS(
        YEAR(order_date),
        MONTH(order_date),
        DAY(order_date),
        actual_hour,
        ABS(RANDOM()) % 60,
        ABS(RANDOM()) % 60
    ) as created_at,
    
    CASE WHEN execution_status = 'EXECUTED' 
         THEN TIMESTAMPADD(minute, ABS(RANDOM()) % 20 + 5, created_at)
         ELSE NULL 
    END as synced_to_sap_at
    
FROM expanded
WHERE decision_weight > 0;  -- Only include hours with activity

-- =====================================================
-- ADD SOME SPECIFIC SCENARIOS FOR TESTING
-- =====================================================

-- Add some critical items with low confidence (for testing alerts)
INSERT INTO agent_audit_log (
    audit_id, agent_name, action_type, material_id, plant, supplier_id,
    order_quantity, confidence_score, order_date, expected_delivery,
    agent_notes, execution_status, created_at, synced_to_sap_at
)
-- Low confidence scenarios - at different hours
SELECT 'TEST_AGNT_CRIT_001', 'Inventory Replenishment Agent', 'MANUAL_REVIEW_REQUIRED',
 'TEST_AGNT_CRIT', 'PL01', 'SUP005', 1500, 0.45,
 DATEADD(day, -5, CURRENT_DATE), DATEADD(day, 10, CURRENT_DATE),
 'Low confidence - New supplier, limited history', 'PENDING_REVIEW',
 DATEADD(hour, 10, DATEADD(minute, 15, DATEADD(day, -5, CURRENT_DATE)::DATE::TIMESTAMP)), NULL
UNION ALL
SELECT 'TEST_AGNT_CRIT_002', 'Inventory Replenishment Agent', 'MANUAL_REVIEW_REQUIRED',
 'TEST_AGNT_CRIT', 'PL02', 'SUP006', 800, 0.38,
 DATEADD(day, -3, CURRENT_DATE), DATEADD(day, 12, CURRENT_DATE),
 'Very low confidence - Inconsistent delivery history', 'PENDING_REVIEW',
 DATEADD(hour, 14, DATEADD(minute, 30, DATEADD(day, -3, CURRENT_DATE)::DATE::TIMESTAMP)), NULL
UNION ALL
-- High confidence successful orders at peak hours
SELECT 'TEST_AGNT_HIGH_001', 'Inventory Replenishment Agent', 'AUTONOMOUS_PO_CREATION',
 'TEST_AGNT_MAT001', 'PL01', 'SUP001', 2000, 0.97,
 DATEADD(day, -2, CURRENT_DATE), DATEADD(day, 5, CURRENT_DATE),
 'High confidence - Regular reorder', 'EXECUTED',
 DATEADD(hour, 10, DATEADD(day, -2, CURRENT_DATE)::DATE::TIMESTAMP),
 DATEADD(minute, 15, DATEADD(hour, 10, DATEADD(day, -2, CURRENT_DATE)::DATE::TIMESTAMP))
UNION ALL
SELECT 'TEST_AGNT_HIGH_002', 'Inventory Replenishment Agent', 'AUTONOMOUS_PO_CREATION',
 'TEST_AGNT_MAT001', 'PL01', 'SUP001', 1800, 0.96,
 DATEADD(day, -1, CURRENT_DATE), DATEADD(day, 4, CURRENT_DATE),
 'High confidence - Regular reorder', 'EXECUTED',
 DATEADD(hour, 14, DATEADD(day, -1, CURRENT_DATE)::DATE::TIMESTAMP),
 DATEADD(minute, 10, DATEADD(hour, 14, DATEADD(day, -1, CURRENT_DATE)::DATE::TIMESTAMP))
UNION ALL
-- Failed executions at various hours
SELECT 'TEST_AGNT_FAIL_001', 'Inventory Replenishment Agent', 'AUTONOMOUS_PO_CREATION',
 'TEST_AGNT_MAT002', 'PL01', 'SUP002', 500, 0.82,
 DATEADD(day, -4, CURRENT_DATE), DATEADD(day, 8, CURRENT_DATE),
 'SAP connection timeout', 'FAILED',
 DATEADD(hour, 11, DATEADD(minute, 45, DATEADD(day, -4, CURRENT_DATE)::DATE::TIMESTAMP)), NULL
UNION ALL
SELECT 'TEST_AGNT_FAIL_002', 'Inventory Replenishment Agent', 'AUTONOMOUS_PO_CREATION',
 'TEST_AGNT_MAT003', 'PL03', 'SUP003', 150, 0.75,
 DATEADD(day, -6, CURRENT_DATE), DATEADD(day, 15, CURRENT_DATE),
 'Invalid supplier ID in SAP', 'FAILED',
 DATEADD(hour, 9, DATEADD(minute, 30, DATEADD(day, -6, CURRENT_DATE)::DATE::TIMESTAMP)), NULL
UNION ALL
-- Weekend activity (limited)
SELECT 'TEST_AGNT_WEEKEND_001', 'Inventory Replenishment Agent', 'AUTONOMOUS_PO_CREATION',
 'TEST_AGNT_MAT001', 'PL01', 'SUP001', 1200, 0.92,
 DATEADD(day, -7, CURRENT_DATE), DATEADD(day, 3, CURRENT_DATE),
 'Weekend automated check', 'EXECUTED',
 DATEADD(hour, 10, DATEADD(day, -7, CURRENT_DATE)::DATE::TIMESTAMP),
 DATEADD(minute, 20, DATEADD(hour, 10, DATEADD(day, -7, CURRENT_DATE)::DATE::TIMESTAMP));

-- =====================================================
-- ADDITIONAL TEST DATA FOR LAST 24 HOURS
-- To ensure enough data for queries with created_at >= DATEADD(day, -1, CURRENT_DATE)
-- Includes high-resolution hourly data for the past day
-- =====================================================

-- Last 24 hours - Detailed hourly data (multiple records per hour)
INSERT INTO agent_audit_log (
    audit_id,
    agent_name,
    action_type,
    material_id,
    plant,
    supplier_id,
    order_quantity,
    confidence_score,
    order_date,
    expected_delivery,
    agent_notes,
    execution_status,
    created_at,
    synced_to_sap_at
)
WITH 
hours_last_24 AS (
    SELECT 
        SEQ4() as hour_offset,
        DATEADD(hour, -hour_offset, CURRENT_TIMESTAMP()) as exact_timestamp,
        DATEADD(hour, -hour_offset, CURRENT_DATE) as order_date,
        EXTRACT(HOUR FROM DATEADD(hour, -hour_offset, CURRENT_TIMESTAMP())) as hour_of_day
    FROM TABLE(GENERATOR(ROWCOUNT => 24))  -- 24 hours
),
-- Define how many records per hour (more during peak hours)
hourly_volume AS (
    SELECT 
        hour_offset,
        exact_timestamp,
        order_date,
        hour_of_day,
        CASE 
            WHEN hour_of_day BETWEEN 8 AND 10 THEN 8  -- Morning peak
            WHEN hour_of_day BETWEEN 11 AND 14 THEN 10 -- Lunch/afternoon peak
            WHEN hour_of_day BETWEEN 15 AND 17 THEN 7  -- Afternoon
            WHEN hour_of_day BETWEEN 18 AND 20 THEN 4  -- Evening
            ELSE 2  -- Night/early morning
        END as records_per_hour
    FROM hours_last_24
),
-- Expand to individual records
seq AS (
    SELECT SEQ4() as seq_within_hour
    FROM TABLE(GENERATOR(ROWCOUNT => 10))
),
expanded AS (
    SELECT 
        h.hour_offset,
        h.exact_timestamp,
        h.order_date,
        h.hour_of_day,
        h.records_per_hour,
        s.seq_within_hour
    FROM hourly_volume h
    CROSS JOIN seq s
    WHERE s.seq_within_hour < h.records_per_hour
)
SELECT 
    'TEST_AGNT_24H_' || 
    TO_CHAR(exact_timestamp, 'YYYYMMDDHH24MI') || '_' || 
    LPAD(seq_within_hour::STRING, 2, '0') as audit_id,
    
    'Inventory Replenishment Agent' as agent_name,
    
    CASE 
        WHEN UNIFORM(1, 10, RANDOM()) <= 8 THEN 'AUTONOMOUS_PO_CREATION'
        WHEN UNIFORM(1, 10, RANDOM()) <= 1 THEN 'MANUAL_REVIEW_REQUIRED'
        ELSE 'ORDER_ADJUSTMENT'
    END as action_type,
    
    CASE 
        WHEN UNIFORM(1, 10, RANDOM()) <= 4 THEN 'TEST_AGNT_MAT001'
        WHEN UNIFORM(1, 10, RANDOM()) <= 3 THEN 'TEST_AGNT_MAT002'
        WHEN UNIFORM(1, 10, RANDOM()) <= 2 THEN 'TEST_AGNT_MAT003'
        ELSE 'TEST_AGNT_MAT004'
    END as material_id,
    
    CASE 
        WHEN UNIFORM(1, 10, RANDOM()) <= 5 THEN 'PL01'
        WHEN UNIFORM(1, 10, RANDOM()) <= 3 THEN 'PL02'
        WHEN UNIFORM(1, 10, RANDOM()) <= 1 THEN 'PL03'
        ELSE 'PL04'
    END as plant,
    
    CASE 
        WHEN UNIFORM(1, 10, RANDOM()) <= 4 THEN 'SUP001'
        WHEN UNIFORM(1, 10, RANDOM()) <= 3 THEN 'SUP002'
        WHEN UNIFORM(1, 10, RANDOM()) <= 2 THEN 'SUP003'
        ELSE 'SUP004'
    END as supplier_id,
    
    CASE 
        WHEN material_id = 'TEST_AGNT_MAT001' THEN ABS(RANDOM()) % 2000 + 1000
        WHEN material_id = 'TEST_AGNT_MAT002' THEN ABS(RANDOM()) % 800 + 400
        WHEN material_id = 'TEST_AGNT_MAT003' THEN ABS(RANDOM()) % 300 + 150
        ELSE ABS(RANDOM()) % 600 + 250
    END as order_quantity,
    
    -- High confidence for recent data
    0.88 + (ABS(RANDOM()) % 12 / 100.0) as confidence_score,  -- 0.88 to 1.0
    
    DATE(order_date) as order_date,
    
    DATEADD(day, ABS(RANDOM()) % 5 + 2, order_date) as expected_delivery,
    
    CASE 
        WHEN action_type = 'AUTONOMOUS_PO_CREATION' THEN 'Auto-created - Recent high confidence'
        WHEN action_type = 'MANUAL_REVIEW_REQUIRED' THEN 'Manual review needed - Edge case'
        ELSE 'Order adjustment based on real-time demand'
    END as agent_notes,
    
    CASE WHEN ABS(RANDOM()) % 10 <= 9 THEN 'EXECUTED' ELSE 'FAILED' END as execution_status,
    
    -- Spread timestamps throughout the hour
    TIMESTAMPADD(minute, ABS(RANDOM()) % 60, 
                 TIMESTAMPADD(second, ABS(RANDOM()) % 60, 
                             DATE_TRUNC('hour', exact_timestamp))) as created_at,
    
    CASE WHEN execution_status = 'EXECUTED' 
         THEN TIMESTAMPADD(minute, ABS(RANDOM()) % 15 + 2, created_at)
         ELSE NULL 
    END as synced_to_sap_at
    
FROM expanded
ORDER BY exact_timestamp DESC;

-- =====================================================
-- ADD SPECIFIC TEST SCENARIOS FOR THE LAST HOUR
-- To ensure real-time data shows in the last hour
-- =====================================================

INSERT INTO agent_audit_log (
    audit_id, agent_name, action_type, material_id, plant, supplier_id,
    order_quantity, confidence_score, order_date, expected_delivery,
    agent_notes, execution_status, created_at, synced_to_sap_at
)
SELECT 
    'TEST_AGNT_NOW_' || LPAD(seq::STRING, 3, '0') as audit_id,
    'Inventory Replenishment Agent' as agent_name,
    CASE 
        WHEN seq <= 3 THEN 'AUTONOMOUS_PO_CREATION'
        WHEN seq <= 5 THEN 'MANUAL_REVIEW_REQUIRED'
        ELSE 'ORDER_ADJUSTMENT'
    END as action_type,
    CASE 
        WHEN seq <= 2 THEN 'TEST_AGNT_MAT001'
        WHEN seq <= 4 THEN 'TEST_AGNT_MAT002'
        WHEN seq <= 6 THEN 'TEST_AGNT_MAT003'
        ELSE 'TEST_AGNT_MAT004'
    END as material_id,
    CASE 
        WHEN seq <= 3 THEN 'PL01'
        WHEN seq <= 6 THEN 'PL02'
        ELSE 'PL03'
    END as plant,
    CASE 
        WHEN seq <= 2 THEN 'SUP001'
        WHEN seq <= 4 THEN 'SUP002'
        WHEN seq <= 6 THEN 'SUP003'
        ELSE 'SUP004'
    END as supplier_id,
    CASE 
        WHEN material_id = 'TEST_AGNT_MAT001' THEN 1850
        WHEN material_id = 'TEST_AGNT_MAT002' THEN 750
        WHEN material_id = 'TEST_AGNT_MAT003' THEN 280
        ELSE 450
    END as order_quantity,
    0.92 + (seq * 0.005) as confidence_score,  -- Increasing confidence
    CURRENT_DATE as order_date,
    DATEADD(day, 5, CURRENT_DATE) as expected_delivery,
    'Real-time test data - Last hour' as agent_notes,
    CASE WHEN seq <= 7 THEN 'EXECUTED' ELSE 'PENDING' END as execution_status,
    -- Spread across the last 60 minutes
    TIMESTAMPADD(minute, -seq, CURRENT_TIMESTAMP()) as created_at,
    CASE WHEN execution_status = 'EXECUTED' 
         THEN TIMESTAMPADD(minute, 2, created_at)
         ELSE NULL 
    END as synced_to_sap_at
FROM (SELECT SEQ4() as seq FROM TABLE(GENERATOR(ROWCOUNT => 10)))
ORDER BY seq;

-- =====================================================
-- ADD PEAK HOUR ACTIVITY (last 3 hours at 10am-1pm if current time matches)
-- Ensures the last few hours have sufficient data density
-- =====================================================

INSERT INTO agent_audit_log (
    audit_id,
    agent_name,
    action_type,
    material_id,
    plant,
    supplier_id,
    order_quantity,
    confidence_score,
    order_date,
    expected_delivery,
    agent_notes,
    execution_status,
    created_at,
    synced_to_sap_at
)
WITH 
recent_hours AS (
    SELECT 
        SEQ4() as hour_offset,
        DATEADD(hour, -hour_offset, CURRENT_TIMESTAMP()) as ts,
        EXTRACT(HOUR FROM DATEADD(hour, -hour_offset, CURRENT_TIMESTAMP())) as hr
    FROM TABLE(GENERATOR(ROWCOUNT => 6))  -- Last 6 hours
    WHERE hour_offset < 3  -- Focus on last 3 hours for density
),
volume_per_hour AS (
    SELECT 
        ts,
        hr,
        CASE 
            WHEN hr BETWEEN 9 AND 11 THEN 12  -- Morning peak
            WHEN hr BETWEEN 13 AND 15 THEN 10  -- Afternoon peak
            ELSE 6
        END as records_per_hour
    FROM recent_hours
),
seq AS (
    SELECT SEQ4() as seq
    FROM TABLE(GENERATOR(ROWCOUNT => 12))
),
expanded AS (
    SELECT 
        v.ts,
        v.hr,
        v.records_per_hour,
        s.seq
    FROM volume_per_hour v
    CROSS JOIN seq s
    WHERE s.seq < v.records_per_hour
)
SELECT 
    'TEST_AGNT_PEAK_' || TO_CHAR(ts, 'HH24MI') || '_' || LPAD(seq::STRING, 2, '0') as audit_id,
    'Inventory Replenishment Agent' as agent_name,
    CASE WHEN seq % 3 = 0 THEN 'MANUAL_REVIEW_REQUIRED' ELSE 'AUTONOMOUS_PO_CREATION' END as action_type,
    CASE 
        WHEN seq <= 3 THEN 'TEST_AGNT_MAT001'
        WHEN seq <= 6 THEN 'TEST_AGNT_MAT002'
        WHEN seq <= 9 THEN 'TEST_AGNT_MAT003'
        ELSE 'TEST_AGNT_MAT004'
    END as material_id,
    CASE 
        WHEN seq % 2 = 0 THEN 'PL01'
        ELSE 'PL02'
    END as plant,
    CASE 
        WHEN seq <= 4 THEN 'SUP001'
        WHEN seq <= 8 THEN 'SUP002'
        ELSE 'SUP003'
    END as supplier_id,
    CASE 
        WHEN material_id = 'TEST_AGNT_MAT001' THEN 1900 + seq * 10
        WHEN material_id = 'TEST_AGNT_MAT002' THEN 800 + seq * 5
        WHEN material_id = 'TEST_AGNT_MAT003' THEN 300 + seq * 2
        ELSE 500 + seq * 3
    END as order_quantity,
    0.94 - (seq * 0.002) as confidence_score,
    DATE(ts) as order_date,
    DATEADD(day, 4, DATE(ts)) as expected_delivery,
    'Peak hour activity - High volume' as agent_notes,
    'EXECUTED' as execution_status,
    TIMESTAMPADD(minute, seq * 2, ts) as created_at,
    TIMESTAMPADD(minute, seq * 2 + 5, ts) as synced_to_sap_at
FROM expanded;

-- =====================================================
-- VERIFICATION QUERY FOR LAST 24 HOURS
-- =====================================================

-- Check data for the last 24 hours
SELECT 
    'Last 24 Hours Data' as period,
    COUNT(*) as total_records,
    COUNT(DISTINCT material_id) as unique_materials,
    COUNT(DISTINCT supplier_id) as unique_suppliers,
    ROUND(AVG(confidence_score), 3) as avg_confidence,
    SUM(order_quantity) as total_ordered,
    MIN(created_at) as earliest,
    MAX(created_at) as latest
FROM agent_audit_log 
WHERE created_at >= DATEADD(day, -1, CURRENT_DATE)
  AND audit_id LIKE 'TEST_AGNT_%';

-- Hourly breakdown for the last 24 hours (for charting)
SELECT 
    EXTRACT(HOUR FROM created_at) as hour_of_day,
    COUNT(*) as decisions,
    ROUND(AVG(confidence_score), 3) as avg_confidence,
    SUM(order_quantity) as total_ordered,
    COUNT(DISTINCT material_id) as materials_ordered
FROM agent_audit_log 
WHERE created_at >= DATEADD(day, -1, CURRENT_DATE)
  AND audit_id LIKE 'TEST_AGNT_%'
GROUP BY EXTRACT(HOUR FROM created_at)
ORDER BY hour_of_day;

-- Minute-by-minute for the last hour (dense chart data)
SELECT 
    DATE_TRUNC('minute', created_at) as minute_slot,
    COUNT(*) as decisions,
    ROUND(AVG(confidence_score), 3) as avg_confidence
FROM agent_audit_log 
WHERE created_at >= DATEADD(hour, -1, CURRENT_TIMESTAMP())
  AND audit_id LIKE 'TEST_AGNT_%'
GROUP BY DATE_TRUNC('minute', created_at)
ORDER BY minute_slot;

-- =====================================================
-- TEST THE SPECIFIC WHERE CLAUSE QUERY
-- =====================================================

/*
-- This is the query you need data for
SELECT 
    COUNT(DISTINCT material_id) as critical_items,
    AVG(confidence_score) as avg_confidence,
    SUM(order_quantity) as total_ordered,
    COUNT(*) as total_decisions
FROM agent_audit_log 
WHERE created_at >= DATEADD(day, -1, CURRENT_DATE)
  AND audit_id LIKE 'TEST_AGNT_%';

-- Expected results based on the test data:
-- critical_items: ~8-10 distinct materials
-- avg_confidence: ~0.91-0.94
-- total_ordered: ~25,000-35,000
-- total_decisions: ~120-150
*/

-- =====================================================
-- VERIFICATION QUERIES FOR HOURLY ANALYSIS
-- =====================================================

-- Hourly distribution across all test data
SELECT 
    EXTRACT(HOUR FROM created_at) as hour_of_day,
    COUNT(*) as decision_count,
    ROUND(AVG(confidence_score), 3) as avg_confidence,
    SUM(order_quantity) as total_ordered,
    COUNT(DISTINCT material_id) as unique_materials
FROM agent_audit_log 
WHERE audit_id LIKE 'TEST_AGNT_%'
GROUP BY EXTRACT(HOUR FROM created_at)
ORDER BY hour_of_day;

-- Daily trend with hourly breakdown (last 7 days)
SELECT 
    DATE(created_at) as decision_date,
    EXTRACT(HOUR FROM created_at) as hour_of_day,
    COUNT(*) as decisions,
    ROUND(AVG(confidence_score), 3) as avg_confidence
FROM agent_audit_log 
WHERE audit_id LIKE 'TEST_AGNT_%'
  AND created_at >= DATEADD(day, -7, CURRENT_DATE)
GROUP BY DATE(created_at), EXTRACT(HOUR FROM created_at)
ORDER BY decision_date, hour_of_day;

-- Weekly pattern by hour
SELECT 
    DAYOFWEEK(created_at) as day_of_week,
    EXTRACT(HOUR FROM created_at) as hour_of_day,
    COUNT(*) as decisions,
    ROUND(AVG(confidence_score), 3) as avg_confidence
FROM agent_audit_log 
WHERE audit_id LIKE 'TEST_AGNT_%'
GROUP BY DAYOFWEEK(created_at), EXTRACT(HOUR FROM created_at)
ORDER BY day_of_week, hour_of_day;

-- Overall statistics
SELECT 
    'Overall Test Data' as description,
    COUNT(*) as total_records,
    MIN(created_at) as earliest_record,
    MAX(created_at) as latest_record,
    COUNT(DISTINCT EXTRACT(HOUR FROM created_at)) as hours_with_activity,
    ROUND(AVG(confidence_score), 3) as avg_confidence,
    SUM(order_quantity) as total_order_quantity
FROM agent_audit_log 
WHERE audit_id LIKE 'TEST_AGNT_%';

-- =====================================================
-- TEST THE METRIC QUERY (4 month history)
-- =====================================================

/*
-- This is the exact query from your view
SELECT 
    COUNT(DISTINCT material_id) as critical_items,
    AVG(confidence_score) as avg_confidence,
    SUM(order_quantity) as total_ordered,
    COUNT(*) as total_decisions
FROM agent_audit_log 
WHERE created_at >= CURRENT_DATE - INTERVAL '4 months'
  AND audit_id LIKE 'TEST_AGNT_%';

-- Hourly breakdown for the last 30 days (for charting)
SELECT 
    EXTRACT(HOUR FROM created_at) as hour_of_day,
    COUNT(*) as decisions,
    AVG(confidence_score) as avg_confidence,
    SUM(order_quantity) as total_ordered
FROM agent_audit_log 
WHERE created_at >= DATEADD(month, -1, CURRENT_DATE)
  AND audit_id LIKE 'TEST_AGNT_%'
GROUP BY EXTRACT(HOUR FROM created_at)
ORDER BY hour_of_day;

-- Daily trend with confidence (for line charts)
SELECT 
    DATE(created_at) as decision_date,
    COUNT(*) as total_decisions,
    AVG(confidence_score) as avg_confidence,
    SUM(order_quantity) as total_ordered
FROM agent_audit_log 
WHERE created_at >= DATEADD(month, -4, CURRENT_DATE)
  AND audit_id LIKE 'TEST_AGNT_%'
GROUP BY DATE(created_at)
ORDER BY decision_date;
*/

-- =====================================================
-- DELETE STATEMENT FOR TEST DATA
-- Run this to clean up all test data
-- =====================================================

/*
-- Delete all test data
DELETE FROM agent_audit_log 
WHERE audit_id LIKE 'TEST_AGNT_%';

-- Verify deletion
SELECT COUNT(*) as remaining_test_records
FROM agent_audit_log 
WHERE audit_id LIKE 'TEST_AGNT_%';
*/

/*
 --streamlit application test sql for the dashboard
 --Get metrics
 SELECT 
        COUNT(DISTINCT material_id) as critical_items,
        AVG(confidence_score) as avg_confidence,
        SUM(order_quantity) as total_ordered,
        COUNT(*) as total_decisions
    FROM agent_audit_log 
    WHERE created_at >= CURRENT_DATE;

-- Recent Agent Decisions
--table 
SELECT 
        created_at,
        material_id,
        plant,
        action_type,
        order_quantity,
        confidence_score,
        agent_notes
    FROM agent_audit_log
    ORDER BY created_at DESC
    LIMIT 100;
        
--Agent Performance Over Time
SELECT 
        DATE_TRUNC('HOUR', created_at) as hour,
        COUNT(*) as decisions,
        AVG(confidence_score) as confidence
    FROM agent_audit_log
    WHERE created_at >= DATEADD(day, -1, CURRENT_DATE)
    GROUP BY 1
    ORDER BY 1;


--Items Requiring Attention
 SELECT * FROM TABLE(analyze_inventory_status())
    WHERE stock_status IN ('CRITICAL', 'REORDER')
    ORDER BY 
        CASE stock_status WHEN 'CRITICAL' THEN 1 WHEN 'REORDER' THEN 2 ELSE 3 END,
        current_stock
    LIMIT 50;

--#Inventory Status Overview
SELECT 
        stock_status,
        COUNT(*) as item_count,
        AVG(confidence_score) as avg_confidence
    FROM TABLE(analyze_inventory_status())
    GROUP BY stock_status
    ORDER BY 
        CASE stock_status 
            WHEN 'CRITICAL' THEN 1 
            WHEN 'REORDER' THEN 2 
            WHEN 'WATCH' THEN 3 
            ELSE 4 
        END;

--m st.subheader("Agent Performance Over Time")
    SELECT 
        DATE_TRUNC('HOUR', created_at) as hour,
        COUNT(*) as decisions,
        AVG(confidence_score) as confidence
    FROM AGENTS.agent_audit_log
    WHERE created_at >= DATEADD(day, -1, CURRENT_DATE)
    GROUP BY 1
    ORDER BY 1;
--Items Requiring Attention
SELECT * FROM analyze_inventory_status()
    WHERE stock_status IN ('CRITICAL', 'REORDER')
    ORDER BY 
        CASE stock_status WHEN 'CRITICAL' THEN 1 WHEN 'REORDER' THEN 2 ELSE 3 END,
        current_stock
    LIMIT 50;

*/