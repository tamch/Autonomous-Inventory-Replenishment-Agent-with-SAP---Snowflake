USE WAREHOUSE SAP_COMPUTE;
USE DATABASE SAP_BDC_HORIZON_CATALOG;
USE SCHEMA AGENTS;

/*
Test Data Summary for Analysis Function:
Test Material	Scenario	Current Stock	Reorder Point	Safety Stock	Stock Status	Supply Status	Expected Action
TEST_ANLZ_001	CRITICAL	10	200	100	CRITICAL	PAST_DUE	ORDER_IMMEDIATELY
TEST_ANLZ_002	REORDER	200	250	150	REORDER	OK	PLACE_ORDER
TEST_ANLZ_003	HEALTHY	800	300	200	HEALTHY	OK	NO_ACTION
TEST_ANLZ_004	COVERAGE_GAP	150	200	120	WATCH	COVERAGE_GAP	EXPEDITE_SUPPLY

*/
-- =====================================================
-- TEST DATA GENERATION FOR ANALYZE_INVENTORY_STATUS FUNCTION
-- AND CREATE_AUTONOMOUS_PURCHASE_ORDER PROCEDURE
-- All test data is marked with 'TEST_ANLZ_' prefix
-- Designed to test different inventory scenarios
-- =====================================================


-- First, let's recreate the procedure with shorter PO number format


-- =====================================================
-- TEST DATA FOR MATDOC TABLE (Material Documents)
-- =====================================================

INSERT INTO SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MATDOC (
    MBLNR, MJAHR, ZEILE, MATNR, WERKS, LAGER, LGORT,
    BWART, BUDAT, CPUDT, CPUTM, USNAM,
    MENGE, MEINS, DMBTR, WAERS,
    LIFNR, KUNNR, AUFNR, KDAUF, KDPOS,
    XBLNR, BKTXT, BLART, BLDAT,
    CHARG, SOBKZ,
    ERFMG, ERFME, SHKZG
) VALUES 
-- TEST_ANLZ_001: CRITICAL stock scenario
('ANLZ001', '2024', '001', 'TEST_ANLZ_001', 'PL01', 'ST01', 'ST01',
 '101', DATEADD(day, -10, CURRENT_DATE), DATEADD(day, -10, CURRENT_DATE), '09:15:00', 'TESTUSR1',
 150, 'EA', 3000.00, 'USD',
 'SUP001', NULL, NULL, NULL, NULL,
 'REF001', 'Initial Receipt', 'WE', DATEADD(day, -10, CURRENT_DATE),
 'BAT01', NULL,
 150, 'EA', 'S'),

('ANLZ001', '2024', '002', 'TEST_ANLZ_001', 'PL01', 'ST01', 'ST01',
 '261', DATEADD(day, -5, CURRENT_DATE), DATEADD(day, -5, CURRENT_DATE), '14:30:00', 'TESTUSR2',
 80, 'EA', -1600.00, 'USD',
 NULL, NULL, 'PROD01', NULL, NULL,
 'REF002', 'Production Issue', 'WA', DATEADD(day, -5, CURRENT_DATE),
 'BAT01', NULL,
 80, 'EA', 'H'),

('ANLZ001', '2024', '003', 'TEST_ANLZ_001', 'PL01', 'ST01', 'ST01',
 '261', DATEADD(day, -2, CURRENT_DATE), DATEADD(day, -2, CURRENT_DATE), '10:45:00', 'TESTUSR2',
 60, 'EA', -1200.00, 'USD',
 NULL, NULL, 'PROD01', NULL, NULL,
 'REF003', 'Production Issue', 'WA', DATEADD(day, -2, CURRENT_DATE),
 'BAT01', NULL,
 60, 'EA', 'H'),

-- TEST_ANLZ_002: REORDER scenario
('ANLZ002', '2024', '001', 'TEST_ANLZ_002', 'PL01', 'ST02', 'ST02',
 '101', DATEADD(day, -20, CURRENT_DATE), DATEADD(day, -20, CURRENT_DATE), '11:30:00', 'TESTUSR1',
 500, 'EA', 10000.00, 'USD',
 'SUP002', NULL, NULL, NULL, NULL,
 'REF004', 'Initial Receipt', 'WE', DATEADD(day, -20, CURRENT_DATE),
 'BAT02', NULL,
 500, 'EA', 'S'),

('ANLZ002', '2024', '002', 'TEST_ANLZ_002', 'PL01', 'ST02', 'ST02',
 '261', DATEADD(day, -15, CURRENT_DATE), DATEADD(day, -15, CURRENT_DATE), '13:20:00', 'TESTUSR2',
 100, 'EA', -2000.00, 'USD',
 NULL, NULL, 'PROD02', NULL, NULL,
 'REF005', 'Production Issue', 'WA', DATEADD(day, -15, CURRENT_DATE),
 'BAT02', NULL,
 100, 'EA', 'H'),

('ANLZ002', '2024', '003', 'TEST_ANLZ_002', 'PL01', 'ST02', 'ST02',
 '261', DATEADD(day, -10, CURRENT_DATE), DATEADD(day, -10, CURRENT_DATE), '09:45:00', 'TESTUSR2',
 120, 'EA', -2400.00, 'USD',
 NULL, NULL, 'PROD02', NULL, NULL,
 'REF006', 'Production Issue', 'WA', DATEADD(day, -10, CURRENT_DATE),
 'BAT02', NULL,
 120, 'EA', 'H'),

('ANLZ002', '2024', '004', 'TEST_ANLZ_002', 'PL01', 'ST02', 'ST02',
 '261', DATEADD(day, -5, CURRENT_DATE), DATEADD(day, -5, CURRENT_DATE), '15:15:00', 'TESTUSR2',
 80, 'EA', -1600.00, 'USD',
 NULL, NULL, 'PROD02', NULL, NULL,
 'REF007', 'Production Issue', 'WA', DATEADD(day, -5, CURRENT_DATE),
 'BAT02', NULL,
 80, 'EA', 'H'),

-- TEST_ANLZ_003: HEALTHY with good supplier
('ANLZ003', '2024', '001', 'TEST_ANLZ_003', 'PL02', 'ST03', 'ST03',
 '101', DATEADD(day, -30, CURRENT_DATE), DATEADD(day, -30, CURRENT_DATE), '08:00:00', 'TESTUSR1',
 1000, 'KG', 20000.00, 'USD',
 'SUP003', NULL, NULL, NULL, NULL,
 'REF008', 'Bulk Receipt', 'WE', DATEADD(day, -30, CURRENT_DATE),
 'BAT03', NULL,
 1000, 'KG', 'S'),

('ANLZ003', '2024', '002', 'TEST_ANLZ_003', 'PL02', 'ST03', 'ST03',
 '261', DATEADD(day, -25, CURRENT_DATE), DATEADD(day, -25, CURRENT_DATE), '10:30:00', 'TESTUSR2',
 200, 'KG', -4000.00, 'USD',
 NULL, NULL, 'PROD03', NULL, NULL,
 'REF009', 'Production Issue', 'WA', DATEADD(day, -25, CURRENT_DATE),
 'BAT03', NULL,
 200, 'KG', 'H'),

-- TEST_ANLZ_004: COVERAGE_GAP scenario
('ANLZ004', '2024', '001', 'TEST_ANLZ_004', 'PL01', 'ST04', 'ST04',
 '101', DATEADD(day, -15, CURRENT_DATE), DATEADD(day, -15, CURRENT_DATE), '14:45:00', 'TESTUSR1',
 300, 'EA', 6000.00, 'USD',
 'SUP004', NULL, NULL, NULL, NULL,
 'REF010', 'Receipt', 'WE', DATEADD(day, -15, CURRENT_DATE),
 'BAT04', NULL,
 300, 'EA', 'S'),

('ANLZ004', '2024', '002', 'TEST_ANLZ_004', 'PL01', 'ST04', 'ST04',
 '261', DATEADD(day, -10, CURRENT_DATE), DATEADD(day, -10, CURRENT_DATE), '09:15:00', 'TESTUSR2',
 100, 'EA', -2000.00, 'USD',
 NULL, NULL, 'PROD04', NULL, NULL,
 'REF011', 'Issue', 'WA', DATEADD(day, -10, CURRENT_DATE),
 'BAT04', NULL,
 100, 'EA', 'H'),

('ANLZ004', '2024', '003', 'TEST_ANLZ_004', 'PL01', 'ST04', 'ST04',
 '261', DATEADD(day, -3, CURRENT_DATE), DATEADD(day, -3, CURRENT_DATE), '11:30:00', 'TESTUSR2',
 50, 'EA', -1000.00, 'USD',
 NULL, NULL, 'PROD04', NULL, NULL,
 'REF012', 'Issue', 'WA', DATEADD(day, -3, CURRENT_DATE),
 'BAT04', NULL,
 50, 'EA', 'H');

-- =====================================================
-- TEST DATA FOR MARC TABLE (Material Master - MRP Parameters)
-- =====================================================

INSERT INTO SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MARC (
    MANDT, MATNR, WERKS, DISPO, DISMM, MINBE, EISBE, BSTMI, BSTMA, PLIFZ, WEBRE
) VALUES 
('800', 'TEST_ANLZ_001', 'PL01', '001', 'PD', 200, 100, 50, 500, 5, 'X'),
('800', 'TEST_ANLZ_002', 'PL01', '002', 'PD', 250, 150, 100, 800, 7, 'X'),
('800', 'TEST_ANLZ_003', 'PL02', '003', 'PD', 300, 200, 200, 2000, 10, 'X'),
('800', 'TEST_ANLZ_004', 'PL01', '004', 'PD', 200, 120, 100, 600, 4, 'X');

-- =====================================================
-- TEST DATA FOR MD04 TABLE (MRP Requirements)
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
) VALUES 
-- TEST_ANLZ_001: Past due requirements (CRITICAL)
('800', 'TEST_ANLZ_001', 'PL01', 'MRP01', 'CU', DATEADD(day, -5, CURRENT_DATE),
 'PL001', 'PO001', 'RS001',
 150, 'EA', 0, 150,
 150, 0, 0, 0,
 '001', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', '001',
 'B', ''),

('800', 'TEST_ANLZ_001', 'PL01', 'MRP01', 'CU', DATEADD(day, 2, CURRENT_DATE),
 'PL002', 'PO002', 'RS002',
 100, 'EA', 0, 100,
 150, 0, 0, 0,
 '001', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', '001',
 'B', ''),

-- TEST_ANLZ_002: Next 7 days requirements (REORDER)
('800', 'TEST_ANLZ_002', 'PL01', 'MRP01', 'CU', DATEADD(day, 3, CURRENT_DATE),
 'PL003', 'PO003', 'RS003',
 120, 'EA', 0, 120,
 200, 0, 0, 0,
 '002', 'WB', 'E', NULL,
 0, 7, 'X',
 'SUP002', '002',
 'B', ''),

('800', 'TEST_ANLZ_002', 'PL01', 'MRP01', 'CU', DATEADD(day, 5, CURRENT_DATE),
 'PL004', 'PO004', 'RS004',
 100, 'EA', 0, 100,
 200, 0, 0, 0,
 '002', 'WB', 'E', NULL,
 0, 7, 'X',
 'SUP002', '002',
 'B', ''),

('800', 'TEST_ANLZ_002', 'PL01', 'MRP01', 'CU', DATEADD(day, 7, CURRENT_DATE),
 'PL005', 'PO005', 'RS005',
 80, 'EA', 0, 80,
 200, 0, 0, 0,
 '002', 'WB', 'E', NULL,
 0, 7, 'X',
 'SUP002', '002',
 'B', ''),

-- TEST_ANLZ_003: Future requirements (HEALTHY)
('800', 'TEST_ANLZ_003', 'PL02', 'MRP02', 'CU', DATEADD(day, 20, CURRENT_DATE),
 'PL006', 'PO006', 'RS006',
 300, 'KG', 0, 300,
 800, 0, 0, 0,
 '003', 'WB', 'E', NULL,
 0, 10, 'X',
 'SUP003', '003',
 'B', ''),

-- TEST_ANLZ_004: Next 7 days requirements with coverage gap
('800', 'TEST_ANLZ_004', 'PL01', 'MRP01', 'CU', DATEADD(day, 2, CURRENT_DATE),
 'PL007', 'PO007', 'RS007',
 150, 'EA', 0, 150,
 150, 0, 0, 0,
 '004', 'WB', 'E', NULL,
 0, 4, 'X',
 'SUP004', '004',
 'B', ''),

('800', 'TEST_ANLZ_004', 'PL01', 'MRP01', 'CU', DATEADD(day, 4, CURRENT_DATE),
 'PL008', 'PO008', 'RS008',
 120, 'EA', 0, 120,
 150, 0, 0, 0,
 '004', 'WB', 'E', NULL,
 0, 4, 'X',
 'SUP004', '004',
 'B', ''),

('800', 'TEST_ANLZ_004', 'PL01', 'MRP01', 'CU', DATEADD(day, 6, CURRENT_DATE),
 'PL009', 'PO009', 'RS009',
 100, 'EA', 0, 100,
 150, 0, 0, 0,
 '004', 'WB', 'E', NULL,
 0, 4, 'X',
 'SUP004', '004',
 'B', '');

-- =====================================================
-- TEST DATA FOR ME2N TABLE (Purchase Orders)
-- =====================================================

INSERT INTO SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.ME2N (
    EBELN, EBELP, LIFNR, NAME1, EKORG, EKGRP,
    MATNR, TXZ01, WERKS, LGORT,
    MENGE, MEINS, BSTMG, WEMNG, REMNG,
    BEDAT, EINDT, BSTYP, BSART,
    NETPR, PEINH, WAERS, BRTWR,
    LPEIN, LFMON, VRTKZ, VERSART,
    LOEKZ, STATU, MEMORY
) VALUES 
-- TEST_ANLZ_001: Overdue PO
('PO001', '0010', 'SUP001', 'Supplier A', 'ORG1', '001',
 'TEST_ANLZ_001', 'Analysis Test Material 1', 'PL01', 'ST01',
 200, 'EA', 200, 0, 200,
 DATEADD(day, -10, CURRENT_DATE), DATEADD(day, -3, CURRENT_DATE), 'F', 'NB',
 20.00, 1, 'USD', 4000.00,
 '7', '01', '', '',
 '', '1', ''),

-- TEST_ANLZ_002: Arriving in next 7 days
('PO002', '0010', 'SUP002', 'Supplier B', 'ORG1', '002',
 'TEST_ANLZ_002', 'Analysis Test Material 2', 'PL01', 'ST02',
 150, 'EA', 150, 0, 150,
 DATEADD(day, -5, CURRENT_DATE), DATEADD(day, 2, CURRENT_DATE), 'F', 'NB',
 18.00, 1, 'USD', 2700.00,
 '7', '01', '', '',
 '', '2', ''),

-- TEST_ANLZ_003: Future PO
('PO003', '0010', 'SUP003', 'Supplier C', 'ORG2', '003',
 'TEST_ANLZ_003', 'Analysis Test Material 3', 'PL02', 'ST03',
 500, 'KG', 500, 0, 500,
 DATEADD(day, -2, CURRENT_DATE), DATEADD(day, 15, CURRENT_DATE), 'F', 'NB',
 22.00, 1, 'USD', 11000.00,
 '17', '02', '', '',
 '', '2', ''),

-- TEST_ANLZ_004: Limited PO coverage (causing coverage gap)
('PO004', '0010', 'SUP004', 'Supplier D', 'ORG1', '004',
 'TEST_ANLZ_004', 'Analysis Test Material 4', 'PL01', 'ST04',
 100, 'EA', 100, 0, 100,
 DATEADD(day, -7, CURRENT_DATE), DATEADD(day, 8, CURRENT_DATE), 'F', 'NB',
 15.00, 1, 'USD', 1500.00,
 '15', '01', '', '',
 '', '2', ''),

-- Historical POs for supplier performance calculation
('PO005', '0010', 'SUP001', 'Supplier A', 'ORG1', '001',
 'TEST_ANLZ_001', 'Analysis Test Material 1', 'PL01', 'ST01',
 150, 'EA', 150, 150, 0,
 DATEADD(day, -60, CURRENT_DATE), DATEADD(day, -58, CURRENT_DATE), 'F', 'NB',
 20.00, 1, 'USD', 3000.00,
 '-2', '01', '', '',
 '', '3', ''),

('PO006', '0010', 'SUP001', 'Supplier A', 'ORG1', '001',
 'TEST_ANLZ_001', 'Analysis Test Material 1', 'PL01', 'ST01',
 180, 'EA', 180, 180, 0,
 DATEADD(day, -45, CURRENT_DATE), DATEADD(day, -45, CURRENT_DATE), 'F', 'NB',
 20.00, 1, 'USD', 3600.00,
 '0', '01', '', '',
 '', '3', ''),

('PO007', '0010', 'SUP001', 'Supplier A', 'ORG1', '001',
 'TEST_ANLZ_001', 'Analysis Test Material 1', 'PL01', 'ST01',
 200, 'EA', 200, 200, 0,
 DATEADD(day, -30, CURRENT_DATE), DATEADD(day, -32, CURRENT_DATE), 'F', 'NB',
 20.00, 1, 'USD', 4000.00,
 '-2', '01', '', '',
 '', '3', ''),

('PO008', '0010', 'SUP002', 'Supplier B', 'ORG1', '002',
 'TEST_ANLZ_002', 'Analysis Test Material 2', 'PL01', 'ST02',
 120, 'EA', 120, 100, 20,
 DATEADD(day, -90, CURRENT_DATE), DATEADD(day, -85, CURRENT_DATE), 'F', 'NB',
 18.00, 1, 'USD', 2160.00,
 '5', '01', '', '',
 '', '2', ''),

('PO009', '0010', 'SUP002', 'Supplier B', 'ORG1', '002',
 'TEST_ANLZ_002', 'Analysis Test Material 2', 'PL01', 'ST02',
 130, 'EA', 130, 130, 0,
 DATEADD(day, -70, CURRENT_DATE), DATEADD(day, -72, CURRENT_DATE), 'F', 'NB',
 18.00, 1, 'USD', 2340.00,
 '-2', '01', '', '',
 '', '3', ''),

('PO010', '0010', 'SUP002', 'Supplier B', 'ORG1', '002',
 'TEST_ANLZ_002', 'Analysis Test Material 2', 'PL01', 'ST02',
 140, 'EA', 140, 140, 0,
 DATEADD(day, -50, CURRENT_DATE), DATEADD(day, -48, CURRENT_DATE), 'F', 'NB',
 18.00, 1, 'USD', 2520.00,
 '2', '01', '', '',
 '', '3', ''),

('PO011', '0010', 'SUP003', 'Supplier C', 'ORG2', '003',
 'TEST_ANLZ_003', 'Analysis Test Material 3', 'PL02', 'ST03',
 400, 'KG', 400, 400, 0,
 DATEADD(day, -120, CURRENT_DATE), DATEADD(day, -122, CURRENT_DATE), 'F', 'NB',
 22.00, 1, 'USD', 8800.00,
 '-2', '02', '', '',
 '', '3', ''),

('PO012', '0010', 'SUP003', 'Supplier C', 'ORG2', '003',
 'TEST_ANLZ_003', 'Analysis Test Material 3', 'PL02', 'ST03',
 450, 'KG', 450, 450, 0,
 DATEADD(day, -90, CURRENT_DATE), DATEADD(day, -91, CURRENT_DATE), 'F', 'NB',
 22.00, 1, 'USD', 9900.00,
 '-1', '02', '', '',
 '', '3', ''),

('PO013', '0010', 'SUP003', 'Supplier C', 'ORG2', '003',
 'TEST_ANLZ_003', 'Analysis Test Material 3', 'PL02', 'ST03',
 500, 'KG', 500, 450, 50,
 DATEADD(day, -60, CURRENT_DATE), DATEADD(day, -55, CURRENT_DATE), 'F', 'NB',
 22.00, 1, 'USD', 11000.00,
 '5', '02', '', '',
 '', '2', '');

-- =====================================================
-- VERIFICATION - Check INVENTORY_SEMANTIC_VIEW for test data
-- =====================================================

SELECT 
    material_id,
    plant,
    current_stock,
    safety_stock,
    reorder_point,
    stock_status,
    supply_status,
    recommended_order_qty,
    supplier_confidence_score,
    past_due_requirements,
    overdue_po_qty,
    next_7_days_requirements,
    arriving_7_days_qty,
    avg_lead_time,
    reliability_score
FROM INVENTORY_SEMANTIC_VIEW 
WHERE material_id LIKE 'TEST_ANLZ_%'
ORDER BY material_id;

-- =====================================================
-- TEST THE ANALYZE_INVENTORY_STATUS FUNCTION
-- =====================================================

-- =====================================================
-- EXPECTED SCENARIOS SUMMARY
-- =====================================================
/*
| Material ID     | Plant | Current Stock | Stock Status | Supply Status | Expected Action                |
|-----------------|-------|---------------|--------------|---------------|--------------------------------|
| TEST_ANLZ_001   | PL01  | 10            | CRITICAL     | PAST_DUE      | ORDER_IMMEDIATELY: 290 units   |
| TEST_ANLZ_002   | PL01  | 200           | REORDER      | OK            | PLACE_ORDER: 100 units         |
| TEST_ANLZ_003   | PL02  | 800           | HEALTHY      | OK            | NO_ACTION                      |
| TEST_ANLZ_004   | PL01  | 150           | WATCH        | COVERAGE_GAP  | EXPEDITE_SUPPLY: Gap of 340 units |
*/

/*
-- Test individual materials
SELECT * FROM TABLE(analyze_inventory_status('TEST_ANLZ_001', 'PL01'));
SELECT * FROM TABLE(analyze_inventory_status('TEST_ANLZ_002', 'PL01'));
SELECT * FROM TABLE(analyze_inventory_status('TEST_ANLZ_003', 'PL02'));
SELECT * FROM TABLE(analyze_inventory_status('TEST_ANLZ_004', 'PL01'));

-- Test all materials (no filters)
SELECT * FROM TABLE(analyze_inventory_status()) 
WHERE material_id LIKE 'TEST_ANLZ_%'
ORDER BY material_id;
*/

-- =====================================================
-- TEST THE CREATE_AUTONOMOUS_PURCHASE_ORDER PROCEDURE
-- =====================================================

/*
-- Test CRITICAL scenario - should create PO
CALL create_autonomous_purchase_order(
    'TEST_ANLZ_001',
    'PL01',
    150,
    'SUP001',
    0.95,
    'Critical stock detected by analysis agent'
);

-- Test REORDER scenario
CALL create_autonomous_purchase_order(
    'TEST_ANLZ_002',
    'PL01',
    200,
    'SUP002',
    0.85,
    'Reorder point triggered'
);

-- Test COVERAGE_GAP scenario
CALL create_autonomous_purchase_order(
    'TEST_ANLZ_004',
    'PL01',
    120,
    'SUP004',
    0.70,
    'Coverage gap detected for next 7 days'
);

-- Check the audit log
SELECT * FROM agent_audit_log 
WHERE material_id LIKE 'TEST_ANLZ_%'
ORDER BY created_at DESC;

-- Check PO staging table - now with shorter PO numbers that fit in VARCHAR(20)
SELECT * FROM sap_po_staging 
WHERE material_id LIKE 'TEST_ANLZ_%'
ORDER BY created_at DESC;
*/



-- =====================================================
-- DELETE STATEMENT FOR TEST DATA
-- Run this to clean up all test data
-- =====================================================

/*
-- Delete from staging and audit tables first
DELETE FROM agent_audit_log WHERE material_id LIKE 'TEST_ANLZ_%';
DELETE FROM sap_po_staging WHERE material_id LIKE 'TEST_ANLZ_%';

-- Delete from source tables
DELETE FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.ME2N WHERE MATNR LIKE 'TEST_ANLZ_%';
DELETE FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 WHERE MATNR LIKE 'TEST_ANLZ_%';
DELETE FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MARC WHERE MATNR LIKE 'TEST_ANLZ_%';
DELETE FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MATDOC WHERE MATNR LIKE 'TEST_ANLZ_%';

-- Verify deletion
SELECT 'MATDOC' as table_name, COUNT(*) as remaining FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MATDOC WHERE MATNR LIKE 'TEST_ANLZ_%'
UNION ALL
SELECT 'MARC', COUNT(*) FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MARC WHERE MATNR LIKE 'TEST_ANLZ_%'
UNION ALL
SELECT 'MD04', COUNT(*) FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 WHERE MATNR LIKE 'TEST_ANLZ_%'
UNION ALL
SELECT 'ME2N', COUNT(*) FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.ME2N WHERE MATNR LIKE 'TEST_ANLZ_%'
UNION ALL
SELECT 'audit_log', COUNT(*) FROM agent_audit_log WHERE material_id LIKE 'TEST_ANLZ_%'
UNION ALL
SELECT 'po_staging', COUNT(*) FROM sap_po_staging WHERE material_id LIKE 'TEST_ANLZ_%';
*/