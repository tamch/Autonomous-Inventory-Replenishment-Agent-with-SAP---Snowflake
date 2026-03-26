USE WAREHOUSE SAP_COMPUTE;
USE DATABASE SAP_BDC_HORIZON_CATALOG;
USE SCHEMA AGENTS;

-- predict_demand
/*
Test Data Summary for Demand Prediction:
Material ID	    Data Volume	        Pattern	Expected                Procedure Behavior
TEST_FCAST_001	2 years daily	    Strong seasonality + trend	    RandomForest with good confidence
TEST_FCAST_002	2 years weekly	    Q4 seasonal peak	            RandomForest with weekly pattern
TEST_FCAST_003	90 days daily	    Stable with noise	            Moving average fallback (< 30 rows?)
TEST_FCAST_004	14 days daily	    Recent only	                    Last value fallback
TEST_FCAST_005	No data	            None	                        Empty data → all zeros
TEST_FCAST_006	~2 years sporadic	20% demand spikes	            RandomForest with high variance
TEST_FCAST_007	~1.6 years	        Zero demand in certain months	Handles zeros in training
TEST_FCAST_008	~1.4 years	        High volatility (±80%)	        Low confidence, wide bounds
*/

-- =====================================================
-- TEST DATA GENERATION FOR PREDICT_DEMAND STORED PROCEDURE
-- All test data is marked with 'TEST_FCAST_' prefix
-- Designed to test different prediction scenarios
-- =====================================================

-- First, clean up any existing test data (optional - comment if first run)
-- DELETE FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 
-- WHERE MATNR LIKE 'TEST_FCAST_%';

-- =====================================================
-- TEST_FCAST_001: SUFFICIENT DATA - 2 years of daily demand
-- =====================================================

-- Generate 2 years of daily demand data
INSERT INTO SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 (
    MANDT, MATNR, WERKS, BERID, DTART, DTERQ,
    PLNUM, PLORD, RESB,
    MENGE, MEINS, ENMNG, OPNG,
    LABST, UMLMC, INSME, EINME,
    DISPO, DISLS, BESKZ, SOBSL,
    WZEIT, PLIFZ, WEBRE,
    LIFNR, EKGRP,
    DELKZ, DELET
)
WITH date_series AS (
    SELECT 
        DATEADD(day, -seq, CURRENT_DATE) as dte,
        seq,
        DAYOFWEEK(DATEADD(day, -seq, CURRENT_DATE)) as dow,
        MONTH(DATEADD(day, -seq, CURRENT_DATE)) as mnth
    FROM (SELECT ROW_NUMBER() OVER (ORDER BY 1) - 1 as seq FROM TABLE(GENERATOR(ROWCOUNT => 730)))
)
SELECT 
    '800' as MANDT,
    'TEST_FCAST_001' as MATNR,
    'PL01' as WERKS,
    'MRP01' as BERID,
    'CU' as DTART,
    dte as DTERQ,
    'PL' || LPAD(seq::STRING, 5, '0') as PLNUM,
    NULL as PLORD,
    'RS' || LPAD(seq::STRING, 5, '0') as RESB,
    -- Demand with trend and seasonality
    GREATEST(0, ROUND(
        500 + 
        (seq * 0.2) +  -- Trend
        CASE dow
            WHEN 0 THEN -100  -- Sunday
            WHEN 1 THEN 150   -- Monday
            WHEN 2 THEN 50    -- Tuesday
            WHEN 3 THEN 100   -- Wednesday
            WHEN 4 THEN 50    -- Thursday
            WHEN 5 THEN -50   -- Friday
            WHEN 6 THEN -200  -- Saturday
        END +
        CASE mnth
            WHEN 1 THEN -100  -- January
            WHEN 2 THEN -50   -- February
            WHEN 3 THEN 0     -- March
            WHEN 4 THEN 50    -- April
            WHEN 5 THEN 100   -- May
            WHEN 6 THEN 150   -- June
            WHEN 7 THEN 200   -- July
            WHEN 8 THEN 250   -- August
            WHEN 9 THEN 300   -- September
            WHEN 10 THEN 350  -- October
            WHEN 11 THEN 400  -- November
            WHEN 12 THEN 450  -- December
        END +
        (ABS(RANDOM()) % 101 - 50)  -- Random noise between -50 and 50
    , 0)) as MENGE,
    'EA' as MEINS,
    0 as ENMNG,
    MENGE as OPNG,
    10000 as LABST,
    0 as UMLMC,
    0 as INSME,
    0 as EINME,
    '001' as DISPO,
    'WB' as DISLS,
    'E' as BESKZ,
    NULL as SOBSL,
    0 as WZEIT,
    5 as PLIFZ,
    'X' as WEBRE,
    'SUP001' as LIFNR,
    '001' as EKGRP,
    'B' as DELKZ,
    '' as DELET
FROM date_series
ORDER BY dte;

-- =====================================================
-- TEST_FCAST_002: SUFFICIENT DATA - 2 years of weekly demand
-- =====================================================

INSERT INTO SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 (
    MANDT, MATNR, WERKS, BERID, DTART, DTERQ,
    PLNUM, PLORD, RESB,
    MENGE, MEINS, ENMNG, OPNG,
    LABST, UMLMC, INSME, EINME,
    DISPO, DISLS, BESKZ, SOBSL,
    WZEIT, PLIFZ, WEBRE,
    LIFNR, EKGRP,
    DELKZ, DELET
)
WITH weekly_series AS (
    SELECT 
        DATEADD(week, -seq, DATE_TRUNC('week', CURRENT_DATE)) as dte,
        seq,
        QUARTER(DATEADD(week, -seq, DATE_TRUNC('week', CURRENT_DATE))) as qtr
    FROM (SELECT ROW_NUMBER() OVER (ORDER BY 1) - 1 as seq FROM TABLE(GENERATOR(ROWCOUNT => 104)))
)
SELECT 
    '800' as MANDT,
    'TEST_FCAST_002' as MATNR,
    'PL01' as WERKS,
    'MRP01' as BERID,
    'CU' as DTART,
    dte as DTERQ,
    'PLW' || LPAD(seq::STRING, 5, '0') as PLNUM,
    NULL as PLORD,
    'RSW' || LPAD(seq::STRING, 5, '0') as RESB,
    -- Weekly demand with quarterly pattern
    GREATEST(0, ROUND(
        2000 +
        CASE qtr
            WHEN 1 THEN -200
            WHEN 2 THEN 0
            WHEN 3 THEN 200
            WHEN 4 THEN 500  -- Q4 peak
        END +
        (ABS(RANDOM()) % 201 - 100)  -- Random noise between -100 and 100
    , 0)) as MENGE,
    'EA' as MEINS,
    0 as ENMNG,
    MENGE as OPNG,
    5000 as LABST,
    0 as UMLMC,
    0 as INSME,
    0 as EINME,
    '002' as DISPO,
    'EX' as DISLS,
    'F' as BESKZ,
    NULL as SOBSL,
    0 as WZEIT,
    7 as PLIFZ,
    'X' as WEBRE,
    'SUP002' as LIFNR,
    '002' as EKGRP,
    'D' as DELKZ,
    '' as DELET
FROM weekly_series
ORDER BY dte;

-- =====================================================
-- TEST_FCAST_003: LIMITED DATA - 3 months of daily demand
-- =====================================================

INSERT INTO SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 (
    MANDT, MATNR, WERKS, BERID, DTART, DTERQ,
    PLNUM, PLORD, RESB,
    MENGE, MEINS, ENMNG, OPNG,
    LABST, UMLMC, INSME, EINME,
    DISPO, DISLS, BESKZ, SOBSL,
    WZEIT, PLIFZ, WEBRE,
    LIFNR, EKGRP,
    DELKZ, DELET
)
WITH date_series AS (
    SELECT 
        DATEADD(day, -seq, CURRENT_DATE) as dte,
        seq
    FROM (SELECT ROW_NUMBER() OVER (ORDER BY 1) - 1 as seq FROM TABLE(GENERATOR(ROWCOUNT => 90)))
)
SELECT 
    '800' as MANDT,
    'TEST_FCAST_003' as MATNR,
    'PL02' as WERKS,
    'MRP02' as BERID,
    'CU' as DTART,
    dte as DTERQ,
    'PL3' || LPAD(seq::STRING, 5, '0') as PLNUM,
    NULL as PLORD,
    'RS3' || LPAD(seq::STRING, 5, '0') as RESB,
    GREATEST(0, ROUND(
        800 + (ABS(RANDOM()) % 201 - 100)  -- Random noise between -100 and 100
    , 0)) as MENGE,
    'EA' as MEINS,
    0 as ENMNG,
    MENGE as OPNG,
    2000 as LABST,
    0 as UMLMC,
    0 as INSME,
    0 as EINME,
    '003' as DISPO,
    'WB' as DISLS,
    'E' as BESKZ,
    NULL as SOBSL,
    0 as WZEIT,
    4 as PLIFZ,
    'X' as WEBRE,
    'SUP003' as LIFNR,
    '003' as EKGRP,
    'B' as DELKZ,
    '' as DELET
FROM date_series
ORDER BY dte;

-- =====================================================
-- TEST_FCAST_004: VERY LIMITED DATA - 2 weeks of demand
-- =====================================================

INSERT INTO SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 (
    MANDT, MATNR, WERKS, BERID, DTART, DTERQ,
    PLNUM, PLORD, RESB,
    MENGE, MEINS, ENMNG, OPNG,
    LABST, UMLMC, INSME, EINME,
    DISPO, DISLS, BESKZ, SOBSL,
    WZEIT, PLIFZ, WEBRE,
    LIFNR, EKGRP,
    DELKZ, DELET
)
WITH date_series AS (
    SELECT 
        DATEADD(day, -seq, CURRENT_DATE) as dte,
        seq
    FROM (SELECT ROW_NUMBER() OVER (ORDER BY 1) - 1 as seq FROM TABLE(GENERATOR(ROWCOUNT => 14)))
)
SELECT 
    '800' as MANDT,
    'TEST_FCAST_004' as MATNR,
    'PL02' as WERKS,
    'MRP02' as BERID,
    'CU' as DTART,
    dte as DTERQ,
    'PL4' || LPAD(seq::STRING, 5, '0') as PLNUM,
    NULL as PLORD,
    'RS4' || LPAD(seq::STRING, 5, '0') as RESB,
    GREATEST(0, ROUND(
        500 + (ABS(RANDOM()) % 101 - 50)  -- Random noise between -50 and 50
    , 0)) as MENGE,
    'EA' as MEINS,
    0 as ENMNG,
    MENGE as OPNG,
    1000 as LABST,
    0 as UMLMC,
    0 as INSME,
    0 as EINME,
    '004' as DISPO,
    'EX' as DISLS,
    'F' as BESKZ,
    NULL as SOBSL,
    0 as WZEIT,
    3 as PLIFZ,
    'X' as WEBRE,
    'SUP004' as LIFNR,
    '004' as EKGRP,
    'D' as DELKZ,
    '' as DELET
FROM date_series
ORDER BY dte;

-- =====================================================
-- TEST_FCAST_005: NO DATA - Brand new material
-- =====================================================
-- Intentionally no data for TEST_FCAST_005

-- =====================================================
-- TEST_FCAST_006: SPORADIC DEMAND - Intermittent spikes
-- =====================================================

INSERT INTO SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 (
    MANDT, MATNR, WERKS, BERID, DTART, DTERQ,
    PLNUM, PLORD, RESB,
    MENGE, MEINS, ENMNG, OPNG,
    LABST, UMLMC, INSME, EINME,
    DISPO, DISLS, BESKZ, SOBSL,
    WZEIT, PLIFZ, WEBRE,
    LIFNR, EKGRP,
    DELKZ, DELET
)
WITH date_series AS (
    SELECT 
        DATEADD(day, -seq, CURRENT_DATE) as dte,
        seq
    FROM (SELECT ROW_NUMBER() OVER (ORDER BY 1) - 1 as seq FROM TABLE(GENERATOR(ROWCOUNT => 700)))
)
SELECT 
    '800' as MANDT,
    'TEST_FCAST_006' as MATNR,
    'PL03' as WERKS,
    'MRP03' as BERID,
    'CU' as DTART,
    dte as DTERQ,
    'PL6' || LPAD(seq::STRING, 5, '0') as PLNUM,
    NULL as PLORD,
    'RS6' || LPAD(seq::STRING, 5, '0') as RESB,
    CASE 
        WHEN ABS(RANDOM()) % 10 < 2 THEN ROUND(ABS(RANDOM()) % 5001 + 5000, 0)  -- 20% chance of spike (5000-10000)
        ELSE ROUND(ABS(RANDOM()) % 401 + 100, 0)  -- Normal demand (100-500)
    END as MENGE,
    'EA' as MEINS,
    0 as ENMNG,
    MENGE as OPNG,
    5000 as LABST,
    0 as UMLMC,
    0 as INSME,
    0 as EINME,
    '005' as DISPO,
    'WB' as DISLS,
    'E' as BESKZ,
    NULL as SOBSL,
    0 as WZEIT,
    5 as PLIFZ,
    'X' as WEBRE,
    'SUP006' as LIFNR,
    '005' as EKGRP,
    'B' as DELKZ,
    '' as DELET
FROM date_series
ORDER BY dte;

-- =====================================================
-- TEST_FCAST_007: ZERO DEMAND PERIODS - Material with gaps
-- =====================================================

INSERT INTO SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 (
    MANDT, MATNR, WERKS, BERID, DTART, DTERQ,
    PLNUM, PLORD, RESB,
    MENGE, MEINS, ENMNG, OPNG,
    LABST, UMLMC, INSME, EINME,
    DISPO, DISLS, BESKZ, SOBSL,
    WZEIT, PLIFZ, WEBRE,
    LIFNR, EKGRP,
    DELKZ, DELET
)
WITH date_series AS (
    SELECT 
        DATEADD(day, -seq, CURRENT_DATE) as dte,
        seq,
        MONTH(DATEADD(day, -seq, CURRENT_DATE)) as mnth
    FROM (SELECT ROW_NUMBER() OVER (ORDER BY 1) - 1 as seq FROM TABLE(GENERATOR(ROWCOUNT => 600)))
)
SELECT 
    '800' as MANDT,
    'TEST_FCAST_007' as MATNR,
    'PL01' as WERKS,
    'MRP01' as BERID,
    'CU' as DTART,
    dte as DTERQ,
    'PL7' || LPAD(seq::STRING, 5, '0') as PLNUM,
    NULL as PLORD,
    'RS7' || LPAD(seq::STRING, 5, '0') as RESB,
    CASE 
        WHEN mnth IN (1, 2, 7, 8) THEN 0  -- Zero demand in Jan, Feb, Jul, Aug
        ELSE ROUND(ABS(RANDOM()) % 401 + 200, 0)  -- Demand 200-600
    END as MENGE,
    'EA' as MEINS,
    0 as ENMNG,
    MENGE as OPNG,
    3000 as LABST,
    0 as UMLMC,
    0 as INSME,
    0 as EINME,
    '006' as DISPO,
    'WB' as DISLS,
    'E' as BESKZ,
    NULL as SOBSL,
    0 as WZEIT,
    4 as PLIFZ,
    'X' as WEBRE,
    'SUP007' as LIFNR,
    '006' as EKGRP,
    'B' as DELKZ,
    '' as DELET
FROM date_series
ORDER BY dte;

-- =====================================================
-- TEST_FCAST_008: HIGH VOLATILITY - Erratic demand
-- =====================================================

INSERT INTO SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 (
    MANDT, MATNR, WERKS, BERID, DTART, DTERQ,
    PLNUM, PLORD, RESB,
    MENGE, MEINS, ENMNG, OPNG,
    LABST, UMLMC, INSME, EINME,
    DISPO, DISLS, BESKZ, SOBSL,
    WZEIT, PLIFZ, WEBRE,
    LIFNR, EKGRP,
    DELKZ, DELET
)
WITH date_series AS (
    SELECT 
        DATEADD(day, -seq, CURRENT_DATE) as dte,
        seq
    FROM (SELECT ROW_NUMBER() OVER (ORDER BY 1) - 1 as seq FROM TABLE(GENERATOR(ROWCOUNT => 500)))
)
SELECT 
    '800' as MANDT,
    'TEST_FCAST_008' as MATNR,
    'PL02' as WERKS,
    'MRP02' as BERID,
    'CU' as DTART,
    dte as DTERQ,
    'PL8' || LPAD(seq::STRING, 5, '0') as PLNUM,
    NULL as PLORD,
    'RS8' || LPAD(seq::STRING, 5, '0') as RESB,
    GREATEST(0, ROUND(
        1000 + (ABS(RANDOM()) % 1601 - 800)  -- High volatility -800 to +800
    , 0)) as MENGE,
    'EA' as MEINS,
    0 as ENMNG,
    MENGE as OPNG,
    5000 as LABST,
    0 as UMLMC,
    0 as INSME,
    0 as EINME,
    '007' as DISPO,
    'EX' as DISLS,
    'F' as BESKZ,
    NULL as SOBSL,
    0 as WZEIT,
    6 as PLIFZ,
    'X' as WEBRE,
    'SUP008' as LIFNR,
    '007' as EKGRP,
    'D' as DELKZ,
    '' as DELET
FROM date_series
ORDER BY dte;

-- =====================================================
-- VERIFICATION QUERY - Check data statistics
-- =====================================================
SELECT 
    MATNR as material_id,
    WERKS as plant,
    COUNT(*) as total_days,
    MIN(DTERQ) as earliest_date,
    MAX(DTERQ) as latest_date,
    ROUND(AVG(MENGE), 2) as avg_demand,
    ROUND(STDDEV(MENGE), 2) as stddev_demand,
    MIN(MENGE) as min_demand,
    MAX(MENGE) as max_demand,
    COUNT(CASE WHEN MENGE = 0 THEN 1 END) as zero_days
FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04
WHERE MATNR LIKE 'TEST_FCAST_%'
GROUP BY MATNR, WERKS
ORDER BY MATNR;

-- =====================================================
-- TEST THE STORED PROCEDURE (example calls)
-- =====================================================

/*
-- Test Case 1: Sufficient data - should use RandomForest
CALL predict_demand('TEST_FCAST_001', 'PL01', 30);

-- Test Case 2: Weekly data - should use RandomForest
CALL predict_demand('TEST_FCAST_002', 'PL01', 30);

-- Test Case 3: Limited data (90 days) - should use moving average if <30 after feature engineering
CALL predict_demand('TEST_FCAST_003', 'PL02', 14);

-- Test Case 4: Very limited data (14 days) - should use last value
CALL predict_demand('TEST_FCAST_004', 'PL02', 7);

-- Test Case 5: No data - should return zeros
CALL predict_demand('TEST_FCAST_005', 'PL01', 10);

-- Test Case 6: Sporadic demand with spikes
CALL predict_demand('TEST_FCAST_006', 'PL03', 30);

-- Test Case 7: Zero demand periods
CALL predict_demand('TEST_FCAST_007', 'PL01', 30);

-- Test Case 8: High volatility
CALL predict_demand('TEST_FCAST_008', 'PL02', 30);
*/

-- =====================================================
-- DELETE STATEMENT FOR TEST DATA
-- Run this to clean up all test data
-- =====================================================

/*
-- Delete from MD04
DELETE FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 
WHERE MATNR LIKE 'TEST_FCAST_%';

-- Verify deletion
SELECT COUNT(*) as remaining_records,
       MIN(MATNR) as first_material,
       MAX(MATNR) as last_material
FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 
WHERE MATNR LIKE 'TEST_FCAST_%';
*/