USE WAREHOUSE SAP_COMPUTE;
USE DATABASE SAP_BDC_HORIZON_CATALOG;
USE SCHEMA AGENTS;

-- INVENTORY_DEMAND_PATTERNS 
/*
Test Data Summary:
Material	Pattern	       Requirement Types	      Time Distribution	        Special Features
TEST_DP_A	High runner	   CU (Customer Orders)	      Weekly for 60 days	    Consistent demand
TEST_DP_B	Seasonal	   DL (Delivery Schedules)	  10,20,30,45,60,75 days	Increasing then decreasing
TEST_DP_C	New product	   PE (Planned Orders)	      5,15,25,40,55,70,85 days	Increasing trend
TEST_DP_D	Slow mover	   PR (Purchase Requisitions) 30,60,90 days	            Sparse demand
TEST_DP_E	Promotional	   CU, DL, PE (Mixed)	      Multiple dates	        All 3 types present
TEST_DP_F	Raw material   CU, DL, PE	              High frequency	        High volumes, mixed types
TEST_DP_G	Packaging	   CU only	                  Weekly for 70 days	    Very high frequency
*/
-- =====================================================
-- TEST DATA GENERATION FOR INVENTORY_DEMAND_PATTERNS
-- All test data is marked with 'TEST_DP_' prefix
-- Created for demand pattern analysis across next 3 months
-- =====================================================


-- First, let's create test data for MARC table (referenced in the view)
INSERT INTO SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MARC (
    MANDT, MATNR, WERKS, DISPO, DISMM, BESKZ, SOBSL,
    MINBE, EISBE, BSTMI, BSTMA, BSTFE,
    PLIFZ, WEBAZ, BEARZ, RUEZT, TRANSZ,
    LOSGR, PERKZ, PERIV, AUSSS,
    KZPRD, VRMOD, VINT1, VINT2,
    FHORI, WEBRE, PRCTL,
    LGPRO, LGRAD, DISPR
) VALUES 
-- Material A - High runner, MRP Controller 001
('800', 'TEST_DP_A', 'PL01', '001', 'PD', 'F', NULL,
 500, 200, 100, 5000, NULL,
 5, 1, 1, 0, 2,
 'WB', 'W', 'V1', 1,
 '1', '1', '1', '1',
 '001', 'X', 'ZM',
 'PROD', 85.00, 'DS1'),

-- Material B - Seasonal product, MRP Controller 002
('800', 'TEST_DP_B', 'PL01', '002', 'VB', 'F', NULL,
 300, 150, 200, 3000, NULL,
 7, 2, 1, 0, 3,
 'EX', 'M', 'V2', 1,
 '1', '2', '2', '2',
 '002', 'X', 'ZF',
 'PROD', 75.00, 'DS2'),

-- Material C - New product, MRP Controller 001
('800', 'TEST_DP_C', 'PL02', '001', 'PD', 'E', '30',
 200, 100, 50, 2000, NULL,
 4, 1, 1, 0, 2,
 'WB', 'W', 'V1', 1,
 '1', '1', '1', '1',
 '001', 'X', 'ZM',
 'PROD', 90.00, 'DS1'),

-- Material D - Slow mover, MRP Controller 003
('800', 'TEST_DP_D', 'PL01', '003', 'ND', 'F', NULL,
 100, 50, 100, 1000, NULL,
 10, 1, 1, 0, 3,
 'EX', 'M', 'V2', 1,
 '1', '2', '2', '2',
 '003', '', 'ZF',
 'PROD', 60.00, 'DS2'),

-- Material E - Promotional item, MRP Controller 002
('800', 'TEST_DP_E', 'PL02', '002', 'PD', 'F', NULL,
 400, 200, 150, 4000, NULL,
 6, 1, 1, 0, 2,
 'WB', 'W', 'V1', 1,
 '1', '1', '1', '1',
 '002', 'X', 'ZM',
 'PROD', 88.00, 'DS1'),

-- Material F - Raw material, MRP Controller 001
('800', 'TEST_DP_F', 'PL03', '001', 'PD', 'F', NULL,
 1000, 500, 500, 10000, NULL,
 3, 1, 2, 0, 1,
 'WB', 'W', 'V1', 1,
 '1', '1', '1', '1',
 '001', 'X', 'ZM',
 'RAW', 95.00, 'DS3'),

-- Material G - Packaging, MRP Controller 004
('800', 'TEST_DP_G', 'PL03', '004', 'VB', 'F', NULL,
 5000, 2000, 1000, 50000, NULL,
 2, 1, 1, 0, 1,
 'EX', 'W', 'V1', 1,
 '1', '1', '1', '1',
 '004', 'X', 'ZM',
 'PACK', 80.00, 'DS3');

-- Now create test data for VBAP table (Sales Order Items) - CORRECTED: No MANDT column
INSERT INTO SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.VBAP (
    VBELN, POSNR, MATNR, ARKTX, WERKS, LGORT, CHARG,
    KWMENG, VRKME, MEINS, UMZIN, UMZIZ,
    NETWR, NETPR, PEINH, KPEIN,
    EDTNR, EINDT, ETENR,
    PSTYV, ABGRU, LFSTA, FKSTA,
    CUOBJ, POSEX
) VALUES 
-- Material A descriptions
('SO0001', '0010', 'TEST_DP_A', 'High-Performance Widget', 'PL01', 'ST01', NULL,
 0, 'EA', 'EA', 1, 1,
 0, 0, 1, 1,
 '0001', DATEADD(day, 30, CURRENT_DATE), '0010',
 'ZTAK', NULL, 'C', NULL,
 NULL, NULL),

('SO0002', '0010', 'TEST_DP_A', 'High-Performance Widget', 'PL01', 'ST01', NULL,
 0, 'EA', 'EA', 1, 1,
 0, 0, 1, 1,
 '0001', DATEADD(day, 60, CURRENT_DATE), '0010',
 'ZTAK', NULL, 'C', NULL,
 NULL, NULL),

-- Material B descriptions
('SO0003', '0010', 'TEST_DP_B', 'Seasonal Garden Tool - Spring', 'PL01', 'ST02', NULL,
 0, 'EA', 'EA', 1, 1,
 0, 0, 1, 1,
 '0001', DATEADD(day, 45, CURRENT_DATE), '0010',
 'ZTAK', NULL, 'C', NULL,
 NULL, NULL),

('SO0004', '0010', 'TEST_DP_B', 'Seasonal Garden Tool - Spring', 'PL01', 'ST02', NULL,
 0, 'EA', 'EA', 1, 1,
 0, 0, 1, 1,
 '0001', DATEADD(day, 75, CURRENT_DATE), '0010',
 'ZTAK', NULL, 'C', NULL,
 NULL, NULL),

-- Material C descriptions
('SO0005', '0010', 'TEST_DP_C', 'Advanced Sensor Module', 'PL02', 'STA1', NULL,
 0, 'EA', 'EA', 1, 1,
 0, 0, 1, 1,
 '0001', DATEADD(day, 15, CURRENT_DATE), '0010',
 'ZTAK', NULL, 'C', NULL,
 NULL, NULL),

('SO0006', '0010', 'TEST_DP_C', 'Advanced Sensor Module', 'PL02', 'STA1', NULL,
 0, 'EA', 'EA', 1, 1,
 0, 0, 1, 1,
 '0001', DATEADD(day, 50, CURRENT_DATE), '0010',
 'ZTAK', NULL, 'C', NULL,
 NULL, NULL),

-- Material D descriptions
('SO0007', '0010', 'TEST_DP_D', 'Industrial Bearing (Slow Moving)', 'PL01', 'ST03', NULL,
 0, 'EA', 'EA', 1, 1,
 0, 0, 1, 1,
 '0001', DATEADD(day, 90, CURRENT_DATE), '0010',
 'ZTAK', NULL, 'C', NULL,
 NULL, NULL),

-- Material E descriptions
('SO0008', '0010', 'TEST_DP_E', 'Promotional Summer Kit', 'PL02', 'STC1', NULL,
 0, 'EA', 'EA', 1, 1,
 0, 0, 1, 1,
 '0001', DATEADD(day, 25, CURRENT_DATE), '0010',
 'ZTAK', NULL, 'C', NULL,
 NULL, NULL),

('SO0009', '0010', 'TEST_DP_E', 'Promotional Summer Kit', 'PL02', 'STC1', NULL,
 0, 'EA', 'EA', 1, 1,
 0, 0, 1, 1,
 '0001', DATEADD(day, 55, CURRENT_DATE), '0010',
 'ZTAK', NULL, 'C', NULL,
 NULL, NULL),

('SO0010', '0010', 'TEST_DP_E', 'Promotional Summer Kit', 'PL02', 'STC1', NULL,
 0, 'EA', 'EA', 1, 1,
 0, 0, 1, 1,
 '0001', DATEADD(day, 85, CURRENT_DATE), '0010',
 'ZTAK', NULL, 'C', NULL,
 NULL, NULL),

-- Material F descriptions
('SO0011', '0010', 'TEST_DP_F', 'Raw Material - Aluminum Sheet', 'PL03', 'STF1', NULL,
 0, 'KG', 'KG', 1, 1,
 0, 0, 1, 1,
 '0001', DATEADD(day, 10, CURRENT_DATE), '0010',
 'ZTAK', NULL, 'C', NULL,
 NULL, NULL),

('SO0012', '0010', 'TEST_DP_F', 'Raw Material - Aluminum Sheet', 'PL03', 'STF1', NULL,
 0, 'KG', 'KG', 1, 1,
 0, 0, 1, 1,
 '0001', DATEADD(day, 40, CURRENT_DATE), '0010',
 'ZTAK', NULL, 'C', NULL,
 NULL, NULL),

-- Material G descriptions
('SO0013', '0010', 'TEST_DP_G', 'Packaging Material - Box L', 'PL03', 'STG1', NULL,
 0, 'EA', 'EA', 1, 1,
 0, 0, 1, 1,
 '0001', DATEADD(day, 20, CURRENT_DATE), '0010',
 'ZTAK', NULL, 'C', NULL,
 NULL, NULL),

('SO0014', '0010', 'TEST_DP_G', 'Packaging Material - Box L', 'PL03', 'STG1', NULL,
 0, 'EA', 'EA', 1, 1,
 0, 0, 1, 1,
 '0001', DATEADD(day, 70, CURRENT_DATE), '0010',
 'ZTAK', NULL, 'C', NULL,
 NULL, NULL);

-- Finally, create test data for MD04 table (MRP Requirements)
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
-- TEST_DP_A: Customer Orders (CU) - High runner
-- =====================================================
('800', 'TEST_DP_A', 'PL01', 'MRP01', 'CU', DATEADD(day, 7, CURRENT_DATE),
 'PL001', 'PO001', 'RS001',
 500, 'EA', 0, 500,
 2000, 0, 0, 0,
 '001', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', '001',
 'B', ''),

('800', 'TEST_DP_A', 'PL01', 'MRP01', 'CU', DATEADD(day, 14, CURRENT_DATE),
 'PL002', 'PO002', 'RS002',
 750, 'EA', 0, 750,
 2000, 0, 0, 0,
 '001', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', '001',
 'B', ''),

('800', 'TEST_DP_A', 'PL01', 'MRP01', 'CU', DATEADD(day, 21, CURRENT_DATE),
 'PL003', 'PO003', 'RS003',
 600, 'EA', 0, 600,
 2000, 0, 0, 0,
 '001', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', '001',
 'B', ''),

('800', 'TEST_DP_A', 'PL01', 'MRP01', 'CU', DATEADD(day, 28, CURRENT_DATE),
 'PL004', 'PO004', 'RS004',
 800, 'EA', 0, 800,
 2000, 0, 0, 0,
 '001', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', '001',
 'B', ''),

('800', 'TEST_DP_A', 'PL01', 'MRP01', 'CU', DATEADD(day, 35, CURRENT_DATE),
 'PL005', 'PO005', 'RS005',
 550, 'EA', 0, 550,
 2000, 0, 0, 0,
 '001', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', '001',
 'B', ''),

('800', 'TEST_DP_A', 'PL01', 'MRP01', 'CU', DATEADD(day, 42, CURRENT_DATE),
 'PL006', 'PO006', 'RS006',
 700, 'EA', 0, 700,
 2000, 0, 0, 0,
 '001', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', '001',
 'B', ''),

('800', 'TEST_DP_A', 'PL01', 'MRP01', 'CU', DATEADD(day, 60, CURRENT_DATE),
 'PL007', 'PO007', 'RS007',
 650, 'EA', 0, 650,
 2000, 0, 0, 0,
 '001', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', '001',
 'B', ''),

-- =====================================================
-- TEST_DP_B: Delivery Schedules (DL) - Seasonal product
-- =====================================================
('800', 'TEST_DP_B', 'PL01', 'MRP01', 'DL', DATEADD(day, 10, CURRENT_DATE),
 'DL001', NULL, NULL,
 1200, 'EA', 0, 1200,
 500, 0, 0, 0,
 '002', 'EX', 'F', NULL,
 0, 7, 'X',
 'SUP002', '002',
 'D', ''),

('800', 'TEST_DP_B', 'PL01', 'MRP01', 'DL', DATEADD(day, 20, CURRENT_DATE),
 'DL002', NULL, NULL,
 1500, 'EA', 0, 1500,
 500, 0, 0, 0,
 '002', 'EX', 'F', NULL,
 0, 7, 'X',
 'SUP002', '002',
 'D', ''),

('800', 'TEST_DP_B', 'PL01', 'MRP01', 'DL', DATEADD(day, 30, CURRENT_DATE),
 'DL003', NULL, NULL,
 1800, 'EA', 0, 1800,
 500, 0, 0, 0,
 '002', 'EX', 'F', NULL,
 0, 7, 'X',
 'SUP002', '002',
 'D', ''),

('800', 'TEST_DP_B', 'PL01', 'MRP01', 'DL', DATEADD(day, 45, CURRENT_DATE),
 'DL004', NULL, NULL,
 2000, 'EA', 0, 2000,
 500, 0, 0, 0,
 '002', 'EX', 'F', NULL,
 0, 7, 'X',
 'SUP002', '002',
 'D', ''),

('800', 'TEST_DP_B', 'PL01', 'MRP01', 'DL', DATEADD(day, 60, CURRENT_DATE),
 'DL005', NULL, NULL,
 1600, 'EA', 0, 1600,
 500, 0, 0, 0,
 '002', 'EX', 'F', NULL,
 0, 7, 'X',
 'SUP002', '002',
 'D', ''),

('800', 'TEST_DP_B', 'PL01', 'MRP01', 'DL', DATEADD(day, 75, CURRENT_DATE),
 'DL006', NULL, NULL,
 1400, 'EA', 0, 1400,
 500, 0, 0, 0,
 '002', 'EX', 'F', NULL,
 0, 7, 'X',
 'SUP002', '002',
 'D', ''),

-- =====================================================
-- TEST_DP_C: Planned Orders (PE) - New product
-- =====================================================
('800', 'TEST_DP_C', 'PL02', 'MRP02', 'PE', DATEADD(day, 5, CURRENT_DATE),
 'PE001', NULL, NULL,
 300, 'EA', 0, 300,
 800, 0, 0, 0,
 '001', 'WB', 'E', '30',
 0, 4, 'X',
 NULL, '001',
 'P', ''),

('800', 'TEST_DP_C', 'PL02', 'MRP02', 'PE', DATEADD(day, 15, CURRENT_DATE),
 'PE002', NULL, NULL,
 350, 'EA', 0, 350,
 800, 0, 0, 0,
 '001', 'WB', 'E', '30',
 0, 4, 'X',
 NULL, '001',
 'P', ''),

('800', 'TEST_DP_C', 'PL02', 'MRP02', 'PE', DATEADD(day, 25, CURRENT_DATE),
 'PE003', NULL, NULL,
 400, 'EA', 0, 400,
 800, 0, 0, 0,
 '001', 'WB', 'E', '30',
 0, 4, 'X',
 NULL, '001',
 'P', ''),

('800', 'TEST_DP_C', 'PL02', 'MRP02', 'PE', DATEADD(day, 40, CURRENT_DATE),
 'PE004', NULL, NULL,
 450, 'EA', 0, 450,
 800, 0, 0, 0,
 '001', 'WB', 'E', '30',
 0, 4, 'X',
 NULL, '001',
 'P', ''),

('800', 'TEST_DP_C', 'PL02', 'MRP02', 'PE', DATEADD(day, 55, CURRENT_DATE),
 'PE005', NULL, NULL,
 500, 'EA', 0, 500,
 800, 0, 0, 0,
 '001', 'WB', 'E', '30',
 0, 4, 'X',
 NULL, '001',
 'P', ''),

('800', 'TEST_DP_C', 'PL02', 'MRP02', 'PE', DATEADD(day, 70, CURRENT_DATE),
 'PE006', NULL, NULL,
 550, 'EA', 0, 550,
 800, 0, 0, 0,
 '001', 'WB', 'E', '30',
 0, 4, 'X',
 NULL, '001',
 'P', ''),

('800', 'TEST_DP_C', 'PL02', 'MRP02', 'PE', DATEADD(day, 85, CURRENT_DATE),
 'PE007', NULL, NULL,
 600, 'EA', 0, 600,
 800, 0, 0, 0,
 '001', 'WB', 'E', '30',
 0, 4, 'X',
 NULL, '001',
 'P', ''),

-- =====================================================
-- TEST_DP_D: Purchase Requisitions (PR) - Slow mover
-- =====================================================
('800', 'TEST_DP_D', 'PL01', 'MRP01', 'PR', DATEADD(day, 30, CURRENT_DATE),
 'PR001', NULL, NULL,
 100, 'EA', 0, 100,
 200, 0, 0, 0,
 '003', 'EX', 'F', NULL,
 0, 10, '',
 'SUP003', '003',
 'P', ''),

('800', 'TEST_DP_D', 'PL01', 'MRP01', 'PR', DATEADD(day, 60, CURRENT_DATE),
 'PR002', NULL, NULL,
 150, 'EA', 0, 150,
 200, 0, 0, 0,
 '003', 'EX', 'F', NULL,
 0, 10, '',
 'SUP003', '003',
 'P', ''),

('800', 'TEST_DP_D', 'PL01', 'MRP01', 'PR', DATEADD(day, 90, CURRENT_DATE),
 'PR003', NULL, NULL,
 120, 'EA', 0, 120,
 200, 0, 0, 0,
 '003', 'EX', 'F', NULL,
 0, 10, '',
 'SUP003', '003',
 'P', ''),

-- =====================================================
-- TEST_DP_E: Mixed requirement types - Promotional
-- =====================================================
-- Customer Orders
('800', 'TEST_DP_E', 'PL02', 'MRP02', 'CU', DATEADD(day, 12, CURRENT_DATE),
 'PL008', 'PO008', 'RS008',
 800, 'EA', 0, 800,
 1200, 0, 0, 0,
 '002', 'WB', 'E', NULL,
 0, 6, 'X',
 'SUP004', '002',
 'B', ''),

('800', 'TEST_DP_E', 'PL02', 'MRP02', 'CU', DATEADD(day, 28, CURRENT_DATE),
 'PL009', 'PO009', 'RS009',
 950, 'EA', 0, 950,
 1200, 0, 0, 0,
 '002', 'WB', 'E', NULL,
 0, 6, 'X',
 'SUP004', '002',
 'B', ''),

-- Delivery Schedules
('800', 'TEST_DP_E', 'PL02', 'MRP02', 'DL', DATEADD(day, 18, CURRENT_DATE),
 'DL007', NULL, NULL,
 700, 'EA', 0, 700,
 1200, 0, 0, 0,
 '002', 'WB', 'F', NULL,
 0, 6, 'X',
 'SUP005', '002',
 'D', ''),

('800', 'TEST_DP_E', 'PL02', 'MRP02', 'DL', DATEADD(day, 42, CURRENT_DATE),
 'DL008', NULL, NULL,
 850, 'EA', 0, 850,
 1200, 0, 0, 0,
 '002', 'WB', 'F', NULL,
 0, 6, 'X',
 'SUP005', '002',
 'D', ''),

-- Planned Orders
('800', 'TEST_DP_E', 'PL02', 'MRP02', 'PE', DATEADD(day, 35, CURRENT_DATE),
 'PE008', NULL, NULL,
 600, 'EA', 0, 600,
 1200, 0, 0, 0,
 '002', 'WB', 'E', NULL,
 0, 6, 'X',
 NULL, '002',
 'P', ''),

('800', 'TEST_DP_E', 'PL02', 'MRP02', 'PE', DATEADD(day, 65, CURRENT_DATE),
 'PE009', NULL, NULL,
 750, 'EA', 0, 750,
 1200, 0, 0, 0,
 '002', 'WB', 'E', NULL,
 0, 6, 'X',
 NULL, '002',
 'P', ''),

-- =====================================================
-- TEST_DP_F: Raw material - High volume, short lead time
-- =====================================================
('800', 'TEST_DP_F', 'PL03', 'MRP03', 'CU', DATEADD(day, 3, CURRENT_DATE),
 'PL010', 'PO010', 'RS010',
 5000, 'KG', 0, 5000,
 15000, 0, 0, 0,
 '001', 'WB', 'E', NULL,
 0, 3, 'X',
 'SUP006', '004',
 'B', ''),

('800', 'TEST_DP_F', 'PL03', 'MRP03', 'CU', DATEADD(day, 8, CURRENT_DATE),
 'PL011', 'PO011', 'RS011',
 6000, 'KG', 0, 6000,
 15000, 0, 0, 0,
 '001', 'WB', 'E', NULL,
 0, 3, 'X',
 'SUP006', '004',
 'B', ''),

('800', 'TEST_DP_F', 'PL03', 'MRP03', 'CU', DATEADD(day, 15, CURRENT_DATE),
 'PL012', 'PO012', 'RS012',
 5500, 'KG', 0, 5500,
 15000, 0, 0, 0,
 '001', 'WB', 'E', NULL,
 0, 3, 'X',
 'SUP006', '004',
 'B', ''),

('800', 'TEST_DP_F', 'PL03', 'MRP03', 'DL', DATEADD(day, 22, CURRENT_DATE),
 'DL009', NULL, NULL,
 7000, 'KG', 0, 7000,
 15000, 0, 0, 0,
 '001', 'WB', 'F', NULL,
 0, 3, 'X',
 'SUP007', '004',
 'D', ''),

('800', 'TEST_DP_F', 'PL03', 'MRP03', 'DL', DATEADD(day, 30, CURRENT_DATE),
 'DL010', NULL, NULL,
 6500, 'KG', 0, 6500,
 15000, 0, 0, 0,
 '001', 'WB', 'F', NULL,
 0, 3, 'X',
 'SUP007', '004',
 'D', ''),

('800', 'TEST_DP_F', 'PL03', 'MRP03', 'PE', DATEADD(day, 45, CURRENT_DATE),
 'PE010', NULL, NULL,
 8000, 'KG', 0, 8000,
 15000, 0, 0, 0,
 '001', 'WB', 'E', NULL,
 0, 3, 'X',
 NULL, '004',
 'P', ''),

-- =====================================================
-- TEST_DP_G: Packaging - High frequency, low quantity
-- =====================================================
('800', 'TEST_DP_G', 'PL03', 'MRP03', 'CU', DATEADD(day, 5, CURRENT_DATE),
 'PL013', 'PO013', 'RS013',
 2000, 'EA', 0, 2000,
 10000, 0, 0, 0,
 '004', 'EX', 'E', NULL,
 0, 2, 'X',
 'SUP008', '005',
 'B', ''),

('800', 'TEST_DP_G', 'PL03', 'MRP03', 'CU', DATEADD(day, 12, CURRENT_DATE),
 'PL014', 'PO014', 'RS014',
 2500, 'EA', 0, 2500,
 10000, 0, 0, 0,
 '004', 'EX', 'E', NULL,
 0, 2, 'X',
 'SUP008', '005',
 'B', ''),

('800', 'TEST_DP_G', 'PL03', 'MRP03', 'CU', DATEADD(day, 19, CURRENT_DATE),
 'PL015', 'PO015', 'RS015',
 2200, 'EA', 0, 2200,
 10000, 0, 0, 0,
 '004', 'EX', 'E', NULL,
 0, 2, 'X',
 'SUP008', '005',
 'B', ''),

('800', 'TEST_DP_G', 'PL03', 'MRP03', 'CU', DATEADD(day, 26, CURRENT_DATE),
 'PL016', 'PO016', 'RS016',
 2800, 'EA', 0, 2800,
 10000, 0, 0, 0,
 '004', 'EX', 'E', NULL,
 0, 2, 'X',
 'SUP009', '005',
 'B', ''),

('800', 'TEST_DP_G', 'PL03', 'MRP03', 'CU', DATEADD(day, 33, CURRENT_DATE),
 'PL017', 'PO017', 'RS017',
 2300, 'EA', 0, 2300,
 10000, 0, 0, 0,
 '004', 'EX', 'E', NULL,
 0, 2, 'X',
 'SUP009', '005',
 'B', ''),

('800', 'TEST_DP_G', 'PL03', 'MRP03', 'CU', DATEADD(day, 40, CURRENT_DATE),
 'PL018', 'PO018', 'RS018',
 2700, 'EA', 0, 2700,
 10000, 0, 0, 0,
 '004', 'EX', 'E', NULL,
 0, 2, 'X',
 'SUP008', '005',
 'B', ''),

('800', 'TEST_DP_G', 'PL03', 'MRP03', 'CU', DATEADD(day, 47, CURRENT_DATE),
 'PL019', 'PO019', 'RS019',
 2400, 'EA', 0, 2400,
 10000, 0, 0, 0,
 '004', 'EX', 'E', NULL,
 0, 2, 'X',
 'SUP009', '005',
 'B', ''),

('800', 'TEST_DP_G', 'PL03', 'MRP03', 'CU', DATEADD(day, 54, CURRENT_DATE),
 'PL020', 'PO020', 'RS020',
 2600, 'EA', 0, 2600,
 10000, 0, 0, 0,
 '004', 'EX', 'E', NULL,
 0, 2, 'X',
 'SUP008', '005',
 'B', ''),

('800', 'TEST_DP_G', 'PL03', 'MRP03', 'CU', DATEADD(day, 61, CURRENT_DATE),
 'PL021', 'PO021', 'RS021',
 2100, 'EA', 0, 2100,
 10000, 0, 0, 0,
 '004', 'EX', 'E', NULL,
 0, 2, 'X',
 'SUP009', '005',
 'B', ''),

('800', 'TEST_DP_G', 'PL03', 'MRP03', 'CU', DATEADD(day, 68, CURRENT_DATE),
 'PL022', 'PO022', 'RS022',
 2900, 'EA', 0, 2900,
 10000, 0, 0, 0,
 '004', 'EX', 'E', NULL,
 0, 2, 'X',
 'SUP008', '005',
 'B', ''),

-- =====================================================
-- Past due requirements (should show HIGH priority in metadata)
-- =====================================================
('800', 'TEST_DP_A', 'PL01', 'MRP01', 'CU', DATEADD(day, -2, CURRENT_DATE),
 'PL023', 'PO023', 'RS023',
 400, 'EA', 0, 400,
 2000, 0, 0, 0,
 '001', 'WB', 'E', NULL,
 0, 5, 'X',
 'SUP001', '001',
 'B', ''),

('800', 'TEST_DP_B', 'PL01', 'MRP01', 'DL', DATEADD(day, -5, CURRENT_DATE),
 'DL011', NULL, NULL,
 1000, 'EA', 0, 500,  -- Partially received (OPNG = 500)
 500, 0, 0, 0,
 '002', 'EX', 'F', NULL,
 0, 7, 'X',
 'SUP002', '002',
 'D', ''),

('800', 'TEST_DP_F', 'PL03', 'MRP03', 'CU', DATEADD(day, -1, CURRENT_DATE),
 'PL024', 'PO024', 'RS024',
 3000, 'KG', 0, 3000,
 15000, 0, 0, 0,
 '001', 'WB', 'E', NULL,
 0, 3, 'X',
 'SUP006', '004',
 'B', '');

-- =====================================================
-- VERIFICATION QUERY
-- =====================================================
SELECT 
    pattern_id,
    material_id,
    plant,
    material_description,
    requirement_date,
    requirement_qty,
    requirement_type,
    requirement_type_desc,
    mrp_controller,
    search_text,
    metadata:priority as priority,
    metadata:season as season,
    metadata:supplier as supplier,
    metadata:open_qty as open_qty
FROM INVENTORY_DEMAND_PATTERNS 
WHERE material_id LIKE 'TEST_DP_%'
ORDER BY requirement_date, material_id;

-- =====================================================
-- SUMMARY BY MATERIAL
-- =====================================================
SELECT 
    material_id,
    plant,
    COUNT(*) as requirement_count,
    SUM(requirement_qty) as total_qty,
    MIN(requirement_date) as first_req_date,
    MAX(requirement_date) as last_req_date,
    LISTAGG(DISTINCT requirement_type_desc, ', ') as requirement_types
FROM INVENTORY_DEMAND_PATTERNS 
WHERE material_id LIKE 'TEST_DP_%'
GROUP BY material_id, plant
ORDER BY material_id;

-- =====================================================
-- DELETE STATEMENT FOR TEST DATA
-- Run this to clean up all test data
-- =====================================================

/*
-- Delete from MD04 first (main table for the view)
DELETE FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 
WHERE MATNR LIKE 'TEST_DP_%';

-- Delete from MARC
DELETE FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MARC 
WHERE MATNR LIKE 'TEST_DP_%';

-- Delete from VBAP - CORRECTED: No MANDT column
DELETE FROM SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.VBAP 
WHERE MATNR LIKE 'TEST_DP_%';

-- Verify deletion
SELECT 'MD04' as table_name, COUNT(*) as remaining_records 
FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 
WHERE MATNR LIKE 'TEST_DP_%'
UNION ALL
SELECT 'MARC', COUNT(*) 
FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MARC 
WHERE MATNR LIKE 'TEST_DP_%'
UNION ALL
SELECT 'VBAP', COUNT(*) 
FROM SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.VBAP 
WHERE MATNR LIKE 'TEST_DP_%';
*/