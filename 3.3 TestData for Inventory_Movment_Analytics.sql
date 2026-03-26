USE WAREHOUSE SAP_COMPUTE;
USE DATABASE SAP_BDC_HORIZON_CATALOG;
USE SCHEMA AGENTS;

/*
Test Data Summary:
Material	Pattern Description	Movement Types	Expected Analytics
TEST_MM_A	High-volume production material	          101 (receipts), 261 (prod issues), 311 (transfers)	High transaction count, mostly goods_issue_count
TEST_MM_B	Finished goods with customer shipments	  101 (receipts), 601 (customer shipments)	            High goods_issue_count, multiple distinct_customers
TEST_MM_C	High-transfer material	                  311 (storage transfers)	                            High transfer_count, zero receipts/issues
TEST_MM_D	Multiple suppliers mixed	              101 (receipts from 3 suppliers), 261 (issues)	        High distinct_suppliers (3), avg_receipt_price varies
TEST_MM_E	Seasonal pattern (Q4 peak)	              101 (receipts), 601 (shipments)	                    Q4: high volumes, Q1: lower volumes
TEST_MM_F	Returns & quality inspections	          101, 122 (returns), 321 (to insp), 103 (from insp)	Complex movement types, special 1xx/3xx combos
TEST_MM_G	Intermittent activity	                  101, 261	                                            Only 2 active months in 2-year period

*/


-- =====================================================
-- TEST DATA GENERATION FOR INVENTORY_MOVEMENT_ANALYTICS
-- All test data is marked with 'TEST_MM_' prefix
-- Created for movement pattern analysis
-- =====================================================

-- Helper: Create a sequence for document numbers
-- Note: Adjust the date ranges based on your current date


INSERT INTO SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MATDOC (
    MBLNR, MJAHR, ZEILE, MATNR, WERKS, LAGER, LGORT,
    BWART, BUDAT, CPUDT, CPUTM, USNAM,
    MENGE, MEINS, DMBTR, WAERS,
    LIFNR, KUNNR, AUFNR, KDAUF, KDPOS,
    XBLNR, BKTXT, BLART, BLDAT,
    CHARG, SOBKZ,
    ERFMG, ERFME, SHKZG
) VALUES 

-- =====================================================
-- MATERIAL A: High-volume production material
-- =====================================================

-- Month 1 (24 months ago) - Regular receipts and issues
('MM001', '2024', '001', 'TEST_MM_A', 'PL01', 'ST01', 'ST01',  -- LAGER/LGORT 4 chars max
 '101', DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)), DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)), '08:15:00', 'TESTUSR1',  -- USNAM 12 chars max
 5000, 'KG', 25000.00, 'USD',
 'SUP001', NULL, NULL, NULL, NULL,
 'REF001', 'Monthly Receipt', 'WE', DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)),
 'BAT01', NULL,  -- CHARG 10 chars max
 5000, 'KG', 'S'),

('MM001', '2024', '002', 'TEST_MM_A', 'PL01', 'ST01', 'ST01',
 '261', DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)) + 5, DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)) + 5, '10:30:00', 'TESTUSR2',
 1200, 'KG', -6000.00, 'USD',
 NULL, NULL, 'PROD01', NULL, NULL,
 'REF002', 'Production Issue', 'WA', DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)) + 5,
 'BAT01', NULL,
 1200, 'KG', 'H'),

('MM001', '2024', '003', 'TEST_MM_A', 'PL01', 'ST01', 'ST01',
 '261', DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)) + 12, DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)) + 12, '14:45:00', 'TESTUSR2',
 1500, 'KG', -7500.00, 'USD',
 NULL, NULL, 'PROD01', NULL, NULL,
 'REF003', 'Production Issue', 'WA', DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)) + 12,
 'BAT01', NULL,
 1500, 'KG', 'H'),

('MM001', '2024', '004', 'TEST_MM_A', 'PL01', 'ST01', 'ST01',
 '261', DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)) + 20, DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)) + 20, '09:15:00', 'TESTUSR2',
 1800, 'KG', -9000.00, 'USD',
 NULL, NULL, 'PROD01', NULL, NULL,
 'REF004', 'Production Issue', 'WA', DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)) + 20,
 'BAT01', NULL,
 1800, 'KG', 'H'),

('MM001', '2024', '005', 'TEST_MM_A', 'PL01', 'ST01', 'ST01',
 '311', DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)) + 25, DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)) + 25, '11:00:00', 'TESTUSR3',
 500, 'KG', 2500.00, 'USD',
 NULL, NULL, NULL, NULL, NULL,
 'REF005', 'Storage Transfer', 'UM', DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)) + 25,
 'BAT01', NULL,
 500, 'KG', 'S'),

-- Month 2 (23 months ago)
('MM002', '2024', '001', 'TEST_MM_A', 'PL01', 'ST01', 'ST01',
 '101', DATEADD(month, -22, DATE_TRUNC('month', CURRENT_DATE)), DATEADD(month, -22, DATE_TRUNC('month', CURRENT_DATE)), '08:00:00', 'TESTUSR1',
 6000, 'KG', 30000.00, 'USD',
 'SUP001', NULL, NULL, NULL, NULL,
 'REF006', 'Monthly Receipt', 'WE', DATEADD(month, -22, DATE_TRUNC('month', CURRENT_DATE)),
 'BAT02', NULL,
 6000, 'KG', 'S'),

('MM002', '2024', '002', 'TEST_MM_A', 'PL01', 'ST01', 'ST01',
 '261', DATEADD(month, -22, DATE_TRUNC('month', CURRENT_DATE)) + 7, DATEADD(month, -22, DATE_TRUNC('month', CURRENT_DATE)) + 7, '13:30:00', 'TESTUSR2',
 2000, 'KG', -10000.00, 'USD',
 NULL, NULL, 'PROD01', NULL, NULL,
 'REF007', 'Production Issue', 'WA', DATEADD(month, -22, DATE_TRUNC('month', CURRENT_DATE)) + 7,
 'BAT02', NULL,
 2000, 'KG', 'H'),

('MM002', '2024', '003', 'TEST_MM_A', 'PL01', 'ST01', 'ST01',
 '261', DATEADD(month, -22, DATE_TRUNC('month', CURRENT_DATE)) + 14, DATEADD(month, -22, DATE_TRUNC('month', CURRENT_DATE)) + 14, '10:45:00', 'TESTUSR2',
 2200, 'KG', -11000.00, 'USD',
 NULL, NULL, 'PROD01', NULL, NULL,
 'REF008', 'Production Issue', 'WA', DATEADD(month, -22, DATE_TRUNC('month', CURRENT_DATE)) + 14,
 'BAT02', NULL,
 2200, 'KG', 'H'),

('MM002', '2024', '004', 'TEST_MM_A', 'PL01', 'ST01', 'ST01',
 '261', DATEADD(month, -22, DATE_TRUNC('month', CURRENT_DATE)) + 21, DATEADD(month, -22, DATE_TRUNC('month', CURRENT_DATE)) + 21, '15:20:00', 'TESTUSR2',
 1500, 'KG', -7500.00, 'USD',
 NULL, NULL, 'PROD01', NULL, NULL,
 'REF009', 'Production Issue', 'WA', DATEADD(month, -22, DATE_TRUNC('month', CURRENT_DATE)) + 21,
 'BAT02', NULL,
 1500, 'KG', 'H'),

-- Month 3 (22 months ago)
('MM003', '2024', '001', 'TEST_MM_A', 'PL01', 'ST01', 'ST01',
 '101', DATEADD(month, -21, DATE_TRUNC('month', CURRENT_DATE)), DATEADD(month, -21, DATE_TRUNC('month', CURRENT_DATE)), '09:30:00', 'TESTUSR1',
 8000, 'KG', 40000.00, 'USD',
 'SUP001', NULL, NULL, NULL, NULL,
 'REF010', 'Monthly Receipt', 'WE', DATEADD(month, -21, DATE_TRUNC('month', CURRENT_DATE)),
 'BAT03', NULL,
 8000, 'KG', 'S'),

('MM003', '2024', '002', 'TEST_MM_A', 'PL01', 'ST01', 'ST01',
 '261', DATEADD(month, -21, DATE_TRUNC('month', CURRENT_DATE)) + 3, DATEADD(month, -21, DATE_TRUNC('month', CURRENT_DATE)) + 3, '08:45:00', 'TESTUSR2',
 1800, 'KG', -9000.00, 'USD',
 NULL, NULL, 'PROD01', NULL, NULL,
 'REF011', 'Production Issue', 'WA', DATEADD(month, -21, DATE_TRUNC('month', CURRENT_DATE)) + 3,
 'BAT03', NULL,
 1800, 'KG', 'H'),

('MM003', '2024', '003', 'TEST_MM_A', 'PL01', 'ST01', 'ST01',
 '261', DATEADD(month, -21, DATE_TRUNC('month', CURRENT_DATE)) + 8, DATEADD(month, -21, DATE_TRUNC('month', CURRENT_DATE)) + 8, '11:30:00', 'TESTUSR2',
 2100, 'KG', -10500.00, 'USD',
 NULL, NULL, 'PROD01', NULL, NULL,
 'REF012', 'Production Issue', 'WA', DATEADD(month, -21, DATE_TRUNC('month', CURRENT_DATE)) + 8,
 'BAT03', NULL,
 2100, 'KG', 'H'),

('MM003', '2024', '004', 'TEST_MM_A', 'PL01', 'ST01', 'ST01',
 '261', DATEADD(month, -21, DATE_TRUNC('month', CURRENT_DATE)) + 15, DATEADD(month, -21, DATE_TRUNC('month', CURRENT_DATE)) + 15, '14:15:00', 'TESTUSR2',
 1900, 'KG', -9500.00, 'USD',
 NULL, NULL, 'PROD01', NULL, NULL,
 'REF013', 'Production Issue', 'WA', DATEADD(month, -21, DATE_TRUNC('month', CURRENT_DATE)) + 15,
 'BAT03', NULL,
 1900, 'KG', 'H'),

-- =====================================================
-- MATERIAL B: Finished goods with customer shipments
-- =====================================================

('MM004', '2024', '001', 'TEST_MM_B', 'PL01', 'ST02', 'ST02',
 '101', DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)) + 2, DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)) + 2, '13:45:00', 'TESTUSR1',
 2000, 'EA', 40000.00, 'USD',
 'SUP002', NULL, NULL, NULL, NULL,
 'REF015', 'FG Receipt', 'WE', DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)) + 2,
 'BAT10', NULL,
 2000, 'EA', 'S'),

('MM004', '2024', '002', 'TEST_MM_B', 'PL01', 'ST02', 'ST02',
 '601', DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)) + 10, DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)) + 10, '09:30:00', 'TESTUSR4',
 500, 'EA', -10000.00, 'USD',
 NULL, 'CUST01', NULL, 'SO1001', '0010',
 'REF016', 'Cust Ship', 'WA', DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)) + 10,
 'BAT10', NULL,
 500, 'EA', 'H'),

('MM004', '2024', '003', 'TEST_MM_B', 'PL01', 'ST02', 'ST02',
 '601', DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)) + 18, DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)) + 18, '11:15:00', 'TESTUSR4',
 700, 'EA', -14000.00, 'USD',
 NULL, 'CUST02', NULL, 'SO1002', '0010',
 'REF017', 'Cust Ship', 'WA', DATEADD(month, -23, DATE_TRUNC('month', CURRENT_DATE)) + 18,
 'BAT10', NULL,
 700, 'EA', 'H'),

('MM005', '2024', '001', 'TEST_MM_B', 'PL01', 'ST02', 'ST02',
 '101', DATEADD(month, -22, DATE_TRUNC('month', CURRENT_DATE)) + 3, DATEADD(month, -22, DATE_TRUNC('month', CURRENT_DATE)) + 3, '10:30:00', 'TESTUSR1',
 2500, 'EA', 50000.00, 'USD',
 'SUP002', NULL, NULL, NULL, NULL,
 'REF018', 'FG Receipt', 'WE', DATEADD(month, -22, DATE_TRUNC('month', CURRENT_DATE)) + 3,
 'BAT11', NULL,
 2500, 'EA', 'S'),

('MM005', '2024', '002', 'TEST_MM_B', 'PL01', 'ST02', 'ST02',
 '601', DATEADD(month, -22, DATE_TRUNC('month', CURRENT_DATE)) + 8, DATEADD(month, -22, DATE_TRUNC('month', CURRENT_DATE)) + 8, '14:20:00', 'TESTUSR4',
 400, 'EA', -8000.00, 'USD',
 NULL, 'CUST03', NULL, 'SO1003', '0010',
 'REF019', 'Cust Ship', 'WA', DATEADD(month, -22, DATE_TRUNC('month', CURRENT_DATE)) + 8,
 'BAT11', NULL,
 400, 'EA', 'H'),

('MM005', '2024', '003', 'TEST_MM_B', 'PL01', 'ST02', 'ST02',
 '601', DATEADD(month, -22, DATE_TRUNC('month', CURRENT_DATE)) + 15, DATEADD(month, -22, DATE_TRUNC('month', CURRENT_DATE)) + 15, '09:45:00', 'TESTUSR4',
 600, 'EA', -12000.00, 'USD',
 NULL, 'CUST01', NULL, 'SO1004', '0010',
 'REF020', 'Cust Ship', 'WA', DATEADD(month, -22, DATE_TRUNC('month', CURRENT_DATE)) + 15,
 'BAT11', NULL,
 600, 'EA', 'H'),

-- =====================================================
-- MATERIAL C: High-transfer material (3xx movements)
-- =====================================================

('MM006', '2024', '001', 'TEST_MM_C', 'PL02', 'STA1', 'STA1',  -- Changed from STORA to STA1 (4 chars)
 '101', DATEADD(month, -20, DATE_TRUNC('month', CURRENT_DATE)), DATEADD(month, -20, DATE_TRUNC('month', CURRENT_DATE)), '08:00:00', 'TESTUSR1',
 3000, 'M', 15000.00, 'USD',
 'SUP003', NULL, NULL, NULL, NULL,
 'REF021', 'Receipt', 'WE', DATEADD(month, -20, DATE_TRUNC('month', CURRENT_DATE)),
 'BAT20', NULL,
 3000, 'M', 'S'),

('MM006', '2024', '002', 'TEST_MM_C', 'PL02', 'STA1', 'STA1',
 '311', DATEADD(month, -20, DATE_TRUNC('month', CURRENT_DATE)) + 2, DATEADD(month, -20, DATE_TRUNC('month', CURRENT_DATE)) + 2, '10:15:00', 'TESTUSR3',
 800, 'M', 4000.00, 'USD',
 NULL, NULL, NULL, NULL, NULL,
 'REF022', 'To STB1', 'UM', DATEADD(month, -20, DATE_TRUNC('month', CURRENT_DATE)) + 2,
 'BAT20', NULL,
 800, 'M', 'S'),

('MM006', '2024', '003', 'TEST_MM_C', 'PL02', 'STB1', 'STB1',  -- Changed from STORB to STB1
 '311', DATEADD(month, -20, DATE_TRUNC('month', CURRENT_DATE)) + 2, DATEADD(month, -20, DATE_TRUNC('month', CURRENT_DATE)) + 2, '10:16:00', 'TESTUSR3',
 800, 'M', 4000.00, 'USD',
 NULL, NULL, NULL, NULL, NULL,
 'REF023', 'From STA1', 'UM', DATEADD(month, -20, DATE_TRUNC('month', CURRENT_DATE)) + 2,
 'BAT20', NULL,
 800, 'M', 'H'),

('MM006', '2024', '004', 'TEST_MM_C', 'PL02', 'STA1', 'STA1',
 '311', DATEADD(month, -20, DATE_TRUNC('month', CURRENT_DATE)) + 5, DATEADD(month, -20, DATE_TRUNC('month', CURRENT_DATE)) + 5, '14:30:00', 'TESTUSR3',
 500, 'M', 2500.00, 'USD',
 NULL, NULL, NULL, NULL, NULL,
 'REF024', 'To STC1', 'UM', DATEADD(month, -20, DATE_TRUNC('month', CURRENT_DATE)) + 5,
 'BAT20', NULL,
 500, 'M', 'S'),

('MM006', '2024', '005', 'TEST_MM_C', 'PL02', 'STC1', 'STC1',  -- Changed from STORC to STC1
 '311', DATEADD(month, -20, DATE_TRUNC('month', CURRENT_DATE)) + 5, DATEADD(month, -20, DATE_TRUNC('month', CURRENT_DATE)) + 5, '14:31:00', 'TESTUSR3',
 500, 'M', 2500.00, 'USD',
 NULL, NULL, NULL, NULL, NULL,
 'REF025', 'From STA1', 'UM', DATEADD(month, -20, DATE_TRUNC('month', CURRENT_DATE)) + 5,
 'BAT20', NULL,
 500, 'M', 'H'),

-- =====================================================
-- MATERIAL D: Multiple suppliers
-- =====================================================

('MM007', '2024', '001', 'TEST_MM_D', 'PL01', 'STD1', 'STD1',  -- Changed from STORD to STD1
 '101', DATEADD(month, -18, DATE_TRUNC('month', CURRENT_DATE)), DATEADD(month, -18, DATE_TRUNC('month', CURRENT_DATE)), '11:30:00', 'TESTUSR1',
 1000, 'EA', 5000.00, 'USD',
 'SUP004', NULL, NULL, NULL, NULL,
 'REF026', 'Rcpt S4', 'WE', DATEADD(month, -18, DATE_TRUNC('month', CURRENT_DATE)),
 'BAT30', NULL,
 1000, 'EA', 'S'),

('MM007', '2024', '002', 'TEST_MM_D', 'PL01', 'STD1', 'STD1',
 '101', DATEADD(month, -18, DATE_TRUNC('month', CURRENT_DATE)) + 7, DATEADD(month, -18, DATE_TRUNC('month', CURRENT_DATE)) + 7, '13:45:00', 'TESTUSR1',
 800, 'EA', 4000.00, 'USD',
 'SUP005', NULL, NULL, NULL, NULL,
 'REF027', 'Rcpt S5', 'WE', DATEADD(month, -18, DATE_TRUNC('month', CURRENT_DATE)) + 7,
 'BAT31', NULL,
 800, 'EA', 'S'),

('MM007', '2024', '003', 'TEST_MM_D', 'PL01', 'STD1', 'STD1',
 '101', DATEADD(month, -18, DATE_TRUNC('month', CURRENT_DATE)) + 14, DATEADD(month, -18, DATE_TRUNC('month', CURRENT_DATE)) + 14, '10:15:00', 'TESTUSR1',
 1200, 'EA', 6000.00, 'USD',
 'SUP006', NULL, NULL, NULL, NULL,
 'REF028', 'Rcpt S6', 'WE', DATEADD(month, -18, DATE_TRUNC('month', CURRENT_DATE)) + 14,
 'BAT32', NULL,
 1200, 'EA', 'S'),

('MM007', '2024', '004', 'TEST_MM_D', 'PL01', 'STD1', 'STD1',
 '261', DATEADD(month, -18, DATE_TRUNC('month', CURRENT_DATE)) + 20, DATEADD(month, -18, DATE_TRUNC('month', CURRENT_DATE)) + 20, '15:30:00', 'TESTUSR2',
 1500, 'EA', -7500.00, 'USD',
 NULL, NULL, 'PROD02', NULL, NULL,
 'REF029', 'Prod Issue', 'WA', DATEADD(month, -18, DATE_TRUNC('month', CURRENT_DATE)) + 20,
 NULL, NULL,
 1500, 'EA', 'H'),

-- =====================================================
-- MATERIAL E: Seasonal pattern
-- =====================================================

-- Q4 - Peak
('MM008', '2024', '001', 'TEST_MM_E', 'PL03', 'STE1', 'STE1',  -- Changed from STORE to STE1
 '101', DATEADD(month, -14, DATE_TRUNC('month', CURRENT_DATE)), DATEADD(month, -14, DATE_TRUNC('month', CURRENT_DATE)), '09:00:00', 'TESTUSR1',
 10000, 'EA', 50000.00, 'USD',
 'SUP007', NULL, NULL, NULL, NULL,
 'REF030', 'Peak Rcpt', 'WE', DATEADD(month, -14, DATE_TRUNC('month', CURRENT_DATE)),
 'BAT40', NULL,
 10000, 'EA', 'S'),

('MM008', '2024', '002', 'TEST_MM_E', 'PL03', 'STE1', 'STE1',
 '601', DATEADD(month, -14, DATE_TRUNC('month', CURRENT_DATE)) + 5, DATEADD(month, -14, DATE_TRUNC('month', CURRENT_DATE)) + 5, '14:20:00', 'TESTUSR4',
 2000, 'EA', -10000.00, 'USD',
 NULL, 'CUST10', NULL, 'SO2001', '0010',
 'REF031', 'Ship C10', 'WA', DATEADD(month, -14, DATE_TRUNC('month', CURRENT_DATE)) + 5,
 'BAT40', NULL,
 2000, 'EA', 'H'),

('MM008', '2024', '003', 'TEST_MM_E', 'PL03', 'STE1', 'STE1',
 '601', DATEADD(month, -14, DATE_TRUNC('month', CURRENT_DATE)) + 8, DATEADD(month, -14, DATE_TRUNC('month', CURRENT_DATE)) + 8, '11:45:00', 'TESTUSR4',
 2500, 'EA', -12500.00, 'USD',
 NULL, 'CUST11', NULL, 'SO2002', '0010',
 'REF032', 'Ship C11', 'WA', DATEADD(month, -14, DATE_TRUNC('month', CURRENT_DATE)) + 8,
 'BAT40', NULL,
 2500, 'EA', 'H'),

-- Q1 - Lower volume
('MM009', '2024', '001', 'TEST_MM_E', 'PL03', 'STE1', 'STE1',
 '101', DATEADD(month, -9, DATE_TRUNC('month', CURRENT_DATE)), DATEADD(month, -9, DATE_TRUNC('month', CURRENT_DATE)), '09:30:00', 'TESTUSR1',
 5000, 'EA', 25000.00, 'USD',
 'SUP007', NULL, NULL, NULL, NULL,
 'REF033', 'Reg Rcpt', 'WE', DATEADD(month, -9, DATE_TRUNC('month', CURRENT_DATE)),
 'BAT41', NULL,
 5000, 'EA', 'S'),

('MM009', '2024', '002', 'TEST_MM_E', 'PL03', 'STE1', 'STE1',
 '601', DATEADD(month, -9, DATE_TRUNC('month', CURRENT_DATE)) + 10, DATEADD(month, -9, DATE_TRUNC('month', CURRENT_DATE)) + 10, '13:45:00', 'TESTUSR4',
 1200, 'EA', -6000.00, 'USD',
 NULL, 'CUST10', NULL, 'SO2003', '0010',
 'REF034', 'Ship C10', 'WA', DATEADD(month, -9, DATE_TRUNC('month', CURRENT_DATE)) + 10,
 'BAT41', NULL,
 1200, 'EA', 'H'),

-- =====================================================
-- MATERIAL F: Returns and quality inspections
-- =====================================================

('MM010', '2024', '001', 'TEST_MM_F', 'PL01', 'STQ1', 'STQ1',  -- Changed from STORQ to STQ1
 '101', DATEADD(month, -6, DATE_TRUNC('month', CURRENT_DATE)), DATEADD(month, -6, DATE_TRUNC('month', CURRENT_DATE)), '08:30:00', 'TESTUSR1',
 2000, 'EA', 10000.00, 'USD',
 'SUP008', NULL, NULL, NULL, NULL,
 'REF035', 'Init Rcpt', 'WE', DATEADD(month, -6, DATE_TRUNC('month', CURRENT_DATE)),
 'BAT50', NULL,
 2000, 'EA', 'S'),

('MM010', '2024', '002', 'TEST_MM_F', 'PL01', 'STQ1', 'STQ1',
 '122', DATEADD(month, -6, DATE_TRUNC('month', CURRENT_DATE)) + 3, DATEADD(month, -6, DATE_TRUNC('month', CURRENT_DATE)) + 3, '11:15:00', 'TESTUSR5',
 200, 'EA', -1000.00, 'USD',
 NULL, NULL, NULL, NULL, NULL,
 'REF036', 'Return', 'WE', DATEADD(month, -6, DATE_TRUNC('month', CURRENT_DATE)) + 3,
 'BAT50', NULL,
 200, 'EA', 'H'),

('MM010', '2024', '003', 'TEST_MM_F', 'PL01', 'STQ1', 'STQ1',
 '321', DATEADD(month, -6, DATE_TRUNC('month', CURRENT_DATE)) + 7, DATEADD(month, -6, DATE_TRUNC('month', CURRENT_DATE)) + 7, '14:45:00', 'TESTUSR3',
 300, 'EA', 1500.00, 'USD',
 NULL, NULL, NULL, NULL, NULL,
 'REF037', 'To Insp', 'UM', DATEADD(month, -6, DATE_TRUNC('month', CURRENT_DATE)) + 7,
 'BAT50', NULL,
 300, 'EA', 'S'),

('MM010', '2024', '004', 'TEST_MM_F', 'PL01', 'STI1', 'STI1',  -- Changed from STORI to STI1
 '321', DATEADD(month, -6, DATE_TRUNC('month', CURRENT_DATE)) + 7, DATEADD(month, -6, DATE_TRUNC('month', CURRENT_DATE)) + 7, '14:46:00', 'TESTUSR3',
 300, 'EA', 1500.00, 'USD',
 NULL, NULL, NULL, NULL, NULL,
 'REF038', 'To Insp', 'UM', DATEADD(month, -6, DATE_TRUNC('month', CURRENT_DATE)) + 7,
 'BAT50', NULL,
 300, 'EA', 'H'),

('MM010', '2024', '005', 'TEST_MM_F', 'PL01', 'STI1', 'STI1',
 '103', DATEADD(month, -6, DATE_TRUNC('month', CURRENT_DATE)) + 14, DATEADD(month, -6, DATE_TRUNC('month', CURRENT_DATE)) + 14, '09:30:00', 'TESTUSR5',
 250, 'EA', 1250.00, 'USD',
 NULL, NULL, NULL, NULL, NULL,
 'REF039', 'Frm Insp', 'WE', DATEADD(month, -6, DATE_TRUNC('month', CURRENT_DATE)) + 14,
 'BAT50', NULL,
 250, 'EA', 'S'),

-- =====================================================
-- MATERIAL G: Intermittent activity
-- =====================================================

('MM011', '2024', '001', 'TEST_MM_G', 'PL02', 'STG1', 'STG1',  -- Changed from STORG to STG1
 '101', DATEADD(month, -6, DATE_TRUNC('month', CURRENT_DATE)), DATEADD(month, -6, DATE_TRUNC('month', CURRENT_DATE)), '10:00:00', 'TESTUSR1',
 1500, 'KG', 7500.00, 'USD',
 'SUP009', NULL, NULL, NULL, NULL,
 'REF040', 'Receipt', 'WE', DATEADD(month, -6, DATE_TRUNC('month', CURRENT_DATE)),
 'BAT60', NULL,
 1500, 'KG', 'S'),

('MM011', '2024', '002', 'TEST_MM_G', 'PL02', 'STG1', 'STG1',
 '261', DATEADD(month, -6, DATE_TRUNC('month', CURRENT_DATE)) + 15, DATEADD(month, -6, DATE_TRUNC('month', CURRENT_DATE)) + 15, '13:30:00', 'TESTUSR2',
 800, 'KG', -4000.00, 'USD',
 NULL, NULL, 'PROD03', NULL, NULL,
 'REF041', 'Prod Issue', 'WA', DATEADD(month, -6, DATE_TRUNC('month', CURRENT_DATE)) + 15,
 'BAT60', NULL,
 800, 'KG', 'H'),

('MM012', '2024', '001', 'TEST_MM_G', 'PL02', 'STG1', 'STG1',
 '101', DATEADD(month, -3, DATE_TRUNC('month', CURRENT_DATE)), DATEADD(month, -3, DATE_TRUNC('month', CURRENT_DATE)), '09:15:00', 'TESTUSR1',
 1200, 'KG', 6000.00, 'USD',
 'SUP009', NULL, NULL, NULL, NULL,
 'REF042', 'Receipt', 'WE', DATEADD(month, -3, DATE_TRUNC('month', CURRENT_DATE)),
 'BAT61', NULL,
 1200, 'KG', 'S'),

('MM012', '2024', '002', 'TEST_MM_G', 'PL02', 'STG1', 'STG1',
 '261', DATEADD(month, -3, DATE_TRUNC('month', CURRENT_DATE)) + 10, DATEADD(month, -3, DATE_TRUNC('month', CURRENT_DATE)) + 10, '15:45:00', 'TESTUSR2',
 600, 'KG', -3000.00, 'USD',
 NULL, NULL, 'PROD03', NULL, NULL,
 'REF043', 'Prod Issue', 'WA', DATEADD(month, -3, DATE_TRUNC('month', CURRENT_DATE)) + 10,
 'BAT61', NULL,
 600, 'KG', 'H');

-- =====================================================
-- VERIFICATION QUERY
-- =====================================================
SELECT 
    material_id,
    plant,
    movement_month,
    transaction_count,
    goods_receipt_count,
    goods_issue_count,
    transfer_count,
    total_receipt_qty,
    total_issue_qty,
    avg_receipt_price,
    distinct_suppliers,
    distinct_customers,
    most_common_movement_type
FROM INVENTORY_MOVEMENT_ANALYTICS 
WHERE material_id LIKE 'TEST_MM_%'
ORDER BY material_id, movement_month DESC;


-- =====================================================
-- DELETE STATEMENT FOR TEST DATA
-- =====================================================

/*
-- Delete all test data with TEST_MM_ prefix
DELETE FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MATDOC 
WHERE MATNR LIKE 'TEST_MM_%';

-- Verify deletion
SELECT COUNT(*) as remaining_test_records
FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MATDOC 
WHERE MATNR LIKE 'TEST_MM_%';
*/