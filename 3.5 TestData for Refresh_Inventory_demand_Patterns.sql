USE WAREHOUSE SAP_COMPUTE;
USE DATABASE SAP_BDC_HORIZON_CATALOG;
USE SCHEMA AGENTS;

-- REFRESH_INVENTORY_DEMAND_PATTERNS
/*
Test Data Summary for Task Testing:
Test Material	  Purpose	Key                                         Features
TEST_TASK_A	        Complete coverage of date ranges	Past due, today, next 7 days, 2-4 weeks, 1-2 months, 2-3 months, exactly 3 months, beyond 3 months (should be excluded)
TEST_TASK_B	        Seasonal pattern testing	        Requirements in Spring/Summer months to test season detection
TEST_TASK_C	        Ramping product	                    Increasing quantities over time
TEST_TASK_D	        Mixed requirement types	            CU, DL, PR, PE all present
TEST_TASK_NO_DESC	LEFT JOIN test	                    No matching VBAP record to test NULL handling
TEST_TASK_MULTI	    Multiple same-day requirements	    Three different requirement types on same date
TEST_TASK_ZERO	    Edge case	                        Zero quantity requirement
*/

-- =====================================================
-- TEST DATA GENERATION FOR REFRESH_INVENTORY_DEMAND_PATTERNS TASK
-- All test data is marked with 'TEST_TASK_' prefix
-- Designed to work with dynamic CURRENT_DATE in the task
-- =====================================================


-- =====================================================
-- TEST DATA FOR MARC TABLE
-- =====================================================
INSERT INTO SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MARC (
    MANDT, MATNR, WERKS, DISPO, DISMM, BESKZ, SOBSL,
    MINBE, EISBE, BSTMI, BSTMA, BSTFE,
    PLIFZ, WEBAZ, BEARZ, RUEZT, TRANSZ,
    LOSGR, PERKZ, PERIV, AUSSS,
    KZPRD, VRMOD, VINT1, VINT2,
    FHORI, WEBRE, PRCTL,
    LGPRO, LGRAD, DISPR
) VALUES 
-- Task Test Materials with different MRP controllers
('800', 'TEST_TASK_A', 'PL01', 'T01', 'PD', 'F', NULL,
 500, 200, 100, 5000, NULL,
 5, 1, 1, 0, 2,
 'WB', 'W', 'V1', 1,
 '1', '1', '1', '1',
 '001', 'X', 'ZM',
 'PROD', 85.00, 'DS1'),

('800', 'TEST_TASK_B', 'PL01', 'T02', 'VB', 'F', NULL,
 300, 150, 200, 3000, NULL,
 7, 2, 1, 0, 3,
 'EX', 'M', 'V2', 1,
 '1', '2', '2', '2',
 '002', 'X', 'ZF',
 'PROD', 75.00, 'DS2'),

('800', 'TEST_TASK_C', 'PL02', 'T01', 'PD', 'E', '30',
 200, 100, 50, 2000, NULL,
 4, 1, 1, 0, 2,
 'WB', 'W', 'V1', 1,
 '1', '1', '1', '1',
 '001', 'X', 'ZM',
 'PROD', 90.00, 'DS1'),

('800', 'TEST_TASK_D', 'PL03', 'T03', 'ND', 'F', NULL,
 1000, 500, 500, 10000, NULL,
 3, 1, 2, 0, 1,
 'WB', 'W', 'V1', 1,
 '1', '1', '1', '1',
 '003', 'X', 'ZM',
 'RAW', 95.00, 'DS3');

-- =====================================================
-- TEST DATA FOR VBAP TABLE (Material Descriptions)
-- =====================================================
INSERT INTO SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.VBAP (
    VBELN, POSNR, MATNR, ARKTX, WERKS, LGORT, CHARG,
    KWMENG, VRKME, MEINS, UMZIN, UMZIZ,
    NETWR, NETPR, PEINH, KPEIN,
    EDTNR, EINDT, ETENR,
    PSTYV, ABGRU, LFSTA, FKSTA,
    CUOBJ, POSEX
) VALUES 
('TASK001', '0010', 'TEST_TASK_A', 'Task Test - High Runner Material', 'PL01', 'ST01', NULL,
 0, 'EA', 'EA', 1, 1,
 0, 0, 1, 1,
 '0001', DATEADD(day, 30, CURRENT_DATE), '0010',
 'ZTAK', NULL, 'C', NULL,
 NULL, NULL),

('TASK002', '0010', 'TEST_TASK_B', 'Task Test - Seasonal Product', 'PL01', 'ST02', NULL,
 0, 'EA', 'EA', 1, 1,
 0, 0, 1, 1,
 '0001', DATEADD(day, 45, CURRENT_DATE), '0010',
 'ZTAK', NULL, 'C', NULL,
 NULL, NULL),

('TASK003', '0010', 'TEST_TASK_C', 'Task Test - New Product Launch', 'PL02', 'STA1', NULL,
 0, 'EA', 'EA', 1, 1,
 0, 0, 1, 1,
 '0001', DATEADD(day, 15, CURRENT_DATE), '0010',
 'ZTAK', NULL, 'C', NULL,
 NULL, NULL),

('TASK004', '0010', 'TEST_TASK_D', 'Task Test - Raw Material Bulk', 'PL03', 'STD1', NULL,
 0, 'KG', 'KG', 1, 1,
 0, 0, 1, 1,
 '0001', DATEADD(day, 10, CURRENT_DATE), '0010',
 'ZTAK', NULL, 'C', NULL,
 NULL, NULL);

-- =====================================================
-- TEST DATA FOR MD04 TABLE - DYNAMIC BASED ON CURRENT_DATE
-- This data will be picked up by the task when it runs
-- =====================================================

-- Clean up any existing test data first (optional - comment out if first run)
-- DELETE FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 
-- WHERE MATNR LIKE 'TEST_TASK_%';

INSERT INTO SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 (
    MANDT, MATNR, WERKS, BERID, DTART, DTERQ,
    PLNUM, PLORD, RESB,
    MENGE, MEINS, ENMNG, OPNG,
    LABST, UMLMC, INSME, EINME,
    DISPO, DISLS, BESKZ, SOBSL,
    WZEIT, PLIFZ, WEBRE,
    LIFNR, EKGRP,
    DELKZ, DELET
) VALUES 

-- =====================================================
-- TEST_TASK_A: Mixed requirements across the 3-month window
-- =====================================================

-- Past due (should show HIGH priority)
('800', 'TEST_TASK_A', 'PL01', 'MRP01', 'CU', DATEADD(day, -2, CURRENT_DATE),
 'TASK001', 'PO001', 'RS001',
 500, 'EA', 0, 500,
 2000, 0, 0, 0,
 'T01', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', 'T01',
 'B', ''),

-- Today (should show HIGH priority - equal to CURRENT_DATE)
('800', 'TEST_TASK_A', 'PL01', 'MRP01', 'CU', CURRENT_DATE,
 'TASK002', 'PO002', 'RS002',
 750, 'EA', 0, 750,
 2000, 0, 0, 0,
 'T01', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', 'T01',
 'B', ''),

-- Next 7 days
('800', 'TEST_TASK_A', 'PL01', 'MRP01', 'CU', DATEADD(day, 3, CURRENT_DATE),
 'TASK003', 'PO003', 'RS003',
 600, 'EA', 0, 600,
 2000, 0, 0, 0,
 'T01', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', 'T01',
 'B', ''),

('800', 'TEST_TASK_A', 'PL01', 'MRP01', 'DL', DATEADD(day, 5, CURRENT_DATE),
 'TASK004', NULL, NULL,
 800, 'EA', 200, 600,  -- Partially received (OPNG = 600)
 2000, 0, 0, 0,
 'T01', 'WB', 'F', NULL,
 0, 5, 'X',
 'SUP002', 'T01',
 'D', ''),

-- 2-4 weeks out
('800', 'TEST_TASK_A', 'PL01', 'MRP01', 'CU', DATEADD(day, 14, CURRENT_DATE),
 'TASK005', 'PO005', 'RS005',
 550, 'EA', 0, 550,
 2000, 0, 0, 0,
 'T01', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', 'T01',
 'B', ''),

('800', 'TEST_TASK_A', 'PL01', 'MRP01', 'CU', DATEADD(day, 21, CURRENT_DATE),
 'TASK006', 'PO006', 'RS006',
 700, 'EA', 0, 700,
 2000, 0, 0, 0,
 'T01', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', 'T01',
 'B', ''),

('800', 'TEST_TASK_A', 'PL01', 'MRP01', 'PE', DATEADD(day, 28, CURRENT_DATE),
 'TASK007', NULL, NULL,
 450, 'EA', 0, 450,
 2000, 0, 0, 0,
 'T01', 'WB', 'E', NULL,
 0, 5, 'X',
 NULL, 'T01',
 'P', ''),

-- 1-2 months out
('800', 'TEST_TASK_A', 'PL01', 'MRP01', 'CU', DATEADD(day, 45, CURRENT_DATE),
 'TASK008', 'PO008', 'RS008',
 650, 'EA', 0, 650,
 2000, 0, 0, 0,
 'T01', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', 'T01',
 'B', ''),

-- 2-3 months out
('800', 'TEST_TASK_A', 'PL01', 'MRP01', 'CU', DATEADD(day, 75, CURRENT_DATE),
 'TASK009', 'PO009', 'RS009',
 600, 'EA', 0, 600,
 2000, 0, 0, 0,
 'T01', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', 'T01',
 'B', ''),

-- Just at the 3-month boundary (should be included)
('800', 'TEST_TASK_A', 'PL01', 'MRP01', 'PR', DATEADD(day, 90, CURRENT_DATE),
 'TASK010', NULL, NULL,
 400, 'EA', 0, 400,
 2000, 0, 0, 0,
 'T01', 'WB', 'F', NULL,
 0, 5, 'X',
 'SUP003', 'T01',
 'P', ''),

-- Beyond 3 months (should NOT be included - test exclusion)
('800', 'TEST_TASK_A', 'PL01', 'MRP01', 'CU', DATEADD(day, 95, CURRENT_DATE),
 'TASK011', 'PO011', 'RS011',
 500, 'EA', 0, 500,
 2000, 0, 0, 0,
 'T01', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', 'T01',
 'B', ''),

-- =====================================================
-- TEST_TASK_B: Seasonal product - Spring/Summer pattern
-- =====================================================

-- Spring months (March, April, May)
('800', 'TEST_TASK_B', 'PL01', 'MRP01', 'DL', DATEADD(day, 15, CURRENT_DATE),
 'TASK012', NULL, NULL,
 1200, 'EA', 0, 1200,
 500, 0, 0, 0,
 'T02', 'EX', 'F', NULL,
 0, 7, 'X',
 'SUP004', 'T02',
 'D', ''),

('800', 'TEST_TASK_B', 'PL01', 'MRP01', 'DL', DATEADD(day, 30, CURRENT_DATE),
 'TASK013', NULL, NULL,
 1500, 'EA', 0, 1500,
 500, 0, 0, 0,
 'T02', 'EX', 'F', NULL,
 0, 7, 'X',
 'SUP004', 'T02',
 'D', ''),

-- Summer months (June, July, August)
('800', 'TEST_TASK_B', 'PL01', 'MRP01', 'DL', DATEADD(day, 60, CURRENT_DATE),
 'TASK014', NULL, NULL,
 2000, 'EA', 0, 2000,
 500, 0, 0, 0,
 'T02', 'EX', 'F', NULL,
 0, 7, 'X',
 'SUP004', 'T02',
 'D', ''),

('800', 'TEST_TASK_B', 'PL01', 'MRP01', 'CU', DATEADD(day, 75, CURRENT_DATE),
 'TASK015', 'PO015', 'RS015',
 1800, 'EA', 0, 1800,
 500, 0, 0, 0,
 'T02', 'EX', 'E', NULL,
 0, 7, 'X',
 'SUP005', 'T02',
 'B', ''),

-- =====================================================
-- TEST_TASK_C: New product - Ramping up
-- =====================================================

-- Early requirements
('800', 'TEST_TASK_C', 'PL02', 'MRP02', 'PE', DATEADD(day, 7, CURRENT_DATE),
 'TASK016', NULL, NULL,
 200, 'EA', 0, 200,
 800, 0, 0, 0,
 'T01', 'WB', 'E', '30',
 0, 4, 'X',
 NULL, 'T01',
 'P', ''),

('800', 'TEST_TASK_C', 'PL02', 'MRP02', 'PE', DATEADD(day, 20, CURRENT_DATE),
 'TASK017', NULL, NULL,
 250, 'EA', 0, 250,
 800, 0, 0, 0,
 'T01', 'WB', 'E', '30',
 0, 4, 'X',
 NULL, 'T01',
 'P', ''),

('800', 'TEST_TASK_C', 'PL02', 'MRP02', 'PE', DATEADD(day, 35, CURRENT_DATE),
 'TASK018', NULL, NULL,
 300, 'EA', 0, 300,
 800, 0, 0, 0,
 'T01', 'WB', 'E', '30',
 0, 4, 'X',
 NULL, 'T01',
 'P', ''),

('800', 'TEST_TASK_C', 'PL02', 'MRP02', 'CU', DATEADD(day, 50, CURRENT_DATE),
 'TASK019', 'PO019', 'RS019',
 350, 'EA', 0, 350,
 800, 0, 0, 0,
 'T01', 'WB', 'E', '30',
 0, 4, 'X',
 'SUP006', 'T01',
 'B', ''),

('800', 'TEST_TASK_C', 'PL02', 'MRP02', 'CU', DATEADD(day, 70, CURRENT_DATE),
 'TASK020', 'PO020', 'RS020',
 400, 'EA', 0, 400,
 800, 0, 0, 0,
 'T01', 'WB', 'E', '30',
 0, 4, 'X',
 'SUP006', 'T01',
 'B', ''),

-- =====================================================
-- TEST_TASK_D: Raw material - Various requirement types
-- =====================================================

-- Mix of requirement types
('800', 'TEST_TASK_D', 'PL03', 'MRP03', 'CU', DATEADD(day, 2, CURRENT_DATE),
 'TASK021', 'PO021', 'RS021',
 5000, 'KG', 0, 5000,
 15000, 0, 0, 0,
 'T03', 'WB', 'E', NULL,
 0, 3, 'X',
 'SUP007', 'T03',
 'B', ''),

('800', 'TEST_TASK_D', 'PL03', 'MRP03', 'CU', DATEADD(day, 12, CURRENT_DATE),
 'TASK022', 'PO022', 'RS022',
 6000, 'KG', 1000, 5000,  -- Partially received
 15000, 0, 0, 0,
 'T03', 'WB', 'E', NULL,
 0, 3, 'X',
 'SUP007', 'T03',
 'B', ''),

('800', 'TEST_TASK_D', 'PL03', 'MRP03', 'DL', DATEADD(day, 25, CURRENT_DATE),
 'TASK023', NULL, NULL,
 7000, 'KG', 0, 7000,
 15000, 0, 0, 0,
 'T03', 'WB', 'F', NULL,
 0, 3, 'X',
 'SUP008', 'T03',
 'D', ''),

('800', 'TEST_TASK_D', 'PL03', 'MRP03', 'PR', DATEADD(day, 40, CURRENT_DATE),
 'TASK024', NULL, NULL,
 8000, 'KG', 0, 8000,
 15000, 0, 0, 0,
 'T03', 'WB', 'F', NULL,
 0, 3, 'X',
 'SUP009', 'T03',
 'P', ''),

('800', 'TEST_TASK_D', 'PL03', 'MRP03', 'PE', DATEADD(day, 60, CURRENT_DATE),
 'TASK025', NULL, NULL,
 5500, 'KG', 0, 5500,
 15000, 0, 0, 0,
 'T03', 'WB', 'E', NULL,
 0, 3, 'X',
 NULL, 'T03',
 'P', ''),

('800', 'TEST_TASK_D', 'PL03', 'MRP03', 'PE', DATEADD(day, 80, CURRENT_DATE),
 'TASK026', NULL, NULL,
 6500, 'KG', 0, 6500,
 15000, 0, 0, 0,
 'T03', 'WB', 'E', NULL,
 0, 3, 'X',
 NULL, 'T03',
 'P', ''),

-- =====================================================
-- Edge Cases for Testing
-- =====================================================

-- Material with no description (test LEFT JOIN behavior)
('800', 'TEST_TASK_NO_DESC', 'PL01', 'MRP01', 'CU', DATEADD(day, 10, CURRENT_DATE),
 'TASK027', 'PO027', 'RS027',
 100, 'EA', 0, 100,
 500, 0, 0, 0,
 'T01', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP010', 'T01',
 'B', ''),

-- Material with multiple requirements on same day
('800', 'TEST_TASK_MULTI', 'PL01', 'MRP01', 'CU', DATEADD(day, 15, CURRENT_DATE),
 'TASK028', 'PO028', 'RS028',
 200, 'EA', 0, 200,
 1000, 0, 0, 0,
 'T01', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP011', 'T01',
 'B', ''),

('800', 'TEST_TASK_MULTI', 'PL01', 'MRP01', 'DL', DATEADD(day, 15, CURRENT_DATE),
 'TASK029', NULL, NULL,
 300, 'EA', 0, 300,
 1000, 0, 0, 0,
 'T01', 'WB', 'F', NULL,
 0, 5, 'X',
 'SUP012', 'T01',
 'D', ''),

('800', 'TEST_TASK_MULTI', 'PL01', 'MRP01', 'PE', DATEADD(day, 15, CURRENT_DATE),
 'TASK030', NULL, NULL,
 150, 'EA', 0, 150,
 1000, 0, 0, 0,
 'T01', 'WB', 'E', NULL,
 0, 5, 'X',
 NULL, 'T01',
 'P', ''),

-- Zero quantity requirement (test handling)
('800', 'TEST_TASK_ZERO', 'PL02', 'MRP02', 'CU', DATEADD(day, 5, CURRENT_DATE),
 'TASK031', 'PO031', 'RS031',
 0, 'EA', 0, 0,
 500, 0, 0, 0,
 'T02', 'WB', 'E', NULL,
 0, 4, 'X',
 'SUP013', 'T02',
 'B', '');

-- =====================================================
-- VERIFICATION QUERY - Check what the task will process
-- =====================================================
WITH date_ref AS (SELECT CURRENT_DATE as ref_date)
SELECT 
    CONCAT(md.MATNR, '-', md.WERKS) as pattern_id,
    md.MATNR as material_id,
    md.WERKS as plant,
    m.ARKTX as material_description,
    md.DTERQ as requirement_date,
    md.MENGE as requirement_qty,
    md.DTART as requirement_type,
    CASE 
        WHEN md.DTART = 'CU' THEN 'Customer Order'
        WHEN md.DTART = 'DL' THEN 'Delivery Schedule'
        WHEN md.DTART = 'PE' THEN 'Planned Order'
        WHEN md.DTART = 'PR' THEN 'Purchase Requisition'
        ELSE 'Other'
    END as requirement_type_desc,
    md.DISPO as mrp_controller,
    CASE WHEN md.DTERQ <= ref_date THEN 'HIGH' ELSE 'NORMAL' END as priority,
    CASE 
        WHEN MONTH(md.DTERQ) IN (12,1,2) THEN 'Winter'
        WHEN MONTH(md.DTERQ) IN (3,4,5) THEN 'Spring'
        WHEN MONTH(md.DTERQ) IN (6,7,8) THEN 'Summer'
        ELSE 'Fall'
    END as season,
    md.OPNG as open_qty,
    COALESCE(md.LIFNR, 'Not assigned') as supplier,
    md.DTERQ BETWEEN ref_date AND DATEADD(month, 3, ref_date) as should_be_included
FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 md
LEFT JOIN SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.VBAP m ON md.MATNR = m.MATNR
CROSS JOIN date_ref
WHERE md.MATNR LIKE 'TEST_TASK_%'
ORDER BY md.MATNR, md.DTERQ;

-- =====================================================
-- TEST THE TASK MANUALLY (for verification)
-- =====================================================
/*
-- Execute the task logic manually to verify it works
INSERT OVERWRITE INTO INVENTORY_DEMAND_PATTERNS_STAGING
WITH date_ref AS (SELECT CURRENT_DATE as ref_date)
SELECT 
    CONCAT(md.MATNR, '-', md.WERKS) as pattern_id,
    md.MATNR as material_id,
    md.WERKS as plant,
    m.ARKTX as material_description,
    md.DTERQ as requirement_date,
    md.MENGE as requirement_qty,
    md.DTART as requirement_type,
    CASE 
        WHEN md.DTART = 'CU' THEN 'Customer Order'
        WHEN md.DTART = 'DL' THEN 'Delivery Schedule'
        WHEN md.DTART = 'PE' THEN 'Planned Order'
        WHEN md.DTART = 'PR' THEN 'Purchase Requisition'
        ELSE 'Other'
    END as requirement_type_desc,
    md.DISPO as mrp_controller,
    CONCAT(
        'Material ', COALESCE(m.ARKTX, 'Unknown'), ' (', md.MATNR, ') at plant ', md.WERKS,
        ' has a requirement of ', md.MENGE, ' ', md.MEINS,
        ' on ', md.DTERQ, ' of type ', 
        CASE WHEN md.DTART = 'CU' THEN 'customer order' 
             WHEN md.DTART = 'DL' THEN 'delivery schedule'
             ELSE 'planning requirement' END,
        CASE WHEN md.OPNG > 0 THEN '. Open quantity: ' || md.OPNG ELSE '' END
    ) as search_text,
    OBJECT_CONSTRUCT(
        'priority', CASE WHEN md.DTERQ <= ref_date THEN 'HIGH' ELSE 'NORMAL' END,
        'open_qty', md.OPNG,
        'supplier', COALESCE(md.LIFNR, 'Not assigned'),
        'season', CASE 
            WHEN MONTH(md.DTERQ) IN (12,1,2) THEN 'Winter'
            WHEN MONTH(md.DTERQ) IN (3,4,5) THEN 'Spring'
            WHEN MONTH(md.DTERQ) IN (6,7,8) THEN 'Summer'
            ELSE 'Fall'
        END
    ) as metadata
FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 md
LEFT JOIN SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.VBAP m ON md.MATNR = m.MATNR
CROSS JOIN date_ref
WHERE md.MATNR LIKE 'TEST_TASK_%'
  AND md.DTERQ BETWEEN ref_date AND DATEADD(month, 3, ref_date);

-- Check what was inserted into staging
SELECT * FROM INVENTORY_DEMAND_PATTERNS_STAGING 
WHERE material_id LIKE 'TEST_TASK_%'
ORDER BY material_id, requirement_date;
*/

-- =====================================================
-- DELETE STATEMENT FOR TEST DATA
-- Run this to clean up all test data
-- =====================================================

/*
-- Delete from staging table first (if you want to clear it too)
DELETE FROM INVENTORY_DEMAND_PATTERNS_STAGING 
WHERE material_id LIKE 'TEST_TASK_%';

-- Delete from MD04 (main source table)
DELETE FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 
WHERE MATNR LIKE 'TEST_TASK_%';

-- Delete from MARC
DELETE FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MARC 
WHERE MATNR LIKE 'TEST_TASK_%';

-- Delete from VBAP
DELETE FROM SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.VBAP 
WHERE MATNR LIKE 'TEST_TASK_%';

-- Verify deletion
SELECT 'MD04' as table_name, COUNT(*) as remaining_records 
FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 
WHERE MATNR LIKE 'TEST_TASK_%'
UNION ALL
SELECT 'MARC', COUNT(*) 
FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MARC 
WHERE MATNR LIKE 'TEST_TASK_%'
UNION ALL
SELECT 'VBAP', COUNT(*) 
FROM SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.VBAP 
WHERE MATNR LIKE 'TEST_TASK_%'
UNION ALL
SELECT 'STAGING', COUNT(*) 
FROM INVENTORY_DEMAND_PATTERNS_STAGING 
WHERE material_id LIKE 'TEST_TASK_%';
*/