- Create the main catalog database
-- DROP DATABASE SAP_BDC_HORIZON_CATALOG;
USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE WAREHOUSE SAP_COMPUTE
  WITH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  COMMENT = 'Warehouse for analytics workloads';
  
USE WAREHOUSE SAP_COMPUTE;

CREATE OR REPLACE DATABASE SAP_BDC_HORIZON_CATALOG;
CREATE ROLE sap_scenario_1_role COMMENT = 'Role for sap scenario.';
-- Grant usage on a warehouse
GRANT USAGE ON WAREHOUSE SAP_COMPUTE TO ROLE sap_scenario_1_role;

GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE sap_scenario_1_role;
SET my_user = CURRENT_USER();
GRANT ROLE sap_scenario_1_role to user IDENTIFIER($my_user);
GRANT USAGE ON DATABASE SAP_BDC_HORIZON_CATALOG TO ROLE sap_scenario_1_role;

-- Create schemas for each SAP instance type
CREATE OR REPLACE SCHEMA SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS;
CREATE OR REPLACE SCHEMA SAP_BDC_HORIZON_CATALOG.S4HANA_APAC;
CREATE OR REPLACE SCHEMA SAP_BDC_HORIZON_CATALOG.S4HANA_EMEA;
CREATE OR REPLACE SCHEMA SAP_BDC_HORIZON_CATALOG.ECC_AMERICAS;
CREATE OR REPLACE SCHEMA SAP_BDC_HORIZON_CATALOG.ENTERPRISE_PLANNING;
CREATE OR REPLACE SCHEMA SAP_BDC_HORIZON_CATALOG.FINANCE_SYSTEMS;


-------------------------------------------------------------------
-- SAP Table creation
-- Agent 1: Autonomous Inventory Replenishment Agent Tables
-- ---------------------------------------------------------
-- Table: SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MATDOC
-- Table: SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04
-- Table: SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.ME2N
-- Table: SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MARC
-- ---------------------------------------------------------
-- Agent 2: Customer ROI Optimizer Agent Tables
-- ---------------------------------------------------------
-- Table: SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.VBAK
-- Table: SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.VBAP
-- Table: SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.LIKP
-- Table: SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.LIPS
-- Table: SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.KONV
-- Table: SAP_BDC_HORIZON_CATALOG.S4HANA_EMEA.ACDOCA
-- Table: SAP_BDC_HORIZON_CATALOG.S4HANA_EMEA.FAGLFLEXA
-- ---------------------------------------------------------
-- Agent 3: Strategic Capacity Planning Agent Tables
-- ---------------------------------------------------------
-- Table: SAP_BDC_HORIZON_CATALOG.ECC_AMERICAS.PA0007
-- Table: SAP_BDC_HORIZON_CATALOG.ECC_AMERICAS.PA0008
-- Table: SAP_BDC_HORIZON_CATALOG.ECC_AMERICAS.PP01
-- Table: SAP_BDC_HORIZON_CATALOG.ENTERPRISE_PLANNING.0BWPLAN
-- Table: SAP_BDC_HORIZON_CATALOG.ENTERPRISE_PLANNING.MSDP
-- Finance Systems Tables
-- Table: SAP_BDC_HORIZON_CATALOG.FINANCE_SYSTEMS.FBL1N
-- Table: SAP_BDC_HORIZON_CATALOG.FINANCE_SYSTEMS.FDMDELTA
-- ---------------------------------------------------------

-- Agent 1: Autonomous Inventory Replenishment Agent Tables
-- Table: SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MATDOC

CREATE OR REPLACE TABLE SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MATDOC (
    -- Key Fields
    MBLNR VARCHAR(10) COMMENT 'Material Document Number',
    MJAHR VARCHAR(4) COMMENT 'Material Document Year',
    ZEILE VARCHAR(4) COMMENT 'Item in Material Document',
    
    -- Material & Plant
    MATNR VARCHAR(18) COMMENT 'Material Number',
    WERKS VARCHAR(4) COMMENT 'Plant',
    LAGER VARCHAR(4) COMMENT 'Storage Location',
    LGORT VARCHAR(4) COMMENT 'Storage Location (alternative)',
    
    -- Movement Data
    BWART VARCHAR(3) COMMENT 'Movement Type',
    BUDAT DATE COMMENT 'Posting Date',
    CPUDT DATE COMMENT 'Entry Date',
    CPUTM TIME COMMENT 'Entry Time',
    USNAM VARCHAR(12) COMMENT 'User Name',
    
    -- Quantities & Values
    MENGE DECIMAL(13,3) COMMENT 'Quantity',
    MEINS VARCHAR(3) COMMENT 'Base Unit of Measure',
    DMBTR DECIMAL(13,2) COMMENT 'Amount in Local Currency',
    WAERS VARCHAR(5) COMMENT 'Currency Key',
    
    -- Reference Documents
    LIFNR VARCHAR(10) COMMENT 'Vendor Account Number',
    KUNNR VARCHAR(10) COMMENT 'Customer Number',
    AUFNR VARCHAR(12) COMMENT 'Order Number',
    KDAUF VARCHAR(10) COMMENT 'Sales Order Number',
    KDPOS VARCHAR(6) COMMENT 'Sales Order Item',
    
    -- Status Flags
    XBLNR VARCHAR(16) COMMENT 'Reference Document Number',
    BKTXT VARCHAR(25) COMMENT 'Document Header Text',
    BLART VARCHAR(2) COMMENT 'Document Type',
    BLDAT DATE COMMENT 'Document Date',
    
    -- Batch & Serial Numbers
    CHARG VARCHAR(10) COMMENT 'Batch Number',
    SOBKZ VARCHAR(1) COMMENT 'Special Stock Indicator',
    
    -- Technical Fields
    ERFMG DECIMAL(13,3) COMMENT 'Quantity in Unit of Entry',
    ERFME VARCHAR(3) COMMENT 'Unit of Entry',
    SHKZG VARCHAR(1) COMMENT 'Debit/Credit Indicator',
    
    PRIMARY KEY (MBLNR, MJAHR, ZEILE)
);

-- Table: SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04
CREATE OR REPLACE TABLE SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04 (
    -- Key Fields
    MANDT VARCHAR(3) COMMENT 'Client',
    MATNR VARCHAR(18) COMMENT 'Material Number',
    WERKS VARCHAR(4) COMMENT 'Plant',
    BERID VARCHAR(10) COMMENT 'MRP Area',
    
    -- Requirements Data
    DTART VARCHAR(2) COMMENT 'Requirement Type',
    DTERQ DATE COMMENT 'Requirements Date',
    PLNUM VARCHAR(10) COMMENT 'Planned Order',
    PLORD VARCHAR(10) COMMENT 'Purchase Order',
    RESB VARCHAR(10) COMMENT 'Reservation',
    
    -- Quantities
    MENGE DECIMAL(13,3) COMMENT 'Requirement Quantity',
    MEINS VARCHAR(3) COMMENT 'Base Unit',
    ENMNG DECIMAL(13,3) COMMENT 'Received Quantity',
    OPNG DECIMAL(13,3) COMMENT 'Open Quantity',
    
    -- Availability
    LABST DECIMAL(13,3) COMMENT 'Unrestricted Stock',
    UMLMC DECIMAL(13,3) COMMENT 'Stock in Transfer',
    INSME DECIMAL(13,3) COMMENT 'Stock in Quality Inspection',
    EINME DECIMAL(13,3) COMMENT 'Total Receipts Quantity',
    
    -- MRP Data
    DISPO VARCHAR(3) COMMENT 'MRP Controller',
    DISLS VARCHAR(2) COMMENT 'Lot Sizing Procedure',
    BESKZ VARCHAR(1) COMMENT 'Procurement Type',
    SOBSL VARCHAR(2) COMMENT 'Special Procurement Type',
    
    -- Dates
    WZEIT DECIMAL(3) COMMENT 'Goods Receipt Processing Time',
    PLIFZ DECIMAL(3) COMMENT 'Planned Delivery Time',
    WEBRE VARCHAR(1) COMMENT 'Goods Receipt Indicator',
    
    -- Supplier Info
    LIFNR VARCHAR(10) COMMENT 'Preferred Vendor',
    EKGRP VARCHAR(3) COMMENT 'Purchasing Group',
    
    -- Status
    DELKZ VARCHAR(1) COMMENT 'MRP element',
    DELET VARCHAR(1) COMMENT 'Deletion Flag',
    
    PRIMARY KEY (MANDT, MATNR, WERKS, BERID, DTERQ, PLNUM)
);

-- Table: SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.ME2N
CREATE OR REPLACE TABLE SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.ME2N (
    -- Key Fields
    EBELN VARCHAR(10) COMMENT 'Purchase Order Number',
    EBELP VARCHAR(5) COMMENT 'Purchase Order Item',
    
    -- Supplier
    LIFNR VARCHAR(10) COMMENT 'Vendor Account Number',
    NAME1 VARCHAR(35) COMMENT 'Vendor Name',
    EKORG VARCHAR(4) COMMENT 'Purchasing Organization',
    EKGRP VARCHAR(3) COMMENT 'Purchasing Group',
    
    -- Material
    MATNR VARCHAR(18) COMMENT 'Material Number',
    TXZ01 VARCHAR(40) COMMENT 'Short Text',
    WERKS VARCHAR(4) COMMENT 'Plant',
    LGORT VARCHAR(4) COMMENT 'Storage Location',
    
    -- Quantities
    MENGE DECIMAL(13,3) COMMENT 'PO Quantity',
    MEINS VARCHAR(3) COMMENT 'Order Unit',
    BSTMG DECIMAL(13,3) COMMENT 'Quantity Ordered',
    WEMNG DECIMAL(13,3) COMMENT 'GR Quantity',
    REMNG DECIMAL(13,3) COMMENT 'Open Quantity',
    
    -- Dates
    BEDAT DATE COMMENT 'Purchase Order Date',
    EINDT DATE COMMENT 'Delivery Date',
    BSTYP VARCHAR(1) COMMENT 'Purchasing Document Category',
    BSART VARCHAR(4) COMMENT 'Purchase Order Type',
    
    -- Pricing
    NETPR DECIMAL(11,2) COMMENT 'Net Price',
    PEINH DECIMAL(5) COMMENT 'Price Unit',
    WAERS VARCHAR(5) COMMENT 'Currency Key',
    BRTWR DECIMAL(13,2) COMMENT 'Gross Order Value',
    
    -- Delivery & Invoicing
    LPEIN VARCHAR(2) COMMENT 'Delivery Date Indicator',
    LFMON VARCHAR(2) COMMENT 'Month of Delivery',
    VRTKZ VARCHAR(1) COMMENT 'Distribution Indicator',
    VERSART VARCHAR(2) COMMENT 'Shipping Type',
    
    -- Status
    LOEKZ VARCHAR(1) COMMENT 'Deletion Indicator',
    STATU VARCHAR(1) COMMENT 'Status',
    MEMORY VARCHAR(1) COMMENT 'Purchase Order in Memory',
    
    PRIMARY KEY (EBELN, EBELP)
);

-- Table: SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MARC
CREATE OR REPLACE TABLE SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MARC (
    -- Key Fields
    MANDT VARCHAR(3) COMMENT 'Client',
    MATNR VARCHAR(18) COMMENT 'Material Number',
    WERKS VARCHAR(4) COMMENT 'Plant',
    
    -- MRP Parameters
    DISPO VARCHAR(3) COMMENT 'MRP Controller',
    DISMM VARCHAR(2) COMMENT 'MRP Type',
    DISPO_OLD VARCHAR(3) COMMENT 'Old MRP Controller',
    BESKZ VARCHAR(1) COMMENT 'Procurement Type',
    SOBSL VARCHAR(2) COMMENT 'Special Procurement Type',
    MINBE DECIMAL(13,3) COMMENT 'Reorder Point',
    EISBE DECIMAL(13,3) COMMENT 'Safety Stock',
    BSTMI DECIMAL(13,3) COMMENT 'Minimum Lot Size',
    BSTMA DECIMAL(13,3) COMMENT 'Maximum Lot Size',
    BSTFE DECIMAL(13,3) COMMENT 'Fixed Lot Size',
    
    -- Time Parameters
    PLIFZ DECIMAL(3) COMMENT 'Planned Delivery Time',
    WEBAZ DECIMAL(3) COMMENT 'Goods Receipt Processing Time',
    BEARZ DECIMAL(3) COMMENT 'Processing Time',
    RUEZT DECIMAL(3) COMMENT 'Setup Time',
    TRANSZ DECIMAL(3) COMMENT 'Transportation Time',
    
    -- Lot Sizing
    LOSGR VARCHAR(4) COMMENT 'Lot Sizing Procedure',
    PERKZ VARCHAR(1) COMMENT 'Lot Sizing Period',
    PERIV VARCHAR(2) COMMENT 'Fiscal Year Variant',
    AUSSS DECIMAL(1) COMMENT 'Lot Sizing Procedure Category',
    
    -- Consumption Values
    KZPRD VARCHAR(1) COMMENT 'Planned Delivery Time Indicator',
    VRMOD VARCHAR(1) COMMENT 'Consumption Mode',
    VINT1 VARCHAR(1) COMMENT 'Consumption Period',
    VINT2 VARCHAR(1) COMMENT 'Forward Consumption Period',
    
    -- Scheduling
    FHORI VARCHAR(3) COMMENT 'Scheduling Margin Key',
    WEBRE VARCHAR(1) COMMENT 'Goods Receipt Indicator',
    PRCTL VARCHAR(2) COMMENT 'Forecast Model',
    
    -- Storage & Handling
    LGPRO VARCHAR(4) COMMENT 'Storage Location for Production',
    LGRAD DECIMAL(5,2) COMMENT 'Storage Bin Utilization',
    DISPR VARCHAR(4) COMMENT 'Distribution Profile',
    
    PRIMARY KEY (MANDT, MATNR, WERKS)
);
----------------------------------------------------
-- Agent 2: Customer ROI Optimizer Agent Tables
----------------------------------------------------

--Table: SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.VBAK
CREATE OR REPLACE TABLE SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.VBAK (
    -- Key Fields
    VBELN VARCHAR(10) COMMENT 'Sales Document',
    ERDAT DATE COMMENT 'Created On',
    ERZET TIME COMMENT 'Entry Time',
    ERNAM VARCHAR(12) COMMENT 'Created By',
    
    -- Customer Info
    KUNNR VARCHAR(10) COMMENT 'Sold-to Party',
    KUNAG VARCHAR(10) COMMENT 'Ship-to Party',
    KUNRE VARCHAR(10) COMMENT 'Bill-to Party',
    KUNWE VARCHAR(10) COMMENT 'Payer',
    
    -- Document Details
    AUART VARCHAR(4) COMMENT 'Sales Document Type',
    VKORG VARCHAR(4) COMMENT 'Sales Organization',
    VTWEG VARCHAR(2) COMMENT 'Distribution Channel',
    SPART VARCHAR(2) COMMENT 'Division',
    
    -- Dates
    AUDAT DATE COMMENT 'Document Date',
    VDATU DATE COMMENT 'Requested Delivery Date',
    WADAT DATE COMMENT 'Goods Issue Date',
    BSTDK DATE COMMENT 'Customer PO Date',
    BSTZD VARCHAR(35) COMMENT 'Customer PO Number',
    
    -- Values
    NETWR DECIMAL(15,2) COMMENT 'Net Value',
    WAERK VARCHAR(5) COMMENT 'Document Currency',
    VKBUR VARCHAR(4) COMMENT 'Sales Office',
    VKGRP VARCHAR(3) COMMENT 'Sales Group',
    
    -- Pricing
    KALSM VARCHAR(6) COMMENT 'Pricing Procedure',
    PRSDT DATE COMMENT 'Pricing Date',
    KNUMA VARCHAR(10) COMMENT 'Promotion',
    
    -- Status
    GBSTK VARCHAR(1) COMMENT 'Overall Status',
    FKSTK VARCHAR(1) COMMENT 'Billing Status',
    LIFSK VARCHAR(1) COMMENT 'Delivery Block',
    FAKSK VARCHAR(1) COMMENT 'Billing Block',
    
    -- Shipping
    VSBED VARCHAR(2) COMMENT 'Shipping Conditions',
    LPRIO VARCHAR(2) COMMENT 'Delivery Priority',
    ROUTE VARCHAR(6) COMMENT 'Route',
    
    PRIMARY KEY (VBELN)
);

-- Table: SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.VBAP
CREATE OR REPLACE TABLE SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.VBAP (
    -- Key Fields
    VBELN VARCHAR(10) COMMENT 'Sales Document',
    POSNR VARCHAR(6) COMMENT 'Sales Document Item',
    
    -- Material
    MATNR VARCHAR(18) COMMENT 'Material Number',
    ARKTX VARCHAR(40) COMMENT 'Short Text',
    WERKS VARCHAR(4) COMMENT 'Plant',
    LGORT VARCHAR(4) COMMENT 'Storage Location',
    CHARG VARCHAR(10) COMMENT 'Batch',
    
    -- Quantities
    KWMENG DECIMAL(15,3) COMMENT 'Order Quantity',
    VRKME VARCHAR(3) COMMENT 'Sales Unit',
    MEINS VARCHAR(3) COMMENT 'Base Unit',
    UMZIN DECIMAL(5) COMMENT 'Numerator',
    UMZIZ DECIMAL(5) COMMENT 'Denominator',
    
    -- Pricing
    NETWR DECIMAL(15,2) COMMENT 'Net Value',
    NETPR DECIMAL(11,2) COMMENT 'Net Price',
    PEINH DECIMAL(5) COMMENT 'Price Unit',
    KPEIN DECIMAL(5) COMMENT 'Condition Pricing Unit',
    
    -- Dates
    EDTNR VARCHAR(4) COMMENT 'Schedule Line',
    EINDT DATE COMMENT 'Delivery Date',
    ETENR VARCHAR(4) COMMENT 'Schedule Line Number',
    
    -- Status
    PSTYV VARCHAR(4) COMMENT 'Item Category',
    ABGRU VARCHAR(2) COMMENT 'Reason for Rejection',
    LFSTA VARCHAR(1) COMMENT 'Delivery Status',
    FKSTA VARCHAR(1) COMMENT 'Billing Status',
    
    -- Configuration
    CUOBJ VARCHAR(18) COMMENT 'Configuration',
    POSEX VARCHAR(6) COMMENT 'External Item Number',
    
    PRIMARY KEY (VBELN, POSNR)
);

-- Table: SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.LIKP
CREATE OR REPLACE TABLE SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.LIKP (
    -- Key Fields
    VBELN VARCHAR(10) COMMENT 'Delivery',
    ERDAT DATE COMMENT 'Created On',
    ERZET TIME COMMENT 'Time of Creation',
    ERNAM VARCHAR(12) COMMENT 'Name of Person Responsible',
    
    -- Delivery Details
    LFART VARCHAR(4) COMMENT 'Delivery Type',
    VKORG VARCHAR(4) COMMENT 'Sales Organization',
    VTWEG VARCHAR(2) COMMENT 'Distribution Channel',
    SPART VARCHAR(2) COMMENT 'Division',
    
    -- Parties
    KUNNR VARCHAR(10) COMMENT 'Ship-to Party',
    KUNAG VARCHAR(10) COMMENT 'Sold-to Party',
    LIFNR VARCHAR(10) COMMENT 'Vendor',
    ADRNR VARCHAR(10) COMMENT 'Address',
    
    -- Dates
    WADAT DATE COMMENT 'Goods Issue Date',
    LDDAT DATE COMMENT 'Loading Date',
    TDDAT DATE COMMENT 'Transportation Planning Date',
    LFDAT DATE COMMENT 'Delivery Date',
    
    -- Shipping
    ROUTE VARCHAR(6) COMMENT 'Route',
    VSBED VARCHAR(2) COMMENT 'Shipping Conditions',
    LPRIO VARCHAR(2) COMMENT 'Delivery Priority',
    TRAGR VARCHAR(4) COMMENT 'Transportation Group',
    
    -- Status
    WBSTK VARCHAR(1) COMMENT 'Goods Movement Status',
    FKSTK VARCHAR(1) COMMENT 'Billing Status',
    KODAT VARCHAR(1) COMMENT 'Picking Status',
    VKORG_DEL VARCHAR(4) COMMENT 'Delivery Sales Org',
    
    -- Weight & Volume
    BRGEW DECIMAL(15,3) COMMENT 'Gross Weight',
    NTGEW DECIMAL(15,3) COMMENT 'Net Weight',
    GEWEI VARCHAR(3) COMMENT 'Weight Unit',
    VOLUM DECIMAL(15,3) COMMENT 'Volume',
    VOLEH VARCHAR(3) COMMENT 'Volume Unit',
    
    PRIMARY KEY (VBELN)
);

-- Table: SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.LIPS
CREATE OR REPLACE TABLE SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.LIPS (
    -- Key Fields
    VBELN VARCHAR(10) COMMENT 'Delivery',
    POSNR VARCHAR(6) COMMENT 'Delivery Item',
    
    -- Material
    MATNR VARCHAR(18) COMMENT 'Material Number',
    ARKTX VARCHAR(40) COMMENT 'Short Text',
    WERKS VARCHAR(4) COMMENT 'Plant',
    LGORT VARCHAR(4) COMMENT 'Storage Location',
    CHARG VARCHAR(10) COMMENT 'Batch',
    
    -- Quantities
    LFIMG DECIMAL(13,3) COMMENT 'Actual Quantity',
    MEINS VARCHAR(3) COMMENT 'Base Unit',
    VRKME VARCHAR(3) COMMENT 'Sales Unit',
    UMZIN DECIMAL(5) COMMENT 'Numerator',
    UMZIZ DECIMAL(5) COMMENT 'Denominator',
    
    -- Reference
    VGBEL VARCHAR(10) COMMENT 'Reference Document',
    VGPOS VARCHAR(6) COMMENT 'Reference Item',
    VGTYP VARCHAR(1) COMMENT 'Document Category',
    AUBEL VARCHAR(10) COMMENT 'Sales Order',
    AUPOS VARCHAR(6) COMMENT 'Sales Order Item',
    
    -- Picking
    PKSTK VARCHAR(1) COMMENT 'Picking Status',
    PIKMG DECIMAL(13,3) COMMENT 'Picked Quantity',
    KOMKZ VARCHAR(1) COMMENT 'Picking Complete',
    GRKOR VARCHAR(3) COMMENT 'Goods Receipt Indicator',
    
    -- Status
    LFSTA VARCHAR(1) COMMENT 'Delivery Status',
    WBSTA VARCHAR(1) COMMENT 'Goods Movement Status',
    FKSTA VARCHAR(1) COMMENT 'Billing Status',
    LVSBL VARCHAR(1) COMMENT 'Deletion Flag',
    
    -- Pricing
    NETWR DECIMAL(15,2) COMMENT 'Net Value',
    NETPR DECIMAL(11,2) COMMENT 'Net Price',
    PEINH DECIMAL(5) COMMENT 'Price Unit',
    
    PRIMARY KEY (VBELN, POSNR)
);

-- Table: SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.KONV
CREATE OR REPLACE TABLE SAP_BDC_HORIZON_CATALOG.S4HANA_APAC.KONV (
    -- Key Fields
    KNUMV VARCHAR(10) COMMENT 'Number of Document Condition',
    KPOSN VARCHAR(6) COMMENT 'Condition Item Number',
    STUNR VARCHAR(3) COMMENT 'Step Number',
    ZAEHK VARCHAR(3) COMMENT 'Condition Counter',
    
    -- Condition Data
    KSCHL VARCHAR(4) COMMENT 'Condition Type',
    KAPPL VARCHAR(2) COMMENT 'Application',
    KOTABNR VARCHAR(3) COMMENT 'Condition Table',
    
    -- Values
    KBETR DECIMAL(11,2) COMMENT 'Rate (Condition Amount)',
    KOEIN VARCHAR(5) COMMENT 'Condition Unit',
    KPEIN DECIMAL(5) COMMENT 'Condition Pricing Unit',
    KUMZA DECIMAL(5) COMMENT 'Numerator',
    KUMNE DECIMAL(5) COMMENT 'Denominator',
    WAERS VARCHAR(5) COMMENT 'Currency Key',
    
    -- Scale Basis
    KNTYP VARCHAR(1) COMMENT 'Condition Category',
    KSTBS DECIMAL(15,3) COMMENT 'Scale Base Value',
    KRECH VARCHAR(1) COMMENT 'Calculation Type',
    KOUPD VARCHAR(1) COMMENT 'Condition Update',
    
    -- Validity
    DATVO DATE COMMENT 'Valid From',
    DATBI DATE COMMENT 'Valid To',
    KOBLI VARCHAR(1) COMMENT 'Condition Obligation',
    
    -- Reference
    KNUMA VARCHAR(10) COMMENT 'Promotion',
    KVEWE VARCHAR(1) COMMENT 'Usage',
    KOTEXT VARCHAR(50) COMMENT 'Condition Text',
    
    PRIMARY KEY (KNUMV, KPOSN, STUNR, ZAEHK)
);

-- Table: SAP_BDC_HORIZON_CATALOG.S4HANA_EMEA.ACDOCA
CREATE OR REPLACE TABLE SAP_BDC_HORIZON_CATALOG.S4HANA_EMEA.ACDOCA (
    -- Key Fields
    RCLNT VARCHAR(3) COMMENT 'Client',
    RBUKRS VARCHAR(4) COMMENT 'Company Code',
    GJAHR VARCHAR(4) COMMENT 'Fiscal Year',
    BELNR VARCHAR(10) COMMENT 'Accounting Document Number',
    DOCLN VARCHAR(3) COMMENT 'Ledger-Specific Line Item',
    
    -- Document Info
    BLART VARCHAR(2) COMMENT 'Document Type',
    BLDAT DATE COMMENT 'Document Date',
    BUDAT DATE COMMENT 'Posting Date',
    CPUDT DATE COMMENT 'Entry Date',
    CPUTM TIME COMMENT 'Entry Time',
    USNAM VARCHAR(12) COMMENT 'User Name',
    AWTYP VARCHAR(5) COMMENT 'Reference Transaction',
    AWKEY VARCHAR(20) COMMENT 'Reference Key',
    
    -- Accounts
    RACCT VARCHAR(10) COMMENT 'Account Number',
    RCNTR VARCHAR(10) COMMENT 'Cost Center',
    PRCTR VARCHAR(10) COMMENT 'Profit Center',
    SEGMENT VARCHAR(10) COMMENT 'Segment',
    
    -- Amounts
    HSL DECIMAL(23,2) COMMENT 'Amount in Local Currency',
    TSL DECIMAL(23,2) COMMENT 'Amount in Transaction Currency',
    MSL DECIMAL(23,2) COMMENT 'Amount in Group Currency',
    KSL DECIMAL(23,2) COMMENT 'Amount in Global Currency',
    RWCUR VARCHAR(5) COMMENT 'Currency',
    
    -- Quantities
    MENGE DECIMAL(13,3) COMMENT 'Quantity',
    MEINS VARCHAR(3) COMMENT 'Unit of Measure',
    ERNAME VARCHAR(35) COMMENT 'Created By',
    
    -- Dimensions
    KOKRS VARCHAR(4) COMMENT 'Controlling Area',
    KOSTL VARCHAR(10) COMMENT 'Cost Center',
    AUFNR VARCHAR(12) COMMENT 'Order',
    VBELN VARCHAR(10) COMMENT 'Sales Document',
    POSNR VARCHAR(6) COMMENT 'Sales Document Item',
    MATNR VARCHAR(18) COMMENT 'Material',
    WERKS VARCHAR(4) COMMENT 'Plant',
    KUNNR VARCHAR(10) COMMENT 'Customer',
    LIFNR VARCHAR(10) COMMENT 'Vendor',
    
    -- Profitability
    PAOBJNR VARCHAR(10) COMMENT 'Profitability Segment',
    PRCTR_UP VARCHAR(10) COMMENT 'Partner Profit Center',
    PPRCTR VARCHAR(10) COMMENT 'Partner Profit Center',
    
    -- Status
    XBILK VARCHAR(1) COMMENT 'Balance Sheet Account',
    XSPLITMOD VARCHAR(1) COMMENT 'Split',
    STBLG VARCHAR(10) COMMENT 'Reversal Document',
    STJAH VARCHAR(4) COMMENT 'Reversal Year',
    
    PRIMARY KEY (RCLNT, RBUKRS, GJAHR, BELNR, DOCLN)
);

-- Table: SAP_BDC_HORIZON_CATALOG.S4HANA_EMEA.FAGLFLEXA
CREATE OR REPLACE TABLE SAP_BDC_HORIZON_CATALOG.S4HANA_EMEA.FAGLFLEXA (
    -- Key Fields
    RCLNT VARCHAR(3) COMMENT 'Client',
    RBUKRS VARCHAR(4) COMMENT 'Company Code',
    RLDNR VARCHAR(2) COMMENT 'Ledger',
    GJAHR VARCHAR(4) COMMENT 'Fiscal Year',
    BELNR VARCHAR(10) COMMENT 'Document Number',
    DOCLN VARCHAR(3) COMMENT 'Line Item',
    
    -- Account Assignment
    RACCT VARCHAR(10) COMMENT 'Account',
    RCNTR VARCHAR(10) COMMENT 'Cost Center',
    PRCTR VARCHAR(10) COMMENT 'Profit Center',
    RFAREA VARCHAR(16) COMMENT 'Functional Area',
    SEGMENT VARCHAR(10) COMMENT 'Segment',
    
    -- Amounts
    HSL01 DECIMAL(23,2) COMMENT 'Amount in Currency 1',
    HSL02 DECIMAL(23,2) COMMENT 'Amount in Currency 2',
    HSL03 DECIMAL(23,2) COMMENT 'Amount in Currency 3',
    RWCUR1 VARCHAR(5) COMMENT 'Currency Key 1',
    RWCUR2 VARCHAR(5) COMMENT 'Currency Key 2',
    RWCUR3 VARCHAR(5) COMMENT 'Currency Key 3',
    
    -- Dates
    BUDAT DATE COMMENT 'Posting Date',
    BLDAT DATE COMMENT 'Document Date',
    PERID VARCHAR(3) COMMENT 'Period',
    FISCYEARPER VARCHAR(7) COMMENT 'Fiscal Year/Period',
    
    -- Dimensions
    KOKRS VARCHAR(4) COMMENT 'Controlling Area',
    KOSTL VARCHAR(10) COMMENT 'Cost Center',
    AUFNR VARCHAR(12) COMMENT 'Order',
    VBELN VARCHAR(10) COMMENT 'Sales Document',
    POSNR VARCHAR(6) COMMENT 'Sales Document Item',
    MATNR VARCHAR(18) COMMENT 'Material',
    WERKS VARCHAR(4) COMMENT 'Plant',
    KUNNR VARCHAR(10) COMMENT 'Customer',
    LIFNR VARCHAR(10) COMMENT 'Vendor',
    
    -- Additional Fields
    XBLNR VARCHAR(16) COMMENT 'Reference',
    BLART VARCHAR(2) COMMENT 'Document Type',
    BSTAT VARCHAR(1) COMMENT 'Document Status',
    XREVERSING VARCHAR(1) COMMENT 'Reversal',
    STBLG VARCHAR(10) COMMENT 'Reversal Document',
    
    PRIMARY KEY (RCLNT, RBUKRS, RLDNR, GJAHR, BELNR, DOCLN)
);

----------------------------------------------------
-- Agent 3: Strategic Capacity Planning Agent Tables
----------------------------------------------------

-- Table: SAP_BDC_HORIZON_CATALOG.ECC_AMERICAS.PA0007
CREATE OR REPLACE TABLE SAP_BDC_HORIZON_CATALOG.ECC_AMERICAS.PA0007 (
    -- Key Fields
    PERNR VARCHAR(8) COMMENT 'Personnel Number',
    SUBTY VARCHAR(4) COMMENT 'Subtype',
    OBJPS VARCHAR(2) COMMENT 'Object Identification',
    SPRPS VARCHAR(1) COMMENT 'Lock Indicator',
    ENDDA DATE COMMENT 'End Date',
    BEGDA DATE COMMENT 'Start Date',
    SEQNR VARCHAR(3) COMMENT 'Number of Infotype Record',
    
    -- Work Schedule
    SCHKZ VARCHAR(2) COMMENT 'Work Schedule Rule',
    ZTERF VARCHAR(3) COMMENT 'Employee Time Management Status',
    TPROG VARCHAR(4) COMMENT 'Weekly Work Schedule',
    TPLAN VARCHAR(4) COMMENT 'Daily Work Schedule',
    VARIA VARCHAR(6) COMMENT 'Work Schedule Variant',
    
    -- Hours
    STDVL DECIMAL(5,2) COMMENT 'Weekly Hours',
    STDVA DECIMAL(5,2) COMMENT 'Monthly Hours',
    STDVP DECIMAL(5,2) COMMENT 'Daily Hours',
    STDTA DECIMAL(5,2) COMMENT 'Daily Planned Hours',
    STDFR DECIMAL(5,2) COMMENT 'Friday Hours',
    STDSA DECIMAL(5,2) COMMENT 'Saturday Hours',
    STDSU DECIMAL(5,2) COMMENT 'Sunday Hours',
    STDMO DECIMAL(5,2) COMMENT 'Monday Hours',
    STDTU DECIMAL(5,2) COMMENT 'Tuesday Hours',
    STDWE DECIMAL(5,2) COMMENT 'Wednesday Hours',
    STDTH DECIMAL(5,2) COMMENT 'Thursday Hours',
    
    -- Shift Info
    SHKZG VARCHAR(2) COMMENT 'Shift Key',
    SPKZL VARCHAR(1) COMMENT 'Shift Code',
    SCHED_DAYS DECIMAL(3) COMMENT 'Scheduled Days',
    WORKDAYS DECIMAL(3) COMMENT 'Working Days',
    
    -- Time Management
    ZMODN VARCHAR(4) COMMENT 'Time Recording Modifier',
    ZMODE VARCHAR(4) COMMENT 'Time Recording Method',
    DYMOD VARCHAR(1) COMMENT 'Day Modifier',
    ZWEEK VARCHAR(2) COMMENT 'Week Number',
    ZMONTH VARCHAR(2) COMMENT 'Month Number',
    
    -- Capacity
    CAPACITY_HRS DECIMAL(7,2) COMMENT 'Monthly Capacity Hours',
    UTILIZATION_RATE DECIMAL(5,2) COMMENT 'Utilization Rate',
    AVAILABILITY VARCHAR(1) COMMENT 'Availability Status',
    
    PRIMARY KEY (PERNR, SUBTY, ENDDA, BEGDA)
);

-- Table: SAP_BDC_HORIZON_CATALOG.ECC_AMERICAS.PA0008
CREATE OR REPLACE TABLE SAP_BDC_HORIZON_CATALOG.ECC_AMERICAS.PA0008 (
    -- Key Fields
    PERNR VARCHAR(8) COMMENT 'Personnel Number',
    SUBTY VARCHAR(4) COMMENT 'Subtype',
    OBJPS VARCHAR(2) COMMENT 'Object Identification',
    SPRPS VARCHAR(1) COMMENT 'Lock Indicator',
    ENDDA DATE COMMENT 'End Date',
    BEGDA DATE COMMENT 'Start Date',
    SEQNR VARCHAR(3) COMMENT 'Number of Infotype Record',
    
    -- Basic Pay
    TRFAR VARCHAR(2) COMMENT 'Pay Scale Type',
    TRFGB VARCHAR(2) COMMENT 'Pay Scale Area',
    TRFGR VARCHAR(8) COMMENT 'Pay Scale Group',
    TRFST VARCHAR(2) COMMENT 'Pay Scale Level',
    TRFKZ VARCHAR(1) COMMENT 'Pay Scale Indicator',
    
    -- Salary Details
    BETRG DECIMAL(15,2) COMMENT 'Amount',
    WAERS VARCHAR(5) COMMENT 'Currency Key',
    ANZHL DECIMAL(7,2) COMMENT 'Number',
    EITXT VARCHAR(40) COMMENT 'Employee Text',
    ZEINH VARCHAR(3) COMMENT 'Time/Measurement Unit',
    PERIO VARCHAR(1) COMMENT 'Period',
    
    -- Payment
    ZFPER VARCHAR(1) COMMENT 'Payment Period',
    ZWECK VARCHAR(40) COMMENT 'Purpose',
    EMPCT DECIMAL(3) COMMENT 'Employment Percentage',
    JOBID VARCHAR(8) COMMENT 'Job Key',
    COSTCENTER VARCHAR(10) COMMENT 'Cost Center',
    
    -- Additional Pay
    BONUS_AMOUNT DECIMAL(15,2) COMMENT 'Bonus Amount',
    BONUS_PERCENT DECIMAL(5,2) COMMENT 'Bonus Percentage',
    OVERTIME_RATE DECIMAL(5,2) COMMENT 'Overtime Multiplier',
    SHIFT_DIFF DECIMAL(15,2) COMMENT 'Shift Differential',
    
    -- Capacity Cost
    HOURLY_COST DECIMAL(15,2) COMMENT 'Hourly Cost',
    MONTHLY_COST DECIMAL(15,2) COMMENT 'Monthly Cost',
    ANNUAL_COST DECIMAL(15,2) COMMENT 'Annual Cost',
    
    PRIMARY KEY (PERNR, SUBTY, ENDDA, BEGDA)
);

-- Table: SAP_BDC_HORIZON_CATALOG.ECC_AMERICAS.PP01
CREATE OR REPLACE TABLE SAP_BDC_HORIZON_CATALOG.ECC_AMERICAS.PP01 (
    -- Key Fields
    OTYPE VARCHAR(2) COMMENT 'Object Type',
    OBJID VARCHAR(8) COMMENT 'Object ID',
    PLVAR VARCHAR(2) COMMENT 'Plan Version',
    BEGDA DATE COMMENT 'Start Date',
    ENDDA DATE COMMENT 'End Date',
    ISTAT VARCHAR(1) COMMENT 'Status',
    HISTO VARCHAR(1) COMMENT 'Historical Flag',
    SHORT VARCHAR(12) COMMENT 'Object Abbreviation',
    STEXT VARCHAR(40) COMMENT 'Object Name',
    
    -- Work Center Data
    ARBPL VARCHAR(8) COMMENT 'Work Center',
    WERKS VARCHAR(4) COMMENT 'Plant',
    BUKRS VARCHAR(4) COMMENT 'Company Code',
    KOSTL VARCHAR(10) COMMENT 'Cost Center',
    VERWE VARCHAR(3) COMMENT 'Work Center Category',
    
    -- Capacity Data
    KAPID VARCHAR(4) COMMENT 'Capacity ID',
    KAPAR VARCHAR(3) COMMENT 'Capacity Category',
    KAPV1 DECIMAL(7,2) COMMENT 'Available Capacity',
    KAPE1 VARCHAR(3) COMMENT 'Capacity Unit',
    KAPV2 DECIMAL(7,2) COMMENT 'Required Capacity',
    KAPV3 DECIMAL(7,2) COMMENT 'Planned Capacity',
    AUSCH DECIMAL(7,2) COMMENT 'Utilization Rate',
    OVERL DECIMAL(7,2) COMMENT 'Overload Percentage',
    
    -- Scheduling
    SPRAS VARCHAR(1) COMMENT 'Language Key',
    SORTF VARCHAR(10) COMMENT 'Sort Field',
    SCHGR VARCHAR(4) COMMENT 'Scheduling Group',
    TSTRAT VARCHAR(2) COMMENT 'Scheduling Strategy',
    OFFSET DECIMAL(5) COMMENT 'Scheduling Offset',
    OFFSET_UNIT VARCHAR(3) COMMENT 'Offset Unit',
    
    -- Production Capacity
    PROD_CAPACITY DECIMAL(13,2) COMMENT 'Production Capacity',
    PROD_UNIT VARCHAR(3) COMMENT 'Production Unit',
    SETUP_TIME DECIMAL(7,2) COMMENT 'Setup Time',
    MACHINE_TIME DECIMAL(7,2) COMMENT 'Machine Time',
    LABOR_TIME DECIMAL(7,2) COMMENT 'Labor Time',
    QUEUE_TIME DECIMAL(7,2) COMMENT 'Queue Time',
    WAIT_TIME DECIMAL(7,2) COMMENT 'Wait Time',
    MOVE_TIME DECIMAL(7,2) COMMENT 'Move Time',
    
    -- Efficiency
    EFFICIENCY DECIMAL(5,2) COMMENT 'Efficiency Rate',
    QUALITY_RATE DECIMAL(5,2) COMMENT 'Quality Rate',
    AVAILABILITY DECIMAL(5,2) COMMENT 'Availability Rate',
    OEE DECIMAL(5,2) COMMENT 'Overall Equipment Effectiveness',
    
    PRIMARY KEY (OTYPE, OBJID, PLVAR, BEGDA, ENDDA)
);

-- Table: SAP_BDC_HORIZON_CATALOG.ENTERPRISE_PLANNING.0BWPLAN   --- change 0 to O, python as issue with atble starting numbers
CREATE OR REPLACE TABLE SAP_BDC_HORIZON_CATALOG.ENTERPRISE_PLANNING.OBWPLAN (
    -- Key Fields
    PLANNING_ID VARCHAR(20) COMMENT 'Planning ID',
    VERSION VARCHAR(3) COMMENT 'Planning Version',
    FISCYEAR VARCHAR(4) COMMENT 'Fiscal Year',
    FISCPERIOD VARCHAR(3) COMMENT 'Fiscal Period',
    
    -- Budget Data
    BUDGET_TYPE VARCHAR(2) COMMENT 'Budget Type (CapEx/OpEx)',
    BUDGET_CATEGORY VARCHAR(10) COMMENT 'Budget Category',
    BUDGET_DESC VARCHAR(60) COMMENT 'Budget Description',
    
    -- Amounts
    PLAN_AMOUNT DECIMAL(23,2) COMMENT 'Planned Amount',
    ACTUAL_AMOUNT DECIMAL(23,2) COMMENT 'Actual Amount',
    COMMITTED_AMOUNT DECIMAL(23,2) COMMENT 'Committed Amount',
    REMAINING_AMOUNT DECIMAL(23,2) COMMENT 'Remaining Amount',
    CURRENCY VARCHAR(5) COMMENT 'Currency Key',
    
    -- Capital Investment
    CAPEX_CATEGORY VARCHAR(4) COMMENT 'CapEx Category',
    PROJECT_ID VARCHAR(24) COMMENT 'Project ID',
    ASSET_CLASS VARCHAR(8) COMMENT 'Asset Class',
    INVESTMENT_TYPE VARCHAR(4) COMMENT 'Investment Type',
    
    -- Time Phasing
    REQUEST_YEAR VARCHAR(4) COMMENT 'Request Year',
    APPROVAL_YEAR VARCHAR(4) COMMENT 'Approval Year',
    START_DATE DATE COMMENT 'Planned Start Date',
    END_DATE DATE COMMENT 'Planned End Date',
    PAYMENT_DATE DATE COMMENT 'Expected Payment Date',
    
    -- ROI
    EXPECTED_ROI DECIMAL(5,2) COMMENT 'Expected ROI %',
    PAYBACK_PERIOD DECIMAL(5,2) COMMENT 'Payback Period (Years)',
    NPV DECIMAL(23,2) COMMENT 'Net Present Value',
    IRR DECIMAL(5,2) COMMENT 'Internal Rate of Return %',
    
    -- Status
    STATUS VARCHAR(1) COMMENT 'Status (P/A/R/C)',
    PRIORITY VARCHAR(1) COMMENT 'Priority (1-5)',
    APPROVAL_STATUS VARCHAR(2) COMMENT 'Approval Status',
    APPROVED_BY VARCHAR(12) COMMENT 'Approved By',
    APPROVED_DATE DATE COMMENT 'Approval Date',
    
    -- Department
    COST_CENTER VARCHAR(10) COMMENT 'Cost Center',
    PROFIT_CENTER VARCHAR(10) COMMENT 'Profit Center',
    DEPARTMENT VARCHAR(12) COMMENT 'Department',
    DIVISION VARCHAR(4) COMMENT 'Division',
    
    PRIMARY KEY (PLANNING_ID, VERSION, FISCYEAR, FISCPERIOD)
);

-- Table: SAP_BDC_HORIZON_CATALOG.ENTERPRISE_PLANNING.MSDP
CREATE OR REPLACE TABLE SAP_BDC_HORIZON_CATALOG.ENTERPRISE_PLANNING.MSDP (
    -- Key Fields
    MATNR VARCHAR(18) COMMENT 'Material Number',
    WERKS VARCHAR(4) COMMENT 'Plant',
    VERSION VARCHAR(3) COMMENT 'Planning Version',
    PERIOD_START DATE COMMENT 'Period Start Date',
    PERIOD_END DATE COMMENT 'Period End Date',
    
    -- Demand Data
    DEMAND_CATEGORY VARCHAR(2) COMMENT 'Demand Category',
    DEMAND_TYPE VARCHAR(2) COMMENT 'Demand Type',
    FORECAST_MODEL VARCHAR(10) COMMENT 'Forecast Model',
    
    -- Quantities
    FORECAST_QTY DECIMAL(15,3) COMMENT 'Forecast Quantity',
    ACTUAL_DEMAND_QTY DECIMAL(15,3) COMMENT 'Actual Demand',
    BASELINE_FORECAST DECIMAL(15,3) COMMENT 'Baseline Forecast',
    PROMOTION_FORECAST DECIMAL(15,3) COMMENT 'Promotional Impact',
    SEASONAL_FACTOR DECIMAL(5,2) COMMENT 'Seasonal Factor',
    TREND_FACTOR DECIMAL(5,2) COMMENT 'Trend Factor',
    
    -- Unit
    BASE_UOM VARCHAR(3) COMMENT 'Base Unit of Measure',
    SALES_UOM VARCHAR(3) COMMENT 'Sales Unit',
    
    -- Statistical Data
    MEAN_ABSOLUTE_ERROR DECIMAL(15,3) COMMENT 'Mean Absolute Error',
    MEAN_ABSOLUTE_PERCENT_ERROR DECIMAL(5,2) COMMENT 'MAPE %',
    BIAS DECIMAL(15,3) COMMENT 'Forecast Bias',
    STANDARD_DEVIATION DECIMAL(15,3) COMMENT 'Standard Deviation',
    CONFIDENCE_INTERVAL_LOWER DECIMAL(15,3) COMMENT '95% CI Lower',
    CONFIDENCE_INTERVAL_UPPER DECIMAL(15,3) COMMENT '95% CI Upper',
    
    -- Model Parameters
    ALPHA DECIMAL(5,3) COMMENT 'Smoothing Alpha',
    BETA DECIMAL(5,3) COMMENT 'Trend Beta',
    GAMMA DECIMAL(5,3) COMMENT 'Seasonal Gamma',
    MODEL_QUALITY VARCHAR(1) COMMENT 'Model Quality (A/B/C)',
    
    -- Constraints
    CAPACITY_CONSTRAINT DECIMAL(15,3) COMMENT 'Capacity Constraint',
    MATERIAL_CONSTRAINT VARCHAR(1) COMMENT 'Material Constraint Flag',
    SUPPLIER_CONSTRAINT VARCHAR(1) COMMENT 'Supplier Constraint Flag',
    
    -- Dates
    CREATED_DATE DATE COMMENT 'Forecast Created Date',
    LAST_UPDATED DATE COMMENT 'Last Updated',
    FORECAST_HORIZON VARCHAR(1) COMMENT 'Forecast Horizon',
    
    PRIMARY KEY (MATNR, WERKS, VERSION, PERIOD_START, DEMAND_CATEGORY)
);

-- Finance Systems Tables
-- Table: SAP_BDC_HORIZON_CATALOG.FINANCE_SYSTEMS.FBL1N

CREATE OR REPLACE TABLE SAP_BDC_HORIZON_CATALOG.FINANCE_SYSTEMS.FBL1N (
    -- Key Fields
    KUNNR VARCHAR(10) COMMENT 'Customer Number',
    BUKRS VARCHAR(4) COMMENT 'Company Code',
    BELNR VARCHAR(10) COMMENT 'Document Number',
    GJAHR VARCHAR(4) COMMENT 'Fiscal Year',
    BUZEI VARCHAR(3) COMMENT 'Line Item',
    
    -- Customer Info
    NAME1 VARCHAR(35) COMMENT 'Customer Name',
    LAND1 VARCHAR(3) COMMENT 'Country Key',
    REGIO VARCHAR(3) COMMENT 'Region',
    SORTL VARCHAR(10) COMMENT 'Sort Field',
    
    -- Document Details
    BLART VARCHAR(2) COMMENT 'Document Type',
    BLDAT DATE COMMENT 'Document Date',
    BUDAT DATE COMMENT 'Posting Date',
    ZFBDT DATE COMMENT 'Baseline Date for Due Calculation',
    ZTERM VARCHAR(4) COMMENT 'Payment Terms',
    ZLSCH VARCHAR(1) COMMENT 'Payment Method',
    
    -- Amounts
    DMBTR DECIMAL(15,2) COMMENT 'Amount in Local Currency',
    WAERS VARCHAR(5) COMMENT 'Currency Key',
    WRBTR DECIMAL(15,2) COMMENT 'Amount in Document Currency',
    SKNTO DECIMAL(13,2) COMMENT 'Cash Discount Amount',
    NETDT DATE COMMENT 'Net Due Date',
    SKFBT DECIMAL(13,2) COMMENT 'Amount Eligible for Cash Discount',
    
    -- Aging
    DAYS_OVERDUE DECIMAL(5) COMMENT 'Days Overdue',
    AGING_CATEGORY VARCHAR(2) COMMENT 'Aging Category',
    DUNN_LEVEL VARCHAR(1) COMMENT 'Dunning Level',
    MANSP VARCHAR(1) COMMENT 'Dunning Block',
    MADAT DATE COMMENT 'Last Dunning Date',
    
    -- Payment Info
    AUGDT DATE COMMENT 'Clearing Date',
    AUGBL VARCHAR(10) COMMENT 'Clearing Document',
    ZUONR VARCHAR(18) COMMENT 'Assignment Number',
    XBLNR VARCHAR(16) COMMENT 'Reference Document',
    
    -- Open Items
    SHKZG VARCHAR(1) COMMENT 'Debit/Credit Indicator',
    OPEN_ITEM VARCHAR(1) COMMENT 'Open Item Indicator',
    UMSKZ VARCHAR(1) COMMENT 'Special GL Indicator',
    
    PRIMARY KEY (KUNNR, BUKRS, BELNR, GJAHR, BUZEI)
);

-- Table: SAP_BDC_HORIZON_CATALOG.FINANCE_SYSTEMS.FDMDELTA
CREATE OR REPLACE TABLE SAP_BDC_HORIZON_CATALOG.FINANCE_SYSTEMS.FDMDELTA (
    -- Key Fields
    CASH_ID VARCHAR(20) COMMENT 'Cash Flow ID',
    COMPANY_CODE VARCHAR(4) COMMENT 'Company Code',
    FISCAL_YEAR VARCHAR(4) COMMENT 'Fiscal Year',
    PERIOD VARCHAR(3) COMMENT 'Period',
    
    -- Forecast Details
    FORECAST_TYPE VARCHAR(2) COMMENT 'Forecast Type',
    FORECAST_DATE DATE COMMENT 'Forecast Date',
    HORIZON_DAYS DECIMAL(3) COMMENT 'Forecast Horizon Days',
    
    -- Inflows
    RECEIVABLES_INFLOW DECIMAL(23,2) COMMENT 'AR Collections Forecast',
    SALES_INFLOW DECIMAL(23,2) COMMENT 'Sales Receipts',
    OTHER_INFLOW DECIMAL(23,2) COMMENT 'Other Cash Inflows',
    TOTAL_INFLOW DECIMAL(23,2) COMMENT 'Total Cash Inflows',
    
    -- Outflows
    PAYABLES_OUTFLOW DECIMAL(23,2) COMMENT 'AP Payments Forecast',
    PAYROLL_OUTFLOW DECIMAL(23,2) COMMENT 'Payroll Outflows',
    TAX_OUTFLOW DECIMAL(23,2) COMMENT 'Tax Payments',
    CAPEX_OUTFLOW DECIMAL(23,2) COMMENT 'CapEx Payments',
    OTHER_OUTFLOW DECIMAL(23,2) COMMENT 'Other Cash Outflows',
    TOTAL_OUTFLOW DECIMAL(23,2) COMMENT 'Total Cash Outflows',
    
    -- Net Cash Flow
    NET_CASH_FLOW DECIMAL(23,2) COMMENT 'Net Cash Flow',
    OPENING_BALANCE DECIMAL(23,2) COMMENT 'Opening Cash Balance',
    CLOSING_BALANCE DECIMAL(23,2) COMMENT 'Closing Cash Balance',
    MINIMUM_BALANCE DECIMAL(23,2) COMMENT 'Minimum Required Balance',
    EXCESS_DEFICIT DECIMAL(23,2) COMMENT 'Excess/Deficit',
    
    -- Currency
    CURRENCY VARCHAR(5) COMMENT 'Currency',
    
    -- Confidence
    CONFIDENCE_LEVEL DECIMAL(5,2) COMMENT 'Forecast Confidence %',
    VARIANCE_PERCENT DECIMAL(5,2) COMMENT 'Historical Variance %',
    
    -- Liquidity Ratios
    CURRENT_RATIO DECIMAL(5,2) COMMENT 'Current Ratio',
    QUICK_RATIO DECIMAL(5,2) COMMENT 'Quick Ratio',
    DAYS_SALES_OUTSTANDING DECIMAL(5,2) COMMENT 'DSO',
    DAYS_PAYABLE_OUTSTANDING DECIMAL(5,2) COMMENT 'DPO',
    
    -- Sources
    DATA_SOURCE VARCHAR(10) COMMENT 'Data Source',
    LAST_REFRESH TIMESTAMP COMMENT 'Last Refresh',
    
    PRIMARY KEY (CASH_ID, COMPANY_CODE, FISCAL_YEAR, PERIOD, FORECAST_TYPE)
);