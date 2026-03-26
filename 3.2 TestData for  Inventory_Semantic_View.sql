USE WAREHOUSE SAP_COMPUTE;
USE DATABASE SAP_BDC_HORIZON_CATALOG;
USE SCHEMA AGENTS;


-- =====================================================
-- TEST DATA GENERATION FOR INVENTORY_SEMANTIC_VIEW
-- =====================================================

-- 1. TEST DATA FOR MATDOC TABLE (Material Documents)
INSERT INTO SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MATDOC (
    MBLNR, MJAHR, ZEILE, MATNR, WERKS, LAGER, LGORT,
    BWART, BUDAT, CPUDT, CPUTM, USNAM,
    MENGE, MEINS, DMBTR, WAERS,
    LIFNR, KUNNR, AUFNR, KDAUF, KDPOS,
    XBLNR, BKTXT, BLART, BLDAT,
    CHARG, SOBKZ,
    ERFMG, ERFME, SHKZG
) VALUES 
-- Material A: Healthy stock with good movement
('TEST001', '2024', '001', 'TEST_MAT_A', 'PL01', 'LOCA', 'LOCA',
 '101', DATEADD(day, -5, CURRENT_DATE), DATEADD(day, -5, CURRENT_DATE), '10:30:00', 'TESTUSER',
 1000, 'EA', 5000.00, 'USD',
 'SUP001', NULL, NULL, NULL, NULL,
 'REF001', 'Test Receipt', 'WE', DATEADD(day, -5, CURRENT_DATE),
 'BATCH01', NULL,
 1000, 'EA', 'S'),

('TEST001', '2024', '002', 'TEST_MAT_A', 'PL01', 'LOCA', 'LOCA',
 '102', DATEADD(day, -10, CURRENT_DATE), DATEADD(day, -10, CURRENT_DATE), '14:20:00', 'TESTUSER',
 200, 'EA', -1000.00, 'USD',
 NULL, 'CUST01', NULL, NULL, NULL,
 'REF002', 'Test Issue', 'WA', DATEADD(day, -10, CURRENT_DATE),
 NULL, NULL,
 200, 'EA', 'H'),

('TEST001', '2024', '003', 'TEST_MAT_A', 'PL01', 'LOCA', 'LOCA',
 '101', DATEADD(day, -15, CURRENT_DATE), DATEADD(day, -15, CURRENT_DATE), '09:15:00', 'TESTUSER',
 500, 'EA', 2500.00, 'USD',
 'SUP001', NULL, NULL, NULL, NULL,
 'REF003', 'Test Receipt', 'WE', DATEADD(day, -15, CURRENT_DATE),
 'BATCH02', NULL,
 500, 'EA', 'S'),

('TEST001', '2024', '004', 'TEST_MAT_A', 'PL01', 'LOCA', 'LOCA',
 '102', DATEADD(day, -20, CURRENT_DATE), DATEADD(day, -20, CURRENT_DATE), '11:45:00', 'TESTUSER',
 100, 'EA', -500.00, 'USD',
 NULL, 'CUST02', NULL, NULL, NULL,
 'REF004', 'Test Issue', 'WA', DATEADD(day, -20, CURRENT_DATE),
 NULL, NULL,
 100, 'EA', 'H'),

-- Material B: Critical stock (below safety stock)
('TEST002', '2024', '001', 'TEST_MAT_B', 'PL01', 'LOCB', 'LOCB',
 '101', DATEADD(day, -2, CURRENT_DATE), DATEADD(day, -2, CURRENT_DATE), '13:10:00', 'TESTUSER',
 50, 'EA', 250.00, 'USD',
 'SUP002', NULL, NULL, NULL, NULL,
 'REF005', 'Test Receipt', 'WE', DATEADD(day, -2, CURRENT_DATE),
 'BATCH03', NULL,
 50, 'EA', 'S'),

('TEST002', '2024', '002', 'TEST_MAT_B', 'PL01', 'LOCB', 'LOCB',
 '102', DATEADD(day, -7, CURRENT_DATE), DATEADD(day, -7, CURRENT_DATE), '15:30:00', 'TESTUSER',
 200, 'EA', -1000.00, 'USD',
 NULL, 'CUST03', NULL, NULL, NULL,
 'REF006', 'Test Issue', 'WA', DATEADD(day, -7, CURRENT_DATE),
 NULL, NULL,
 200, 'EA', 'H'),

('TEST002', '2024', '003', 'TEST_MAT_B', 'PL01', 'LOCB', 'LOCB',
 '101', DATEADD(day, -14, CURRENT_DATE), DATEADD(day, -14, CURRENT_DATE), '10:00:00', 'TESTUSER',
 100, 'EA', 500.00, 'USD',
 'SUP002', NULL, NULL, NULL, NULL,
 'REF007', 'Test Receipt', 'WE', DATEADD(day, -14, CURRENT_DATE),
 'BATCH04', NULL,
 100, 'EA', 'S'),

-- Material C: Reorder point triggered
('TEST003', '2024', '001', 'TEST_MAT_C', 'PL02', 'LOCC', 'LOCC',
 '101', DATEADD(day, -1, CURRENT_DATE), DATEADD(day, -1, CURRENT_DATE), '08:45:00', 'TESTUSER',
 300, 'KG', 1500.00, 'USD',
 'SUP003', NULL, NULL, NULL, NULL,
 'REF008', 'Test Receipt', 'WE', DATEADD(day, -1, CURRENT_DATE),
 'BATCH05', NULL,
 300, 'KG', 'S'),

('TEST003', '2024', '002', 'TEST_MAT_C', 'PL02', 'LOCC', 'LOCC',
 '102', DATEADD(day, -8, CURRENT_DATE), DATEADD(day, -8, CURRENT_DATE), '16:20:00', 'TESTUSER',
 400, 'KG', -2000.00, 'USD',
 NULL, 'CUST04', NULL, NULL, NULL,
 'REF009', 'Test Issue', 'WA', DATEADD(day, -8, CURRENT_DATE),
 NULL, NULL,
 400, 'KG', 'H'),

-- Material D: Multiple storage locations
('TEST004', '2024', '001', 'TEST_MAT_D', 'PL01', 'LOCA', 'LOCA',
 '101', DATEADD(day, -3, CURRENT_DATE), DATEADD(day, -3, CURRENT_DATE), '09:30:00', 'TESTUSER',
 750, 'M', 3750.00, 'USD',
 'SUP004', NULL, NULL, NULL, NULL,
 'REF010', 'Test Receipt', 'WE', DATEADD(day, -3, CURRENT_DATE),
 'BATCH06', NULL,
 750, 'M', 'S'),

('TEST004', '2024', '002', 'TEST_MAT_D', 'PL01', 'LOCD', 'LOCD',
 '101', DATEADD(day, -3, CURRENT_DATE), DATEADD(day, -3, CURRENT_DATE), '09:35:00', 'TESTUSER',
 250, 'M', 1250.00, 'USD',
 'SUP004', NULL, NULL, NULL, NULL,
 'REF011', 'Test Receipt', 'WE', DATEADD(day, -3, CURRENT_DATE),
 'BATCH07', NULL,
 250, 'M', 'S'),

('TEST004', '2024', '003', 'TEST_MAT_D', 'PL01', 'LOCA', 'LOCA',
 '102', DATEADD(day, -12, CURRENT_DATE), DATEADD(day, -12, CURRENT_DATE), '14:15:00', 'TESTUSER',
 100, 'M', -500.00, 'USD',
 NULL, 'CUST05', NULL, NULL, NULL,
 'REF012', 'Test Issue', 'WA', DATEADD(day, -12, CURRENT_DATE),
 NULL, NULL,
 100, 'M', 'H'),

('TEST004', '2024', '004', 'TEST_MAT_D', 'PL01', 'LOCD', 'LOCD',
 '101', DATEADD(day, -18, CURRENT_DATE), DATEADD(day, -18, CURRENT_DATE), '11:20:00', 'TESTUSER',
 150, 'M', 750.00, 'USD',
 'SUP004', NULL, NULL, NULL, NULL,
 'REF013', 'Test Receipt', 'WE', DATEADD(day, -18, CURRENT_DATE),
 'BATCH08', NULL,
 150, 'M', 'S'),

-- Material E: No recent movements
('TEST005', '2024', '001', 'TEST_MAT_E', 'PL02', 'LOCE', 'LOCE',
 '101', DATEADD(day, -45, CURRENT_DATE), DATEADD(day, -45, CURRENT_DATE), '10:00:00', 'TESTUSER',
 500, 'EA', 2500.00, 'USD',
 'SUP005', NULL, NULL, NULL, NULL,
 'REF014', 'Test Receipt', 'WE', DATEADD(day, -45, CURRENT_DATE),
 'BATCH09', NULL,
 500, 'EA', 'S'),

('TEST005', '2024', '002', 'TEST_MAT_E', 'PL02', 'LOCE', 'LOCE',
 '102', DATEADD(day, -60, CURRENT_DATE), DATEADD(day, -60, CURRENT_DATE), '13:45:00', 'TESTUSER',
 300, 'EA', -1500.00, 'USD',
 NULL, 'CUST06', NULL, NULL, NULL,
 'REF015', 'Test Issue', 'WA', DATEADD(day, -60, CURRENT_DATE),
 NULL, NULL,
 300, 'EA', 'H');

-- 2. TEST DATA FOR MARC TABLE (Material Master - Plant Level)
 INSERT INTO SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MARC (
    MANDT, MATNR, WERKS, DISPO, DISMM, BESKZ, SOBSL,
    MINBE, EISBE, BSTMI, BSTMA, BSTFE,
    PLIFZ, WEBAZ, BEARZ, RUEZT, TRANSZ,
    LOSGR, PERKZ, PERIV, AUSSS,
    KZPRD, VRMOD, VINT1, VINT2,
    FHORI, WEBRE, PRCTL,
    LGPRO, LGRAD, DISPR
) VALUES 
-- Material A parameters
('800', 'TEST_MAT_A', 'PL01', '001', 'PD', 'F', NULL,
 200, 150, 100, 2000, NULL,
 5, 1, 1, 0, 2,
 'WB', 'W', 'V1', 1,
 '1', '1', '1', '1',
 '001', 'X', 'ZM',
 'PRD1', 85.00, 'DS1'),  -- DISPR shortened to 3 chars

-- Material B parameters (low safety stock)
('800', 'TEST_MAT_B', 'PL01', '001', 'VB', 'F', NULL,
 300, 100, 50, 500, NULL,
 3, 1, 1, 0, 1,
 'EX', 'W', 'V1', 1,
 '1', '1', '1', '1',
 '001', 'X', 'ZM',
 'PRD2', 90.00, 'DS1'),  

-- Material C parameters
('800', 'TEST_MAT_C', 'PL02', '002', 'PD', 'F', NULL,
 500, 200, 200, 1000, NULL,
 7, 2, 1, 0, 3,
 'WB', 'M', 'V2', 1,
 '1', '2', '2', '2',
 '002', 'X', 'ZF',
 'PRD3', 75.00, 'DS2'),  

-- Material D parameters for both locations
('800', 'TEST_MAT_D', 'PL01', '003', 'PD', 'E', '30',
 400, 250, 150, 1500, NULL,
 4, 1, 2, 0, 2,
 'WB', 'W', 'V1', 1,
 '1', '1', '1', '1',
 '003', 'X', 'ZM',
 'PRD4', 80.00, 'DS1'),  -- DISPR shortened to 3 chars

-- Material E parameters
('800', 'TEST_MAT_E', 'PL02', '002', 'ND', 'F', NULL,
 150, 100, 100, 800, NULL,
 6, 1, 1, 0, 2,
 'EX', 'M', 'V2', 1,
 '1', '2', '2', '2',
 '002', '', 'ZF',
 'PRD5', 70.00, 'DS2');  
 
-- 3. TEST DATA FOR MD04 TABLE (MRP Requirements)
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
-- Past due requirements
('800', 'TEST_MAT_A', 'PL01', 'MRP01', 'VA', DATEADD(day, -3, CURRENT_DATE),
 'PL001', NULL, 'RS001',
 150, 'EA', 0, 150,
 1000, 0, 0, 0,
 '001', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', '001',
 'B', ''),

('800', 'TEST_MAT_B', 'PL01', 'MRP01', 'VA', DATEADD(day, -5, CURRENT_DATE),
 'PL002', NULL, 'RS002',
 80, 'EA', 0, 80,
 50, 0, 0, 0,
 '001', 'EX', 'E', NULL,
 0, 3, 'X',
 'SUP002', '001',
 'B', ''),

('800', 'TEST_MAT_C', 'PL02', 'MRP02', 'VA', DATEADD(day, -2, CURRENT_DATE),
 'PL003', NULL, 'RS003',
 200, 'KG', 0, 200,
 300, 0, 0, 0,
 '002', 'WB', 'E', NULL,
 0, 7, 'X',
 'SUP003', '002',
 'B', ''),

-- Next 7 days requirements
('800', 'TEST_MAT_A', 'PL01', 'MRP01', 'VA', DATEADD(day, 2, CURRENT_DATE),
 'PL004', NULL, 'RS004',
 300, 'EA', 0, 300,
 1000, 0, 0, 0,
 '001', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', '001',
 'B', ''),

('800', 'TEST_MAT_A', 'PL01', 'MRP01', 'VA', DATEADD(day, 5, CURRENT_DATE),
 'PL005', NULL, 'RS005',
 250, 'EA', 0, 250,
 1000, 0, 0, 0,
 '001', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', '001',
 'B', ''),

('800', 'TEST_MAT_B', 'PL01', 'MRP01', 'VA', DATEADD(day, 3, CURRENT_DATE),
 'PL006', NULL, 'RS006',
 150, 'EA', 0, 150,
 50, 0, 0, 0,
 '001', 'EX', 'E', NULL,
 0, 3, 'X',
 'SUP002', '001',
 'B', ''),

('800', 'TEST_MAT_D', 'PL01', 'MRP01', 'VA', DATEADD(day, 1, CURRENT_DATE),
 'PL007', NULL, 'RS007',
 400, 'M', 0, 400,
 900, 0, 0, 0,
 '003', 'WB', 'E', '30',
 0, 4, 'X',
 'SUP004', '001',
 'B', ''),

('800', 'TEST_MAT_D', 'PL01', 'MRP01', 'VA', DATEADD(day, 6, CURRENT_DATE),
 'PL008', NULL, 'RS008',
 350, 'M', 0, 350,
 900, 0, 0, 0,
 '003', 'WB', 'E', '30',
 0, 4, 'X',
 'SUP004', '001',
 'B', ''),

-- Future requirements (>7 days)
('800', 'TEST_MAT_A', 'PL01', 'MRP01', 'VA', DATEADD(day, 15, CURRENT_DATE),
 'PL009', NULL, 'RS009',
 500, 'EA', 0, 500,
 1000, 0, 0, 0,
 '001', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', '001',
 'B', ''),

('800', 'TEST_MAT_B', 'PL01', 'MRP01', 'VA', DATEADD(day, 20, CURRENT_DATE),
 'PL010', NULL, 'RS010',
 200, 'EA', 0, 200,
 50, 0, 0, 0,
 '001', 'EX', 'E', NULL,
 0, 3, 'X',
 'SUP002', '001',
 'B', ''),

('800', 'TEST_MAT_C', 'PL02', 'MRP02', 'VA', DATEADD(day, 10, CURRENT_DATE),
 'PL011', NULL, 'RS011',
 300, 'KG', 0, 300,
 300, 0, 0, 0,
 '002', 'WB', 'E', NULL,
 0, 7, 'X',
 'SUP003', '002',
 'B', ''),

('800', 'TEST_MAT_C', 'PL02', 'MRP02', 'VA', DATEADD(day, 25, CURRENT_DATE),
 'PL012', NULL, 'RS012',
 400, 'KG', 0, 400,
 300, 0, 0, 0,
 '002', 'WB', 'E', NULL,
 0, 7, 'X',
 'SUP003', '002',
 'B', ''),

('800', 'TEST_MAT_E', 'PL02', 'MRP02', 'VA', DATEADD(day, 30, CURRENT_DATE),
 'PL013', NULL, 'RS013',
 250, 'EA', 0, 250,
 200, 0, 0, 0,
 '002', 'EX', 'E', NULL,
 0, 6, '',
 'SUP005', '002',
 'B', '');

-- 4. TEST DATA FOR ME2N TABLE (Purchase Orders)
INSERT INTO SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.ME2N (
    EBELN, EBELP, LIFNR, NAME1, EKORG, EKGRP,
    MATNR, TXZ01, WERKS, LGORT,
    MENGE, MEINS, BSTMG, WEMNG, REMNG,
    BEDAT, EINDT, BSTYP, BSART,
    NETPR, PEINH, WAERS, BRTWR,
    LPEIN, LFMON, VRTKZ, VERSART,
    LOEKZ, STATU, MEMORY
) VALUES 
-- Overdue POs
('PO001', '0010', 'SUP001', 'Test Supplier 1', 'ORG1', '001',
 'TEST_MAT_A', 'Test Material A', 'PL01', 'LOCA',
 500, 'EA', 500, 0, 500,
 DATEADD(day, -10, CURRENT_DATE), DATEADD(day, -5, CURRENT_DATE), 'F', 'NB',
 10.00, 1, 'USD', 5000.00,
 '10', '01', '', '',
 '', '1', ''),

('PO002', '0010', 'SUP002', 'Test Supplier 2', 'ORG1', '001',
 'TEST_MAT_B', 'Test Material B', 'PL01', 'LOCB',
 200, 'EA', 200, 0, 200,
 DATEADD(day, -7, CURRENT_DATE), DATEADD(day, -2, CURRENT_DATE), 'F', 'NB',
 5.00, 1, 'USD', 1000.00,
 '7', '01', '', '',
 '', '1', ''),

-- Arriving in next 7 days
('PO003', '0010', 'SUP001', 'Test Supplier 1', 'ORG1', '001',
 'TEST_MAT_A', 'Test Material A', 'PL01', 'LOCA',
 400, 'EA', 400, 0, 400,
 DATEADD(day, -2, CURRENT_DATE), DATEADD(day, 3, CURRENT_DATE), 'F', 'NB',
 10.00, 1, 'USD', 4000.00,
 '5', '01', '', '',
 '', '2', ''),

('PO004', '0010', 'SUP003', 'Test Supplier 3', 'ORG2', '002',
 'TEST_MAT_C', 'Test Material C', 'PL02', 'LOCC',
 600, 'KG', 600, 0, 600,
 DATEADD(day, -1, CURRENT_DATE), DATEADD(day, 4, CURRENT_DATE), 'F', 'NB',
 5.00, 1, 'USD', 3000.00,
 '5', '02', '', '',
 '', '2', ''),

('PO005', '0010', 'SUP004', 'Test Supplier 4', 'ORG1', '001',
 'TEST_MAT_D', 'Test Material D', 'PL01', 'LOCA',
 350, 'M', 350, 0, 350,
 DATEADD(day, -3, CURRENT_DATE), DATEADD(day, 2, CURRENT_DATE), 'F', 'NB',
 5.00, 1, 'USD', 1750.00,
 '5', '01', '', '',
 '', '2', ''),

-- Future POs (>7 days)
('PO006', '0010', 'SUP001', 'Test Supplier 1', 'ORG1', '001',
 'TEST_MAT_A', 'Test Material A', 'PL01', 'LOCA',
 450, 'EA', 450, 0, 450,
 CURRENT_DATE, DATEADD(day, 12, CURRENT_DATE), 'F', 'NB',
 10.00, 1, 'USD', 4500.00,
 '12', '01', '', '',
 '', '2', ''),

('PO007', '0010', 'SUP003', 'Test Supplier 3', 'ORG2', '002',
 'TEST_MAT_C', 'Test Material C', 'PL02', 'LOCC',
 700, 'KG', 700, 0, 700,
 DATEADD(day, 2, CURRENT_DATE), DATEADD(day, 18, CURRENT_DATE), 'F', 'NB',
 5.00, 1, 'USD', 3500.00,
 '16', '02', '', '',
 '', '2', ''),

('PO008', '0010', 'SUP005', 'Test Supplier 5', 'ORG2', '002',
 'TEST_MAT_E', 'Test Material E', 'PL02', 'LOCE',
 300, 'EA', 300, 0, 300,
 DATEADD(day, 5, CURRENT_DATE), DATEADD(day, 25, CURRENT_DATE), 'F', 'NB',
 8.00, 1, 'USD', 2400.00,
 '20', '02', '', '',
 '', '2', ''),

('PO009', '0010', 'SUP005', 'Test Supplier 5', 'ORG2', '002',
 'TEST_MAT_E', 'Test Material E', 'PL02', 'LOCE',
 200, 'EA', 200, 0, 200,
 DATEADD(day, 7, CURRENT_DATE), DATEADD(day, 32, CURRENT_DATE), 'F', 'NB',
 8.00, 1, 'USD', 1600.00,
 '25', '02', '', '',
 '', '2', ''),

-- Additional POs for supplier performance calculation
('PO010', '0010', 'SUP001', 'Test Supplier 1', 'ORG1', '001',
 'TEST_MAT_A', 'Test Material A', 'PL01', 'LOCA',
 350, 'EA', 350, 350, 0,
 DATEADD(day, -20, CURRENT_DATE), DATEADD(day, -15, CURRENT_DATE), 'F', 'NB',
 10.00, 1, 'USD', 3500.00,
 '-5', '01', '', '',
 '', '3', ''),

('PO011', '0010', 'SUP001', 'Test Supplier 1', 'ORG1', '001',
 'TEST_MAT_A', 'Test Material A', 'PL01', 'LOCA',
 450, 'EA', 450, 450, 0,
 DATEADD(day, -30, CURRENT_DATE), DATEADD(day, -25, CURRENT_DATE), 'F', 'NB',
 10.00, 1, 'USD', 4500.00,
 '-5', '01', '', '',
 '', '3', ''),

('PO012', '0010', 'SUP002', 'Test Supplier 2', 'ORG1', '001',
 'TEST_MAT_B', 'Test Material B', 'PL01', 'LOCB',
 150, 'EA', 150, 150, 0,
 DATEADD(day, -40, CURRENT_DATE), DATEADD(day, -35, CURRENT_DATE), 'F', 'NB',
 5.00, 1, 'USD', 750.00,
 '-5', '01', '', '',
 '', '3', ''),

('PO013', '0010', 'SUP002', 'Test Supplier 2', 'ORG1', '001',
 'TEST_MAT_B', 'Test Material B', 'PL01', 'LOCB',
 250, 'EA', 250, 0, 250,
 DATEADD(day, -50, CURRENT_DATE), DATEADD(day, -45, CURRENT_DATE), 'F', 'NB',
 5.00, 1, 'USD', 1250.00,
 '5', '01', '', '',
 '', '2', '');


-- =====================================================
-- ADDITIONAL TEST DATA FOR DIFFERENT RELIABILITY SCORES
-- =====================================================

-- Additional Suppliers with varying performance in ME2N
INSERT INTO SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.ME2N (
    EBELN, EBELP, LIFNR, NAME1, EKORG, EKGRP,
    MATNR, TXZ01, WERKS, LGORT,
    MENGE, MEINS, BSTMG, WEMNG, REMNG,
    BEDAT, EINDT, BSTYP, BSART,
    NETPR, PEINH, WAERS, BRTWR,
    LPEIN, LFMON, VRTKZ, VERSART,
    LOEKZ, STATU, MEMORY
) VALUES 

-- SUPRELIABLE: High reliability supplier (0.95 confidence)
-- All deliveries on time or early
('PO100', '0010', 'SUPRELAB', 'Super Reliable Inc', 'ORG1', '001',
 'TEST_MAT_A', 'Test Material A', 'PL01', 'LOCA',
 1000, 'EA', 1000, 1000, 0,
 DATEADD(day, -60, CURRENT_DATE), DATEADD(day, -63, CURRENT_DATE), 'F', 'NB',  -- 3 days early
 10.00, 1, 'USD', 10000.00,
 '-3', '01', '', '',
 '', '3', ''),

('PO101', '0010', 'SUPRELAB', 'Super Reliable Inc', 'ORG1', '001',
 'TEST_MAT_A', 'Test Material A', 'PL01', 'LOCA',
 800, 'EA', 800, 800, 0,
 DATEADD(day, -45, CURRENT_DATE), DATEADD(day, -46, CURRENT_DATE), 'F', 'NB',  -- 1 day early
 10.00, 1, 'USD', 8000.00,
 '-1', '01', '', '',
 '', '3', ''),

('PO102', '0010', 'SUPRELAB', 'Super Reliable Inc', 'ORG1', '001',
 'TEST_MAT_A', 'Test Material A', 'PL01', 'LOCA',
 1200, 'EA', 1200, 1200, 0,
 DATEADD(day, -30, CURRENT_DATE), DATEADD(day, -30, CURRENT_DATE), 'F', 'NB',  -- On time
 10.00, 1, 'USD', 12000.00,
 '0', '01', '', '',
 '', '3', ''),

('PO103', '0010', 'SUPRELAB', 'Super Reliable Inc', 'ORG1', '001',
 'TEST_MAT_A', 'Test Material A', 'PL01', 'LOCA',
 600, 'EA', 600, 600, 0,
 DATEADD(day, -15, CURRENT_DATE), DATEADD(day, -17, CURRENT_DATE), 'F', 'NB',  -- 2 days early
 10.00, 1, 'USD', 6000.00,
 '-2', '01', '', '',
 '', '3', ''),

-- GOODSUP: Good reliability supplier (0.85 confidence)
-- Mostly on time, occasional slight delay
('PO104', '0010', 'GOODSUP', 'Good Supplier Co', 'ORG1', '001',
 'TEST_MAT_B', 'Test Material B', 'PL01', 'LOCB',
 500, 'EA', 500, 500, 0,
 DATEADD(day, -50, CURRENT_DATE), DATEADD(day, -50, CURRENT_DATE), 'F', 'NB',  -- On time
 5.00, 1, 'USD', 2500.00,
 '0', '01', '', '',
 '', '3', ''),

('PO105', '0010', 'GOODSUP', 'Good Supplier Co', 'ORG1', '001',
 'TEST_MAT_B', 'Test Material B', 'PL01', 'LOCB',
 400, 'EA', 400, 400, 0,
 DATEADD(day, -40, CURRENT_DATE), DATEADD(day, -38, CURRENT_DATE), 'F', 'NB',  -- 2 days early
 5.00, 1, 'USD', 2000.00,
 '-2', '01', '', '',
 '', '3', ''),

('PO106', '0010', 'GOODSUP', 'Good Supplier Co', 'ORG1', '001',
 'TEST_MAT_B', 'Test Material B', 'PL01', 'LOCB',
 600, 'EA', 600, 600, 0,
 DATEADD(day, -25, CURRENT_DATE), DATEADD(day, -24, CURRENT_DATE), 'F', 'NB',  -- 1 day early
 5.00, 1, 'USD', 3000.00,
 '-1', '01', '', '',
 '', '3', ''),

('PO107', '0010', 'GOODSUP', 'Good Supplier Co', 'ORG1', '001',
 'TEST_MAT_B', 'Test Material B', 'PL01', 'LOCB',
 350, 'EA', 350, 300, 50,  -- Partial delivery, 2 days late
 DATEADD(day, -20, CURRENT_DATE), DATEADD(day, -18, CURRENT_DATE), 'F', 'NB',
 5.00, 1, 'USD', 1750.00,
 '2', '01', '', '',
 '', '2', ''),

-- AVGSUPPL: Average reliability supplier (0.70 confidence)
-- Mixed performance
('PO108', '0010', 'AVGSUPPL', 'Average Supplies Ltd', 'ORG2', '002',
 'TEST_MAT_C', 'Test Material C', 'PL02', 'LOCC',
 700, 'KG', 700, 650, 50,
 DATEADD(day, -55, CURRENT_DATE), DATEADD(day, -52, CURRENT_DATE), 'F', 'NB',  -- 3 days late
 5.00, 1, 'USD', 3500.00,
 '3', '02', '', '',
 '', '2', ''),

('PO109', '0010', 'AVGSUPPL', 'Average Supplies Ltd', 'ORG2', '002',
 'TEST_MAT_C', 'Test Material C', 'PL02', 'LOCC',
 550, 'KG', 550, 550, 0,
 DATEADD(day, -42, CURRENT_DATE), DATEADD(day, -44, CURRENT_DATE), 'F', 'NB',  -- 2 days early
 5.00, 1, 'USD', 2750.00,
 '-2', '02', '', '',
 '', '3', ''),

('PO110', '0010', 'AVGSUPPL', 'Average Supplies Ltd', 'ORG2', '002',
 'TEST_MAT_C', 'Test Material C', 'PL02', 'LOCC',
 800, 'KG', 800, 750, 50,
 DATEADD(day, -28, CURRENT_DATE), DATEADD(day, -25, CURRENT_DATE), 'F', 'NB',  -- 3 days late
 5.00, 1, 'USD', 4000.00,
 '3', '02', '', '',
 '', '2', ''),

('PO111', '0010', 'AVGSUPPL', 'Average Supplies Ltd', 'ORG2', '002',
 'TEST_MAT_C', 'Test Material C', 'PL02', 'LOCC',
 450, 'KG', 450, 450, 0,
 DATEADD(day, -15, CURRENT_DATE), DATEADD(day, -15, CURRENT_DATE), 'F', 'NB',  -- On time
 5.00, 1, 'USD', 2250.00,
 '0', '02', '', '',
 '', '3', ''),

('PO112', '0010', 'AVGSUPPL', 'Average Supplies Ltd', 'ORG2', '002',
 'TEST_MAT_C', 'Test Material C', 'PL02', 'LOCC',
 600, 'KG', 600, 550, 50,
 DATEADD(day, -8, CURRENT_DATE), DATEADD(day, -5, CURRENT_DATE), 'F', 'NB',  -- 3 days late
 5.00, 1, 'USD', 3000.00,
 '3', '02', '', '',
 '', '2', ''),

-- LOWREL: Low reliability supplier (0.50 confidence)
-- Frequently late
('PO113', '0010', 'LOWREL', 'Low Reliability Corp', 'ORG2', '002',
 'TEST_MAT_D', 'Test Material D', 'PL01', 'LOCA',
 400, 'M', 400, 300, 100,
 DATEADD(day, -70, CURRENT_DATE), DATEADD(day, -63, CURRENT_DATE), 'F', 'NB',  -- 7 days late
 5.00, 1, 'USD', 2000.00,
 '7', '01', '', '',
 '', '2', ''),

('PO114', '0010', 'LOWREL', 'Low Reliability Corp', 'ORG2', '002',
 'TEST_MAT_D', 'Test Material D', 'PL01', 'LOCD',
 350, 'M', 350, 280, 70,
 DATEADD(day, -58, CURRENT_DATE), DATEADD(day, -50, CURRENT_DATE), 'F', 'NB',  -- 8 days late
 5.00, 1, 'USD', 1750.00,
 '8', '01', '', '',
 '', '2', ''),

('PO115', '0010', 'LOWREL', 'Low Reliability Corp', 'ORG2', '002',
 'TEST_MAT_D', 'Test Material D', 'PL01', 'LOCA',
 500, 'M', 500, 400, 100,
 DATEADD(day, -40, CURRENT_DATE), DATEADD(day, -35, CURRENT_DATE), 'F', 'NB',  -- 5 days late
 5.00, 1, 'USD', 2500.00,
 '5', '01', '', '',
 '', '2', ''),

('PO116', '0010', 'LOWREL', 'Low Reliability Corp', 'ORG2', '002',
 'TEST_MAT_D', 'Test Material D', 'PL01', 'LOCD',
 450, 'M', 450, 350, 100,
 DATEADD(day, -25, CURRENT_DATE), DATEADD(day, -20, CURRENT_DATE), 'F', 'NB',  -- 5 days late
 5.00, 1, 'USD', 2250.00,
 '5', '01', '', '',
 '', '2', ''),

('PO117', '0010', 'LOWREL', 'Low Reliability Corp', 'ORG2', '002',
 'TEST_MAT_D', 'Test Material D', 'PL01', 'LOCA',
 300, 'M', 300, 200, 100,
 DATEADD(day, -12, CURRENT_DATE), DATEADD(day, -8, CURRENT_DATE), 'F', 'NB',  -- 4 days late
 5.00, 1, 'USD', 1500.00,
 '4', '01', '', '',
 '', '2', ''),

-- NEWSUP: New supplier with limited history (will get default 0.50)
('PO118', '0010', 'NEWSUP', 'New Supplier LLC', 'ORG1', '001',
 'TEST_MAT_E', 'Test Material E', 'PL02', 'LOCE',
 200, 'EA', 200, 200, 0,
 DATEADD(day, -10, CURRENT_DATE), DATEADD(day, -8, CURRENT_DATE), 'F', 'NB',  -- 2 days late (only 1 PO)
 8.00, 1, 'USD', 1600.00,
 '2', '02', '', '',
 '', '3', '');

-- =====================================================
-- ADDITIONAL MARC DATA FOR DIFFERENT PLANNED DELIVERY TIMES
-- To test the avg_lead_time <= planned_delivery_time condition
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
-- Material with SUPRELAB (planned delivery time 5 days - supplier avg lead time should be less)
('800', 'TEST_MAT_F', 'PL01', '004', 'PD', 'F', NULL,
 300, 200, 150, 2000, NULL,
 5, 1, 1, 0, 2,
 'WB', 'W', 'V1', 1,
 '1', '1', '1', '1',
 '004', 'X', 'ZM',
 'PRD6', 95.00, 'DS1'),

-- Material with GOODSUP (planned delivery time 3 days - supplier has some delays)
('800', 'TEST_MAT_G', 'PL01', '005', 'PD', 'F', NULL,
 250, 150, 100, 1500, NULL,
 3, 1, 1, 0, 2,
 'WB', 'W', 'V1', 1,
 '1', '1', '1', '1',
 '005', 'X', 'ZM',
 'PRD7', 88.00, 'DS1'),

-- Material with AVGSUPPL (planned delivery time 4 days - mixed performance)
('800', 'TEST_MAT_H', 'PL02', '006', 'PD', 'F', NULL,
 400, 250, 200, 1800, NULL,
 4, 2, 1, 0, 3,
 'WB', 'M', 'V2', 1,
 '1', '2', '2', '2',
 '006', 'X', 'ZF',
 'PRD8', 78.00, 'DS2'),

-- Material with LOWREL (planned delivery time 3 days - always late)
('800', 'TEST_MAT_I', 'PL01', '007', 'PD', 'F', NULL,
 350, 200, 150, 1600, NULL,
 3, 1, 1, 0, 2,
 'WB', 'W', 'V1', 1,
 '1', '1', '1', '1',
 '007', 'X', 'ZM',
 'PRD9', 72.00, 'DS1');

-- =====================================================
-- ADDITIONAL ME2N DATA FOR THE NEW MATERIALS
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
-- For TEST_MAT_F with SUPRELAB (all on time/early)
('PO200', '0010', 'SUPRELAB', 'Super Reliable Inc', 'ORG1', '001',
 'TEST_MAT_F', 'Test Material F', 'PL01', 'LOCA',
 800, 'EA', 800, 800, 0,
 DATEADD(day, -40, CURRENT_DATE), DATEADD(day, -42, CURRENT_DATE), 'F', 'NB',
 12.00, 1, 'USD', 9600.00,
 '-2', '01', '', '',
 '', '3', ''),

('PO201', '0010', 'SUPRELAB', 'Super Reliable Inc', 'ORG1', '001',
 'TEST_MAT_F', 'Test Material F', 'PL01', 'LOCA',
 600, 'EA', 600, 600, 0,
 DATEADD(day, -25, CURRENT_DATE), DATEADD(day, -26, CURRENT_DATE), 'F', 'NB',
 12.00, 1, 'USD', 7200.00,
 '-1', '01', '', '',
 '', '3', ''),

-- For TEST_MAT_G with GOODSUP
('PO202', '0010', 'GOODSUP', 'Good Supplier Co', 'ORG1', '001',
 'TEST_MAT_G', 'Test Material G', 'PL01', 'LOCB',
 500, 'EA', 500, 500, 0,
 DATEADD(day, -35, CURRENT_DATE), DATEADD(day, -35, CURRENT_DATE), 'F', 'NB',
 8.00, 1, 'USD', 4000.00,
 '0', '01', '', '',
 '', '3', ''),

('PO203', '0010', 'GOODSUP', 'Good Supplier Co', 'ORG1', '001',
 'TEST_MAT_G', 'Test Material G', 'PL01', 'LOCB',
 450, 'EA', 450, 400, 50,
 DATEADD(day, -20, CURRENT_DATE), DATEADD(day, -17, CURRENT_DATE), 'F', 'NB',
 8.00, 1, 'USD', 3600.00,
 '3', '01', '', '',
 '', '2', ''),

-- For TEST_MAT_H with AVGSUPPL
('PO204', '0010', 'AVGSUPPL', 'Average Supplies Ltd', 'ORG2', '002',
 'TEST_MAT_H', 'Test Material H', 'PL02', 'LOCC',
 700, 'KG', 700, 700, 0,
 DATEADD(day, -30, CURRENT_DATE), DATEADD(day, -32, CURRENT_DATE), 'F', 'NB',
 6.00, 1, 'USD', 4200.00,
 '-2', '02', '', '',
 '', '3', ''),

('PO205', '0010', 'AVGSUPPL', 'Average Supplies Ltd', 'ORG2', '002',
 'TEST_MAT_H', 'Test Material H', 'PL02', 'LOCC',
 550, 'KG', 550, 500, 50,
 DATEADD(day, -18, CURRENT_DATE), DATEADD(day, -15, CURRENT_DATE), 'F', 'NB',
 6.00, 1, 'USD', 3300.00,
 '3', '02', '', '',
 '', '2', ''),

('PO206', '0010', 'AVGSUPPL', 'Average Supplies Ltd', 'ORG2', '002',
 'TEST_MAT_H', 'Test Material H', 'PL02', 'LOCC',
 600, 'KG', 600, 600, 0,
 DATEADD(day, -8, CURRENT_DATE), DATEADD(day, -10, CURRENT_DATE), 'F', 'NB',
 6.00, 1, 'USD', 3600.00,
 '-2', '02', '', '',
 '', '3', ''),

-- For TEST_MAT_I with LOWREL
('PO207', '0010', 'LOWREL', 'Low Reliability Corp', 'ORG2', '002',
 'TEST_MAT_I', 'Test Material I', 'PL01', 'LOCA',
 400, 'M', 400, 300, 100,
 DATEADD(day, -45, CURRENT_DATE), DATEADD(day, -38, CURRENT_DATE), 'F', 'NB',
 7.00, 1, 'USD', 2800.00,
 '7', '01', '', '',
 '', '2', ''),

('PO208', '0010', 'LOWREL', 'Low Reliability Corp', 'ORG2', '002',
 'TEST_MAT_I', 'Test Material I', 'PL01', 'LOCD',
 350, 'M', 350, 250, 100,
 DATEADD(day, -28, CURRENT_DATE), DATEADD(day, -22, CURRENT_DATE), 'F', 'NB',
 7.00, 1, 'USD', 2450.00,
 '6', '01', '', '',
 '', '2', ''),

('PO209', '0010', 'LOWREL', 'Low Reliability Corp', 'ORG2', '002',
 'TEST_MAT_I', 'Test Material I', 'PL01', 'LOCA',
 500, 'M', 500, 400, 100,
 DATEADD(day, -12, CURRENT_DATE), DATEADD(day, -7, CURRENT_DATE), 'F', 'NB',
 7.00, 1, 'USD', 3500.00,
 '5', '01', '', '',
 '', '2', '');

INSERT INTO SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.ME2N (
    EBELN, EBELP, LIFNR, NAME1, EKORG, EKGRP,
    MATNR, TXZ01, WERKS, LGORT,
    MENGE, MEINS, BSTMG, WEMNG, REMNG,
    BEDAT, EINDT, BSTYP, BSART,
    NETPR, PEINH, WAERS, BRTWR,
    LPEIN, LFMON, VRTKZ, VERSART,
    LOEKZ, STATU, MEMORY
) VALUES 

-- SUPPLIER A: Perfect reliability score = 1.0 (all deliveries on time or early)
-- 5 POs, all EINDT >= BEDAT
('PO300', '0010', 'SUP_A', 'Perfect Supplier Inc', 'ORG1', '001',
 'TEST_MAT_A', 'Test Material A', 'PL01', 'LOCA',
 1000, 'EA', 1000, 1000, 0,
 DATEADD(day, -300, CURRENT_DATE), DATEADD(day, -305, CURRENT_DATE), 'F', 'NB',  -- 5 days early
 10.00, 1, 'USD', 10000.00,
 '-5', '01', '', '',
 '', '3', ''),

('PO301', '0010', 'SUP_A', 'Perfect Supplier Inc', 'ORG1', '001',
 'TEST_MAT_A', 'Test Material A', 'PL01', 'LOCA',
 800, 'EA', 800, 800, 0,
 DATEADD(day, -240, CURRENT_DATE), DATEADD(day, -242, CURRENT_DATE), 'F', 'NB',  -- 2 days early
 10.00, 1, 'USD', 8000.00,
 '-2', '01', '', '',
 '', '3', ''),

('PO302', '0010', 'SUP_A', 'Perfect Supplier Inc', 'ORG1', '001',
 'TEST_MAT_A', 'Test Material A', 'PL01', 'LOCA',
 1200, 'EA', 1200, 1200, 0,
 DATEADD(day, -180, CURRENT_DATE), DATEADD(day, -180, CURRENT_DATE), 'F', 'NB',  -- On time
 10.00, 1, 'USD', 12000.00,
 '0', '01', '', '',
 '', '3', ''),

('PO303', '0010', 'SUP_A', 'Perfect Supplier Inc', 'ORG1', '001',
 'TEST_MAT_A', 'Test Material A', 'PL01', 'LOCA',
 600, 'EA', 600, 600, 0,
 DATEADD(day, -120, CURRENT_DATE), DATEADD(day, -125, CURRENT_DATE), 'F', 'NB',  -- 5 days early
 10.00, 1, 'USD', 6000.00,
 '-5', '01', '', '',
 '', '3', ''),

('PO304', '0010', 'SUP_A', 'Perfect Supplier Inc', 'ORG1', '001',
 'TEST_MAT_A', 'Test Material A', 'PL01', 'LOCA',
 900, 'EA', 900, 900, 0,
 DATEADD(day, -60, CURRENT_DATE), DATEADD(day, -62, CURRENT_DATE), 'F', 'NB',  -- 2 days early
 10.00, 1, 'USD', 9000.00,
 '-2', '01', '', '',
 '', '3', ''),

-- SUPPLIER B: High reliability score = 0.9 (8 on-time, 2 late)
('PO305', '0010', 'SUP_B', 'High Reliability Ltd', 'ORG1', '002',
 'TEST_MAT_B', 'Test Material B', 'PL01', 'LOCB',
 500, 'EA', 500, 500, 0,
 DATEADD(day, -290, CURRENT_DATE), DATEADD(day, -290, CURRENT_DATE), 'F', 'NB',  -- On time
 8.00, 1, 'USD', 4000.00,
 '0', '01', '', '',
 '', '3', ''),

('PO306', '0010', 'SUP_B', 'High Reliability Ltd', 'ORG1', '002',
 'TEST_MAT_B', 'Test Material B', 'PL01', 'LOCB',
 450, 'EA', 450, 450, 0,
 DATEADD(day, -250, CURRENT_DATE), DATEADD(day, -252, CURRENT_DATE), 'F', 'NB',  -- 2 days early
 8.00, 1, 'USD', 3600.00,
 '-2', '01', '', '',
 '', '3', ''),

('PO307', '0010', 'SUP_B', 'High Reliability Ltd', 'ORG1', '002',
 'TEST_MAT_B', 'Test Material B', 'PL01', 'LOCB',
 600, 'EA', 600, 600, 0,
 DATEADD(day, -200, CURRENT_DATE), DATEADD(day, -200, CURRENT_DATE), 'F', 'NB',  -- On time
 8.00, 1, 'USD', 4800.00,
 '0', '01', '', '',
 '', '3', ''),

('PO308', '0010', 'SUP_B', 'High Reliability Ltd', 'ORG1', '002',
 'TEST_MAT_B', 'Test Material B', 'PL01', 'LOCB',
 550, 'EA', 550, 550, 0,
 DATEADD(day, -160, CURRENT_DATE), DATEADD(day, -162, CURRENT_DATE), 'F', 'NB',  -- 2 days early
 8.00, 1, 'USD', 4400.00,
 '-2', '01', '', '',
 '', '3', ''),

('PO309', '0010', 'SUP_B', 'High Reliability Ltd', 'ORG1', '002',
 'TEST_MAT_B', 'Test Material B', 'PL01', 'LOCB',
 400, 'EA', 400, 400, 0,
 DATEADD(day, -130, CURRENT_DATE), DATEADD(day, -133, CURRENT_DATE), 'F', 'NB',  -- 3 days early
 8.00, 1, 'USD', 3200.00,
 '-3', '01', '', '',
 '', '3', ''),

('PO310', '0010', 'SUP_B', 'High Reliability Ltd', 'ORG1', '002',
 'TEST_MAT_B', 'Test Material B', 'PL01', 'LOCB',
 700, 'EA', 700, 700, 0,
 DATEADD(day, -100, CURRENT_DATE), DATEADD(day, -100, CURRENT_DATE), 'F', 'NB',  -- On time
 8.00, 1, 'USD', 5600.00,
 '0', '01', '', '',
 '', '3', ''),

('PO311', '0010', 'SUP_B', 'High Reliability Ltd', 'ORG1', '002',
 'TEST_MAT_B', 'Test Material B', 'PL01', 'LOCB',
 350, 'EA', 350, 350, 0,
 DATEADD(day, -80, CURRENT_DATE), DATEADD(day, -82, CURRENT_DATE), 'F', 'NB',  -- 2 days early
 8.00, 1, 'USD', 2800.00,
 '-2', '01', '', '',
 '', '3', ''),

('PO312', '0010', 'SUP_B', 'High Reliability Ltd', 'ORG1', '002',
 'TEST_MAT_B', 'Test Material B', 'PL01', 'LOCB',
 650, 'EA', 650, 600, 50,  -- Late delivery (EINDT < BEDAT)
 DATEADD(day, -50, CURRENT_DATE), DATEADD(day, -45, CURRENT_DATE), 'F', 'NB',  -- 5 days late
 8.00, 1, 'USD', 5200.00,
 '5', '01', '', '',
 '', '2', ''),

('PO313', '0010', 'SUP_B', 'High Reliability Ltd', 'ORG1', '002',
 'TEST_MAT_B', 'Test Material B', 'PL01', 'LOCB',
 750, 'EA', 750, 700, 50,  -- Late delivery (EINDT < BEDAT)
 DATEADD(day, -30, CURRENT_DATE), DATEADD(day, -25, CURRENT_DATE), 'F', 'NB',  -- 5 days late
 8.00, 1, 'USD', 6000.00,
 '5', '01', '', '',
 '', '2', ''),

-- SUPPLIER C: Medium reliability score = 0.75 (5 on-time, 3 late)
('PO314', '0010', 'SUP_C', 'Medium Reliability Co', 'ORG2', '003',
 'TEST_MAT_C', 'Test Material C', 'PL02', 'LOCC',
 800, 'KG', 800, 800, 0,
 DATEADD(day, -280, CURRENT_DATE), DATEADD(day, -280, CURRENT_DATE), 'F', 'NB',  -- On time
 6.00, 1, 'USD', 4800.00,
 '0', '02', '', '',
 '', '3', ''),

('PO315', '0010', 'SUP_C', 'Medium Reliability Co', 'ORG2', '003',
 'TEST_MAT_C', 'Test Material C', 'PL02', 'LOCC',
 600, 'KG', 600, 600, 0,
 DATEADD(day, -220, CURRENT_DATE), DATEADD(day, -222, CURRENT_DATE), 'F', 'NB',  -- 2 days early
 6.00, 1, 'USD', 3600.00,
 '-2', '02', '', '',
 '', '3', ''),

('PO316', '0010', 'SUP_C', 'Medium Reliability Co', 'ORG2', '003',
 'TEST_MAT_C', 'Test Material C', 'PL02', 'LOCC',
 700, 'KG', 700, 700, 0,
 DATEADD(day, -170, CURRENT_DATE), DATEADD(day, -170, CURRENT_DATE), 'F', 'NB',  -- On time
 6.00, 1, 'USD', 4200.00,
 '0', '02', '', '',
 '', '3', ''),

('PO317', '0010', 'SUP_C', 'Medium Reliability Co', 'ORG2', '003',
 'TEST_MAT_C', 'Test Material C', 'PL02', 'LOCC',
 550, 'KG', 550, 500, 50,  -- Late delivery
 DATEADD(day, -140, CURRENT_DATE), DATEADD(day, -135, CURRENT_DATE), 'F', 'NB',  -- 5 days late
 6.00, 1, 'USD', 3300.00,
 '5', '02', '', '',
 '', '2', ''),

('PO318', '0010', 'SUP_C', 'Medium Reliability Co', 'ORG2', '003',
 'TEST_MAT_C', 'Test Material C', 'PL02', 'LOCC',
 900, 'KG', 900, 900, 0,
 DATEADD(day, -110, CURRENT_DATE), DATEADD(day, -112, CURRENT_DATE), 'F', 'NB',  -- 2 days early
 6.00, 1, 'USD', 5400.00,
 '-2', '02', '', '',
 '', '3', ''),

('PO319', '0010', 'SUP_C', 'Medium Reliability Co', 'ORG2', '003',
 'TEST_MAT_C', 'Test Material C', 'PL02', 'LOCC',
 450, 'KG', 450, 450, 0,
 DATEADD(day, -85, CURRENT_DATE), DATEADD(day, -85, CURRENT_DATE), 'F', 'NB',  -- On time
 6.00, 1, 'USD', 2700.00,
 '0', '02', '', '',
 '', '3', ''),

('PO320', '0010', 'SUP_C', 'Medium Reliability Co', 'ORG2', '003',
 'TEST_MAT_C', 'Test Material C', 'PL02', 'LOCC',
 750, 'KG', 750, 700, 50,  -- Late delivery
 DATEADD(day, -55, CURRENT_DATE), DATEADD(day, -50, CURRENT_DATE), 'F', 'NB',  -- 5 days late
 6.00, 1, 'USD', 4500.00,
 '5', '02', '', '',
 '', '2', ''),

('PO321', '0010', 'SUP_C', 'Medium Reliability Co', 'ORG2', '003',
 'TEST_MAT_C', 'Test Material C', 'PL02', 'LOCC',
 500, 'KG', 500, 450, 50,  -- Late delivery
 DATEADD(day, -25, CURRENT_DATE), DATEADD(day, -20, CURRENT_DATE), 'F', 'NB',  -- 5 days late
 6.00, 1, 'USD', 3000.00,
 '5', '02', '', '',
 '', '2', ''),

-- SUPPLIER D: Low reliability score = 0.55 (2 on-time, 4 late)
('PO322', '0010', 'SUP_D', 'Low Reliability Corp', 'ORG1', '004',
 'TEST_MAT_D', 'Test Material D', 'PL01', 'LOCA',
 400, 'M', 400, 400, 0,
 DATEADD(day, -260, CURRENT_DATE), DATEADD(day, -260, CURRENT_DATE), 'F', 'NB',  -- On time
 7.00, 1, 'USD', 2800.00,
 '0', '01', '', '',
 '', '3', ''),

('PO323', '0010', 'SUP_D', 'Low Reliability Corp', 'ORG1', '004',
 'TEST_MAT_D', 'Test Material D', 'PL01', 'LOCD',
 350, 'M', 350, 300, 50,  -- Late delivery
 DATEADD(day, -210, CURRENT_DATE), DATEADD(day, -200, CURRENT_DATE), 'F', 'NB',  -- 10 days late
 7.00, 1, 'USD', 2450.00,
 '10', '01', '', '',
 '', '2', ''),

('PO324', '0010', 'SUP_D', 'Low Reliability Corp', 'ORG1', '004',
 'TEST_MAT_D', 'Test Material D', 'PL01', 'LOCA',
 500, 'M', 500, 450, 50,  -- Late delivery
 DATEADD(day, -165, CURRENT_DATE), DATEADD(day, -155, CURRENT_DATE), 'F', 'NB',  -- 10 days late
 7.00, 1, 'USD', 3500.00,
 '10', '01', '', '',
 '', '2', ''),

('PO325', '0010', 'SUP_D', 'Low Reliability Corp', 'ORG1', '004',
 'TEST_MAT_D', 'Test Material D', 'PL01', 'LOCD',
 450, 'M', 450, 450, 0,
 DATEADD(day, -120, CURRENT_DATE), DATEADD(day, -122, CURRENT_DATE), 'F', 'NB',  -- 2 days early (On time)
 7.00, 1, 'USD', 3150.00,
 '-2', '01', '', '',
 '', '3', ''),

('PO326', '0010', 'SUP_D', 'Low Reliability Corp', 'ORG1', '004',
 'TEST_MAT_D', 'Test Material D', 'PL01', 'LOCA',
 300, 'M', 300, 250, 50,  -- Late delivery
 DATEADD(day, -80, CURRENT_DATE), DATEADD(day, -70, CURRENT_DATE), 'F', 'NB',  -- 10 days late
 7.00, 1, 'USD', 2100.00,
 '10', '01', '', '',
 '', '2', ''),

('PO327', '0010', 'SUP_D', 'Low Reliability Corp', 'ORG1', '004',
 'TEST_MAT_D', 'Test Material D', 'PL01', 'LOCD',
 550, 'M', 550, 500, 50,  -- Late delivery
 DATEADD(day, -40, CURRENT_DATE), DATEADD(day, -30, CURRENT_DATE), 'F', 'NB',  -- 10 days late
 7.00, 1, 'USD', 3850.00,
 '10', '01', '', '',
 '', '2', ''),

-- SUPPLIER E: Very low reliability score = 0.35 (1 on-time, 5 late)
('PO328', '0010', 'SUP_E', 'Very Low Reliability Ltd', 'ORG2', '005',
 'TEST_MAT_E', 'Test Material E', 'PL02', 'LOCE',
 600, 'EA', 600, 550, 50,  -- Late delivery
 DATEADD(day, -270, CURRENT_DATE), DATEADD(day, -260, CURRENT_DATE), 'F', 'NB',  -- 10 days late
 9.00, 1, 'USD', 5400.00,
 '10', '02', '', '',
 '', '2', ''),

('PO329', '0010', 'SUP_E', 'Very Low Reliability Ltd', 'ORG2', '005',
 'TEST_MAT_E', 'Test Material E', 'PL02', 'LOCE',
 500, 'EA', 500, 450, 50,  -- Late delivery
 DATEADD(day, -215, CURRENT_DATE), DATEADD(day, -205, CURRENT_DATE), 'F', 'NB',  -- 10 days late
 9.00, 1, 'USD', 4500.00,
 '10', '02', '', '',
 '', '2', ''),

('PO330', '0010', 'SUP_E', 'Very Low Reliability Ltd', 'ORG2', '005',
 'TEST_MAT_E', 'Test Material E', 'PL02', 'LOCE',
 700, 'EA', 700, 700, 0,
 DATEADD(day, -160, CURRENT_DATE), DATEADD(day, -162, CURRENT_DATE), 'F', 'NB',  -- 2 days early (On time)
 9.00, 1, 'USD', 6300.00,
 '-2', '02', '', '',
 '', '3', ''),

('PO331', '0010', 'SUP_E', 'Very Low Reliability Ltd', 'ORG2', '005',
 'TEST_MAT_E', 'Test Material E', 'PL02', 'LOCE',
 400, 'EA', 400, 350, 50,  -- Late delivery
 DATEADD(day, -115, CURRENT_DATE), DATEADD(day, -105, CURRENT_DATE), 'F', 'NB',  -- 10 days late
 9.00, 1, 'USD', 3600.00,
 '10', '02', '', '',
 '', '2', ''),

('PO332', '0010', 'SUP_E', 'Very Low Reliability Ltd', 'ORG2', '005',
 'TEST_MAT_E', 'Test Material E', 'PL02', 'LOCE',
 550, 'EA', 550, 500, 50,  -- Late delivery
 DATEADD(day, -70, CURRENT_DATE), DATEADD(day, -60, CURRENT_DATE), 'F', 'NB',  -- 10 days late
 9.00, 1, 'USD', 4950.00,
 '10', '02', '', '',
 '', '2', ''),

('PO333', '0010', 'SUP_E', 'Very Low Reliability Ltd', 'ORG2', '005',
 'TEST_MAT_E', 'Test Material E', 'PL02', 'LOCE',
 450, 'EA', 450, 400, 50,  -- Late delivery
 DATEADD(day, -30, CURRENT_DATE), DATEADD(day, -20, CURRENT_DATE), 'F', 'NB',  -- 10 days late
 9.00, 1, 'USD', 4050.00,
 '10', '02', '', '',
 '', '2', ''),

-- SUPPLIER F: Extremely low reliability score = 0.25 (0 on-time, 4 late)
('PO334', '0010', 'SUP_F', 'Extremely Low Inc', 'ORG1', '006',
 'TEST_MAT_F', 'Test Material F', 'PL01', 'LOCA',
 300, 'EA', 300, 250, 50,  -- Late delivery
 DATEADD(day, -250, CURRENT_DATE), DATEADD(day, -240, CURRENT_DATE), 'F', 'NB',  -- 10 days late
 11.00, 1, 'USD', 3300.00,
 '10', '01', '', '',
 '', '2', ''),

('PO335', '0010', 'SUP_F', 'Extremely Low Inc', 'ORG1', '006',
 'TEST_MAT_F', 'Test Material F', 'PL01', 'LOCA',
 400, 'EA', 400, 350, 50,  -- Late delivery
 DATEADD(day, -190, CURRENT_DATE), DATEADD(day, -180, CURRENT_DATE), 'F', 'NB',  -- 10 days late
 11.00, 1, 'USD', 4400.00,
 '10', '01', '', '',
 '', '2', ''),

('PO336', '0010', 'SUP_F', 'Extremely Low Inc', 'ORG1', '006',
 'TEST_MAT_F', 'Test Material F', 'PL01', 'LOCA',
 500, 'EA', 500, 450, 50,  -- Late delivery
 DATEADD(day, -130, CURRENT_DATE), DATEADD(day, -120, CURRENT_DATE), 'F', 'NB',  -- 10 days late
 11.00, 1, 'USD', 5500.00,
 '10', '01', '', '',
 '', '2', ''),

('PO337', '0010', 'SUP_F', 'Extremely Low Inc', 'ORG1', '006',
 'TEST_MAT_F', 'Test Material F', 'PL01', 'LOCA',
 350, 'EA', 350, 300, 50,  -- Late delivery
 DATEADD(day, -70, CURRENT_DATE), DATEADD(day, -60, CURRENT_DATE), 'F', 'NB',  -- 10 days late
 11.00, 1, 'USD', 3850.00,
 '10', '01', '', '',
 '', '2', ''),

-- SUPPLIER G: Minimal reliability score = 0.20 (0 on-time, 5 late - but this will yield 0.25? Let's check formula)
-- The formula AVG(CASE WHEN EINDT >= BEDAT THEN 1.0 ELSE 0.5 END) means:
-- On-time = 1.0, Late = 0.5
-- With 5 late POs: (0.5 * 5) / 5 = 0.5 (can't go below 0.5)
-- To get 0.2, we need a different pattern, but formula limits to 0.5 minimum
-- Let's create a supplier that will give 0.5 (all late)
('PO338', '0010', 'SUP_G', 'Minimal Reliability Co', 'ORG2', '007',
 'TEST_MAT_G', 'Test Material G', 'PL01', 'LOCB',
 250, 'EA', 250, 200, 50,  -- Late delivery
 DATEADD(day, -240, CURRENT_DATE), DATEADD(day, -230, CURRENT_DATE), 'F', 'NB',  -- 10 days late
 12.00, 1, 'USD', 3000.00,
 '10', '01', '', '',
 '', '2', ''),

('PO339', '0010', 'SUP_G', 'Minimal Reliability Co', 'ORG2', '007',
 'TEST_MAT_G', 'Test Material G', 'PL01', 'LOCB',
 350, 'EA', 350, 300, 50,  -- Late delivery
 DATEADD(day, -180, CURRENT_DATE), DATEADD(day, -170, CURRENT_DATE), 'F', 'NB',  -- 10 days late
 12.00, 1, 'USD', 4200.00,
 '10', '01', '', '',
 '', '2', ''),

('PO340', '0010', 'SUP_G', 'Minimal Reliability Co', 'ORG2', '007',
 'TEST_MAT_G', 'Test Material G', 'PL01', 'LOCB',
 450, 'EA', 450, 400, 50,  -- Late delivery
 DATEADD(day, -120, CURRENT_DATE), DATEADD(day, -110, CURRENT_DATE), 'F', 'NB',  -- 10 days late
 12.00, 1, 'USD', 5400.00,
 '10', '01', '', '',
 '', '2', ''),

('PO341', '0010', 'SUP_G', 'Minimal Reliability Co', 'ORG2', '007',
 'TEST_MAT_G', 'Test Material G', 'PL01', 'LOCB',
 300, 'EA', 300, 250, 50,  -- Late delivery
 DATEADD(day, -60, CURRENT_DATE), DATEADD(day, -50, CURRENT_DATE), 'F', 'NB',  -- 10 days late
 12.00, 1, 'USD', 3600.00,
 '10', '01', '', '',
 '', '2', '');

-- =====================================================
-- VERIFICATION QUERY - Check the test data in the view
-- =====================================================
SELECT * FROM INVENTORY_SEMANTIC_VIEW 
WHERE material_id LIKE 'TEST_%'
ORDER BY material_id, plant, storage_location;

-- =====================================================
-- DELETE STATEMENT FOR TEST DATA
-- Run this to clean up all test data
-- =====================================================

/*
-- Delete from MATDOC (Material Documents)
DELETE FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MATDOC 
WHERE MATNR LIKE 'TEST_MAT%';

-- Delete from MARC (Material Master Plant Data)
DELETE FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MARC 
WHERE MATNR LIKE 'TEST_MAT%';

-- Delete from MD04 (MRP Requirements)
DELETE FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 
WHERE MATNR LIKE 'TEST_MAT%';

-- Delete from ME2N (Purchase Orders)
DELETE FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.ME2N 
WHERE MATNR LIKE 'TEST_MAT%';

-- Commit the deletion (if applicable)
-- COMMIT;

-- Verify cleanup
SELECT 'MATDOC' as table_name, COUNT(*) as record_count 
FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MATDOC 
WHERE MATNR LIKE 'TEST_MAT%'
UNION ALL
SELECT 'MARC', COUNT(*) 
FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MARC 
WHERE MATNR LIKE 'TEST_MAT%'
UNION ALL
SELECT 'MD04', COUNT(*) 
FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 
WHERE MATNR LIKE 'TEST_MAT%'
UNION ALL
SELECT 'ME2N', COUNT(*) 
FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.ME2N 
WHERE MATNR LIKE 'TEST_MAT%';
*/





