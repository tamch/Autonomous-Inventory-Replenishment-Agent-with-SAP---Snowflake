-- Agent 1: Autonomous Inventory Replenishment Agent 

-- 1. Semantic Views
-- 1.1 Inventory Core Semantic View
USE WAREHOUSE SAP_COMPUTE;
USE DATABASE SAP_BDC_HORIZON_CATALOG;
CREATE OR REPLACE SCHEMA SAP_BDC_HORIZON_CATALOG.AGENTS;
USE SCHEMA AGENTS;

-- Create semantic view for inventory analysis
CREATE OR REPLACE VIEW INVENTORY_SEMANTIC_VIEW AS
WITH inventory_current AS (
    SELECT 
        m.MATNR as material_id,
        m.WERKS as plant,
        m.LGORT as storage_location,
        MAX(m.BUDAT) as last_movement_date,
        SUM(CASE WHEN m.SHKZG = 'S' THEN m.MENGE ELSE -m.MENGE END) as current_stock,
        m.MEINS as uom
    FROM S4HANA_ALL_REGIONS.MATDOC m
    WHERE m.BUDAT >= DATEADD(month, -12, CURRENT_DATE)
    GROUP BY m.MATNR, m.WERKS, m.LGORT, m.MEINS
),
material_params AS (
    SELECT 
        MATNR,
        WERKS,
        DISPO as mrp_controller,
        DISMM as mrp_type,
        MINBE as reorder_point,
        EISBE as safety_stock,
        BSTMI as min_lot_size,
        BSTMA as max_lot_size,
        PLIFZ as planned_delivery_time,
        WEBRE as goods_receipt_ind
    FROM S4HANA_ALL_REGIONS.MARC
),
open_requirements AS (
    SELECT 
        MATNR,
        WERKS,
        SUM(CASE WHEN DTERQ <= CURRENT_DATE THEN OPNG ELSE 0 END) as past_due_qty,
        SUM(CASE WHEN DTERQ > CURRENT_DATE AND DTERQ <= DATEADD(day, 7, CURRENT_DATE) THEN OPNG ELSE 0 END) as next_7_days_qty,
        SUM(CASE WHEN DTERQ > DATEADD(day, 7, CURRENT_DATE) THEN OPNG ELSE 0 END) as future_qty,
        MIN(CASE WHEN DTERQ > CURRENT_DATE THEN DTERQ ELSE NULL END) as next_requirement_date
    FROM S4HANA_ALL_REGIONS.MD04
    GROUP BY MATNR, WERKS
),
open_pos AS (
    SELECT 
        MATNR,
        WERKS,
        SUM(CASE WHEN EINDT <= CURRENT_DATE THEN REMNG ELSE 0 END) as overdue_po_qty,
        SUM(CASE WHEN EINDT > CURRENT_DATE AND EINDT <= DATEADD(day, 7, CURRENT_DATE) THEN REMNG ELSE 0 END) as arriving_7_days_qty,
        SUM(CASE WHEN EINDT > DATEADD(day, 7, CURRENT_DATE) THEN REMNG ELSE 0 END) as future_po_qty,
        MIN(CASE WHEN EINDT > CURRENT_DATE THEN EINDT ELSE NULL END) as next_receipt_date,
        LISTAGG(DISTINCT LIFNR, ',') as active_suppliers
    FROM S4HANA_ALL_REGIONS.ME2N
    WHERE REMNG > 0
    GROUP BY MATNR, WERKS
),
supplier_performance AS (
    SELECT 
        LIFNR as supplier_id,
        AVG(DATEDIFF(day, BEDAT, EINDT)) as avg_lead_time,
        COUNT(*) as total_pos,
        SUM(CASE WHEN EINDT < CURRENT_DATE AND REMNG > 0 THEN 1 ELSE 0 END) as late_deliveries,
        AVG(CASE WHEN EINDT >= BEDAT THEN 1.0 ELSE 0.5 END) as reliability_score
    FROM S4HANA_ALL_REGIONS.ME2N
    WHERE BEDAT >= DATEADD(year, -1, CURRENT_DATE)
    GROUP BY LIFNR
)
SELECT 
    -- Material identifiers
    ic.material_id,
    ic.plant,
    ic.storage_location,
    
    -- Current stock position
    ic.current_stock,
    ic.uom,
    ic.last_movement_date,
    
    -- MRP parameters
    mp.reorder_point,
    mp.safety_stock,
    mp.min_lot_size,
    mp.max_lot_size,
    mp.planned_delivery_time,
    mp.mrp_controller,
    
    -- Requirements
    COALESCE(orq.past_due_qty, 0) as past_due_requirements,
    COALESCE(orq.next_7_days_qty, 0) as next_7_days_requirements,
    COALESCE(orq.future_qty, 0) as future_requirements,
    orq.next_requirement_date,
    
    -- Open POs
    COALESCE(op.overdue_po_qty, 0) as overdue_po_qty,
    COALESCE(op.arriving_7_days_qty, 0) as arriving_7_days_qty,
    COALESCE(op.future_po_qty, 0) as future_po_qty,
    op.next_receipt_date,
    op.active_suppliers,
    
    -- Calculated metrics
    ic.current_stock - COALESCE(orq.past_due_qty, 0) as available_stock,
    (ic.current_stock - COALESCE(orq.past_due_qty, 0)) - mp.safety_stock as excess_over_safety,
    mp.reorder_point - (ic.current_stock - COALESCE(orq.past_due_qty, 0)) as reorder_trigger_amount,
    
    -- Status flags
    CASE 
        WHEN (ic.current_stock - COALESCE(orq.past_due_qty, 0)) < mp.safety_stock THEN 'CRITICAL'
        WHEN (ic.current_stock - COALESCE(orq.past_due_qty, 0)) < mp.reorder_point THEN 'REORDER'
        WHEN (ic.current_stock - COALESCE(orq.past_due_qty, 0)) < mp.reorder_point * 1.5 THEN 'WATCH'
        ELSE 'HEALTHY'
    END as stock_status,
    
    CASE 
        WHEN COALESCE(orq.past_due_qty, 0) > 0 THEN 'PAST_DUE'
        WHEN COALESCE(op.overdue_po_qty, 0) > 0 THEN 'OVERDUE_PO'
        WHEN COALESCE(orq.next_7_days_qty, 0) > COALESCE(op.arriving_7_days_qty, 0) THEN 'COVERAGE_GAP'
        ELSE 'OK'
    END as supply_status,
    
    -- Supplier performance (use first supplier if multiple)
    sp.avg_lead_time,
    sp.reliability_score,
    sp.late_deliveries,
    
    -- Recommended order quantity
    GREATEST(
        mp.min_lot_size,
        CEIL(
            (COALESCE(orq.past_due_qty, 0) + COALESCE(orq.next_7_days_qty, 0)) 
            - COALESCE(op.overdue_po_qty, 0) 
            - COALESCE(op.arriving_7_days_qty, 0)
            + mp.safety_stock 
            - (ic.current_stock - COALESCE(orq.past_due_qty, 0))
        )
    ) as recommended_order_qty,
    
    -- Confidence score for autonomous ordering
    CASE
        WHEN sp.reliability_score >= 0.9 AND sp.avg_lead_time <= mp.planned_delivery_time THEN 0.95
        WHEN sp.reliability_score >= 0.8 THEN 0.85
        WHEN sp.reliability_score >= 0.7 THEN 0.70
        ELSE 0.50
    END as supplier_confidence_score

FROM inventory_current ic
LEFT JOIN material_params mp 
    ON ic.material_id = mp.MATNR AND ic.plant = mp.WERKS
LEFT JOIN open_requirements orq 
    ON ic.material_id = orq.MATNR AND ic.plant = orq.WERKS
LEFT JOIN open_pos op 
    ON ic.material_id = op.MATNR AND ic.plant = op.WERKS
LEFT JOIN supplier_performance sp 
    ON op.active_suppliers LIKE '%' || sp.supplier_id || '%';


-- 1.2 Inventory Movement Analytics View
-- Create view for inventory movement patterns
CREATE OR REPLACE VIEW INVENTORY_MOVEMENT_ANALYTICS AS
SELECT 
    MATNR as material_id,
    WERKS as plant,
    DATE_TRUNC('month', BUDAT) as movement_month,
    COUNT(*) as transaction_count,
    SUM(CASE WHEN BWART LIKE '1%' THEN 1 ELSE 0 END) as goods_receipt_count,
    SUM(CASE WHEN BWART LIKE '2%' THEN 1 ELSE 0 END) as goods_issue_count,
    SUM(CASE WHEN BWART LIKE '3%' THEN 1 ELSE 0 END) as transfer_count,
    SUM(CASE WHEN SHKZG = 'S' THEN MENGE ELSE 0 END) as total_receipt_qty,
    SUM(CASE WHEN SHKZG = 'H' THEN MENGE ELSE 0 END) as total_issue_qty,
    AVG(CASE WHEN SHKZG = 'S' THEN DMBTR/MENGE ELSE NULL END) as avg_receipt_price,
    COUNT(DISTINCT LIFNR) as distinct_suppliers,
    COUNT(DISTINCT KUNNR) as distinct_customers,
    MODE(BWART) as most_common_movement_type
FROM S4HANA_ALL_REGIONS.MATDOC
WHERE BUDAT >= DATEADD(year, -2, CURRENT_DATE)
GROUP BY MATNR, WERKS, DATE_TRUNC('month', BUDAT);




-- 1.3 Demand Pattern Detection View (for Cortex Search)
-- Create view for demand pattern analysis with text for Cortex Search

-- cause an error Query contains the function 'CURRENT_DATE', but change tracking is not supported on queries with non-deterministic functions.
-- Change tracking is not supported on queries with 'VALUES'.
CREATE OR REPLACE VIEW INVENTORY_DEMAND_PATTERNS AS
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
    -- Create searchable text field for Cortex Search
    CONCAT(
        'Material ', m.ARKTX, ' (', md.MATNR, ') at plant ', md.WERKS,
        ' has a requirement of ', md.MENGE, ' ', md.MEINS,
        ' on ', md.DTERQ, ' of type ', 
        CASE WHEN md.DTART = 'CU' THEN 'customer order' 
             WHEN md.DTART = 'DL' THEN 'delivery schedule'
             ELSE 'planning requirement' END,
        CASE WHEN md.OPNG > 0 THEN '. Open quantity: ' || md.OPNG ELSE '' END
    ) as search_text,
    -- Add metadata for filtering
    OBJECT_CONSTRUCT(
        'priority', CASE WHEN md.DTERQ <= CURRENT_DATE THEN 'HIGH' ELSE 'NORMAL' END,
        'open_qty', md.OPNG,
        'supplier', COALESCE(md.LIFNR, 'Not assigned'),
        'season', CASE 
            WHEN MONTH(md.DTERQ) IN (12,1,2) THEN 'Winter'
            WHEN MONTH(md.DTERQ) IN (3,4,5) THEN 'Spring'
            WHEN MONTH(md.DTERQ) IN (6,7,8) THEN 'Summer'
            ELSE 'Fall'
        END
    ) as metadata
FROM S4HANA_ALL_REGIONS.MD04 md
LEFT JOIN S4HANA_ALL_REGIONS.MARC mc ON md.MATNR = mc.MATNR AND md.WERKS = mc.WERKS
LEFT JOIN S4HANA_APAC.VBAP m ON md.MATNR = m.MATNR
WHERE md.DTERQ BETWEEN CURRENT_DATE AND DATEADD(month, 3, CURRENT_DATE);

-- replace with following
-- Step 3.1.1: Create a table to hold the materialized data
CREATE OR REPLACE TABLE INVENTORY_DEMAND_PATTERNS_STAGING (
    pattern_id STRING,
    material_id STRING,
    plant STRING,
    material_description STRING,
    requirement_date DATE,
    requirement_qty NUMBER,
    requirement_type STRING,
    requirement_type_desc STRING,
    mrp_controller STRING,
    search_text STRING,
    metadata VARIANT
);

-- Step 3.1.2: Create a task to refresh the data periodically
CREATE OR REPLACE TASK REFRESH_INVENTORY_DEMAND_PATTERNS
    WAREHOUSE = SAP_COMPUTE
    SCHEDULE = '5 MINUTE'
AS
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
            'Material ', m.ARKTX, ' (', md.MATNR, ') at plant ', md.WERKS,
            ' has a requirement of ', md.MENGE, ' ', md.MEINS,
            ' on ', md.DTERQ, ' of type ', 
            CASE WHEN md.DTART = 'CU' THEN 'customer order' 
                 WHEN md.DTART = 'DL' THEN 'delivery schedule'
                 ELSE 'planning requirement' END,
            CASE WHEN md.OPNG > 0 THEN '. Open quantity: ' || md.OPNG ELSE '' END
        ) as search_text,
        OBJECT_CONSTRUCT(
            'priority', CASE WHEN md.DTERQ <= date_ref.ref_date THEN 'HIGH' ELSE 'NORMAL' END,
            'open_qty', md.OPNG,
            'supplier', COALESCE(md.LIFNR, 'Not assigned'),
            'season', CASE 
                WHEN MONTH(md.DTERQ) IN (12,1,2) THEN 'Winter'
                WHEN MONTH(md.DTERQ) IN (3,4,5) THEN 'Spring'
                WHEN MONTH(md.DTERQ) IN (6,7,8) THEN 'Summer'
                ELSE 'Fall'
            END
        ) as metadata
    FROM S4HANA_ALL_REGIONS.MD04 md
    LEFT JOIN S4HANA_ALL_REGIONS.MARC mc ON md.MATNR = mc.MATNR AND md.WERKS = mc.WERKS
    LEFT JOIN S4HANA_APAC.VBAP m ON md.MATNR = m.MATNR
    CROSS JOIN date_ref
    WHERE md.DTERQ BETWEEN date_ref.ref_date AND DATEADD(month, 3, date_ref.ref_date);

-- Step 3.1.3: Start the task
ALTER TASK REFRESH_INVENTORY_DEMAND_PATTERNS RESUME;
ALTER TASK REFRESH_INVENTORY_DEMAND_PATTERNS SUSPEND; -- suspend

-- 2. Set Up Cortex Search Service
CREATE OR REPLACE CORTEX SEARCH SERVICE INVENTORY_DEMAND_SEARCH
ON search_text
ATTRIBUTES requirement_type, mrp_controller
WAREHOUSE = SAP_COMPUTE
TARGET_LAG = '1 hour'
AS
    SELECT * FROM INVENTORY_DEMAND_PATTERNS_STAGING;

ALTER CORTEX SEARCH SERVICE INVENTORY_DEMAND_SEARCH RESUME;
ALTER CORTEX SEARCH SERVICE INVENTORY_DEMAND_SEARCH SUSPEND;

ALTER CORTEX SEARCH SERVICE INVENTORY_DEMAND_SEARCH SUSPEND INDEXING;
-- or
ALTER CORTEX SEARCH SERVICE INVENTORY_DEMAND_SEARCH SUSPEND SERVING;



-- 3. Create ML Model for Demand Prediction
-- Create Snowpark Python function for demand prediction
CREATE OR REPLACE PROCEDURE predict_demand(
    material_id VARCHAR,
    plant VARCHAR,
    forecast_days INT
)
RETURNS TABLE (forecast_date DATE, predicted_demand FLOAT, lower_bound FLOAT, upper_bound FLOAT, confidence FLOAT)
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('snowflake-snowpark-python', 'pandas', 'numpy', 'scikit-learn')
HANDLER = 'predict_demand'
AS
$$
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from datetime import timedelta, date
from snowflake.snowpark import DataFrame as SnowparkDataFrame
from snowflake.snowpark.types import StructType, StructField, DateType, FloatType
import logging

def predict_demand(snowpark_session, material_id, plant, forecast_days):
    # Set up logging
    logger = logging.getLogger('predict_demand')
    logger.info(f"Starting prediction for material {material_id}, plant {plant}, days {forecast_days}")
    
    # Get historical demand data
    query = f"""
    SELECT 
        DTERQ,
        MENGE as demand
    FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.MD04
    WHERE MATNR = '{material_id}' 
        AND WERKS = '{plant}'
        AND DTERQ >= DATEADD(year, -2, CURRENT_DATE)
    ORDER BY DTERQ
    """
    
    logger.info(f"Executing query: {query}")
    
    # Execute query and convert to pandas
    snowpark_df = snowpark_session.sql(query)
    df = snowpark_df.to_pandas()
    
    logger.info(f"Retrieved {len(df)} rows from database")
    
    # Check if DataFrame is empty
    if df.empty:
        logger.info("No data found, returning empty forecast with zeros")
        results = []
        for i in range(forecast_days):
            forecast_date = date.today() + timedelta(days=i+1)
            results.append([forecast_date, 0.0, 0.0, 0.0, 0.0])
        
        # Define schema for the output
        schema = StructType([
            StructField("forecast_date", DateType()),
            StructField("predicted_demand", FloatType()),
            StructField("lower_bound", FloatType()),
            StructField("upper_bound", FloatType()),
            StructField("confidence", FloatType())
        ])
        
        return snowpark_session.create_dataframe(results, schema)
    
    # Rename columns to work with pandas
    df.columns = ['dterq', 'demand']  # Explicitly rename columns
    
    # Create results list
    results = []
    
    if len(df) < 30:
        logger.info(f"Only {len(df)} rows, using moving average fallback")
        # Not enough data for ML, use simple moving average
        last_30_days = df['demand'].tail(min(30, len(df))).mean() if len(df) > 0 else 0
        for i in range(forecast_days):
            forecast_date = date.today() + timedelta(days=i+1)
            results.append([forecast_date, float(last_30_days), float(last_30_days * 0.7), float(last_30_days * 1.3), 0.6])
    else:
        # Feature engineering
        df['dterq'] = pd.to_datetime(df['dterq'])
        df['dayofweek'] = df['dterq'].dt.dayofweek
        df['month'] = df['dterq'].dt.month
        df['quarter'] = df['dterq'].dt.quarter
        df['dayofyear'] = df['dterq'].dt.dayofyear
        
        # Create lag features
        for lag in [1, 7, 30]:
            df[f'lag_{lag}'] = df['demand'].shift(lag)
        
        # Rolling statistics
        df['rolling_mean_7'] = df['demand'].rolling(window=7, min_periods=1).mean()
        df['rolling_std_7'] = df['demand'].rolling(window=7, min_periods=1).std()
        
        # Drop NaN values
        original_len = len(df)
        df = df.dropna()
        logger.info(f"After feature engineering and dropping NaN: {len(df)} rows remaining (from {original_len})")
        
        if len(df) < 10:
            logger.info(f"Only {len(df)} rows after feature engineering, using last value fallback")
            last_demand = df['demand'].iloc[-1] if len(df) > 0 else 0
            for i in range(forecast_days):
                forecast_date = date.today() + timedelta(days=i+1)
                results.append([forecast_date, float(last_demand), float(max(0, last_demand * 0.8)), float(last_demand * 1.2), 0.5])
        else:
            # Prepare features
            feature_cols = ['dayofweek', 'month', 'quarter', 'dayofyear', 
                            'lag_1', 'lag_7', 'lag_30', 'rolling_mean_7', 'rolling_std_7']
            X = df[feature_cols]
            y = df['demand']
            
            # Train model
            logger.info("Training RandomForest model...")
            model = RandomForestRegressor(n_estimators=100, max_depth=10, random_state=42)
            model.fit(X, y)
            logger.info("Model training complete")
            
            # Get the last date for forecasting
            last_date = df['dterq'].max()
            
            # Generate future dates
            future_dates = [last_date + timedelta(days=i+1) for i in range(forecast_days)]
            
            # Prepare future features
            future_df = pd.DataFrame({'date': future_dates})
            future_df['dayofweek'] = future_df['date'].dt.dayofweek
            future_df['month'] = future_df['date'].dt.month
            future_df['quarter'] = future_df['date'].dt.quarter
            future_df['dayofyear'] = future_df['date'].dt.dayofyear
            
            # Use last known values for lags
            last_row = df.iloc[-1]
            future_df['lag_1'] = last_row['demand']
            future_df['lag_7'] = df['demand'].tail(7).mean() if len(df) >= 7 else last_row['demand']
            future_df['lag_30'] = df['demand'].tail(30).mean() if len(df) >= 30 else last_row['demand']
            future_df['rolling_mean_7'] = df['demand'].tail(7).mean()
            future_df['rolling_std_7'] = df['demand'].tail(7).std() if len(df) >= 7 else 0
            
            # Predict
            predictions = model.predict(future_df[feature_cols])
            
            # Calculate prediction intervals
            errors = np.abs(y - model.predict(X))
            mae = np.mean(errors)
            r2_score = max(0, model.score(X, y))

            logger.info(f"MAE: {mae:.2f}, R2: {r2_score:.3f}")
            
            # Build results
            for i, pred in enumerate(predictions):
                results.append([
                    future_dates[i].date() if hasattr(future_dates[i], 'date') else future_dates[i],
                    float(max(0, pred)),
                    float(max(0, pred - 2*mae)),
                    float(pred + 2*mae),
                    float(r2_score)
                ])
    
    # Convert to Snowpark DataFrame
    if results:
        logger.info(f"Creating Snowpark DataFrame with {len(results)} rows")
        
        # Define schema for the output
        schema = StructType([
            StructField("forecast_date", DateType()),
            StructField("predicted_demand", FloatType()),
            StructField("lower_bound", FloatType()),
            StructField("upper_bound", FloatType()),
            StructField("confidence", FloatType())
        ])
        
        # Create Snowpark DataFrame from results
        return snowpark_session.create_dataframe(results, schema)
    else:
        logger.info("No results generated, returning empty DataFrame")
        # Return empty DataFrame with correct schema
        schema = StructType([
            StructField("forecast_date", DateType()),
            StructField("predicted_demand", FloatType()),
            StructField("lower_bound", FloatType()),
            StructField("upper_bound", FloatType()),
            StructField("confidence", FloatType())
        ])
        return snowpark_session.create_dataframe([], schema)
$$;



-------------------------------------------------------
-- 4. Create Cortex Agent Functions
--------------------------------------------------------
-- 4.1 Inventory Analysis Function

-- Create function for inventory analysis using Cortex
CREATE OR REPLACE FUNCTION analyze_inventory_status(
    i_material_id VARCHAR DEFAULT NULL,
    i_plant_id VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    material_id VARCHAR,
    plant VARCHAR,
    current_stock NUMBER,
    safety_stock NUMBER,
    reorder_point NUMBER,
    stock_status VARCHAR,
    supply_status VARCHAR,
    recommended_order_qty NUMBER,
    supplier_confidence_score NUMBER,
    past_due_requirements NUMBER,
    overdue_po_qty NUMBER,
    next_7_days_requirements NUMBER,
    arriving_7_days_qty NUMBER,
    avg_lead_time NUMBER,
    reliability_score NUMBER,
    recommended_action VARCHAR,
    active_suppliers VARCHAR,
    confidence_score NUMBER,
    analysis_details VARIANT
)
LANGUAGE SQL
AS
$$
WITH analysis_base AS (
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
        reliability_score,
        -- Generate active_suppliers based on material_id or use default
        CASE 
            WHEN material_id LIKE 'MAT%' THEN 'SUPPLIER_A,SUPPLIER_B,SUPPLIER_C'
            WHEN material_id LIKE 'RM%' THEN 'RAW_MAT_SUPPLIER1,RAW_MAT_SUPPLIER2'
            ELSE 'DEFAULT_SUPPLIER'
        END as active_suppliers,
        OBJECT_CONSTRUCT(
            'past_due_requirements', past_due_requirements,
            'overdue_po_qty', overdue_po_qty,
            'next_7_days_demand', next_7_days_requirements,
            'next_7_days_supply', arriving_7_days_qty,
            'avg_lead_time_days', avg_lead_time,
            'supplier_reliability', reliability_score,
            'coverage_days', CASE 
                WHEN next_7_days_requirements > 0 
                THEN (current_stock + arriving_7_days_qty) / (next_7_days_requirements / 7)
                ELSE 999 END
        ) as details
    FROM INVENTORY_SEMANTIC_VIEW
    WHERE (i_material_id IS NULL OR material_id = i_material_id)
       AND (i_plant_id IS NULL OR plant = i_plant_id)
)
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
    reliability_score,
    CASE
        WHEN stock_status = 'CRITICAL' AND recommended_order_qty > 0 
            THEN 'ORDER_IMMEDIATELY: ' || recommended_order_qty || ' units'
        WHEN stock_status = 'REORDER' AND recommended_order_qty > 0
            THEN 'PLACE_ORDER: ' || recommended_order_qty || ' units'
        WHEN supply_status = 'COVERAGE_GAP' 
            THEN 'EXPEDITE_SUPPLY: Gap of ' || (next_7_days_requirements - arriving_7_days_qty) || ' units'
        WHEN stock_status = 'WATCH' 
            THEN 'MONITOR_ONLY: Stock above reorder point'
        ELSE 'NO_ACTION: Stock levels adequate'
    END as recommended_action,
    active_suppliers,
    supplier_confidence_score as confidence_score,
    TRY_CAST(details AS VARIANT) as analysis_details
FROM analysis_base
WHERE stock_status IN ('CRITICAL', 'REORDER') OR supply_status != 'OK'
$$;



-- 4.2 Autonomous Order Creation Function
-- Create stored procedure for autonomous PO creation
CREATE OR REPLACE PROCEDURE create_autonomous_purchase_order(
    material_id VARCHAR,
    plant_id VARCHAR,
    quantity NUMBER,
    supplier_id VARCHAR,
    confidence_score FLOAT,
    agent_notes VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    po_number VARCHAR;
    order_date DATE;
    delivery_date DATE;
    audit_id VARCHAR;
BEGIN
    -- Generate PO number
    po_number := 'AUTO-' || TO_CHAR(CURRENT_TIMESTAMP(), 'YYYYMMDDHH24MISS') || '-' || material_id;
    order_date := CURRENT_DATE();
    
    -- Calculate expected delivery date based on supplier performance
    delivery_date := DATEADD(
        day, 
        (SELECT COALESCE(avg_lead_time, 14) 
         FROM INVENTORY_SEMANTIC_VIEW 
         WHERE material_id = :material_id AND plant = :plant_id 
         LIMIT 1),
        :order_date
    );
    
    -- Generate audit_id
    audit_id := UUID_STRING();
    
    -- Log the autonomous decision (without RETURNING clause)
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
        created_at
    ) VALUES (
        :audit_id,
        'Inventory Replenishment Agent',
        'AUTONOMOUS_PO_CREATION',
        :material_id,
        :plant_id,
        :supplier_id,
        :quantity,
        :confidence_score,
        :order_date,
        :delivery_date,
        :agent_notes,
        'EXECUTED',
        CURRENT_TIMESTAMP()
    );
    
    -- In production, this would call SAP OData API
    -- For demo, we'll insert into a staging table
    INSERT INTO sap_po_staging (
        po_number,
        material_id,
        plant,
        supplier_id,
        quantity,
        order_date,
        delivery_date,
        confidence_score,
        audit_id,
        status
    ) VALUES (
        :po_number,
        :material_id,
        :plant_id,
        :supplier_id,
        :quantity,
        :order_date,
        :delivery_date,
        :confidence_score,
        :audit_id,
        'PENDING_SYNC'
    );
    
    RETURN 'PO_CREATED: ' || po_number || ' with confidence ' || confidence_score;
END;
$$;

-- 4.3 Agent Decision Logic with Cortex
-- Create the main agent function using Cortex AI

DROP PROCEDURE IF EXISTS inventory_replenishment_agent(VARCHAR); 


CREATE OR REPLACE PROCEDURE inventory_replenishment_agent(
    run_mode VARCHAR DEFAULT 'AUTOMATIC' -- 'AUTOMATIC' or 'SIMULATION'
)
RETURNS TABLE (
    execution_id VARCHAR,
    material_id VARCHAR,
    plant VARCHAR,
    decision VARCHAR,
    order_quantity FLOAT,
    confidence FLOAT,
    reasoning VARCHAR
)
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('snowflake-snowpark-python', 'pandas')
HANDLER = 'process'  
AS
$$
import pandas as pd
import json
from datetime import datetime
from snowflake.snowpark.types import StructType, StructField, StringType, FloatType, IntegerType

def process(session, run_mode='AUTOMATIC'):
    execution_id = datetime.now().strftime('%Y%m%d_%H%M%S')
    agent = InventoryReplenishmentAgentLogic(session, run_mode, execution_id)
    results = agent.run()
    
    # Define the schema
    schema = StructType([
        StructField("execution_id", StringType()),
        StructField("material_id", StringType()),
        StructField("plant", StringType()),
        StructField("decision", StringType()),
        StructField("order_quantity", FloatType()),
        StructField("confidence", FloatType()),
        StructField("reasoning", StringType())
    ])
    
    # Create Snowpark DataFrame from results
    return session.create_dataframe(results, schema)

class InventoryReplenishmentAgentLogic:
    def __init__(self, session, run_mode, execution_id):
        self.session = session
        self.run_mode = run_mode
        self.execution_id = execution_id
        
    def analyze_inventory_items(self):
        """Get all items needing attention"""
        query = """
        SELECT 
            MATERIAL_ID,  -- Changed from material_id to MATERIAL_ID (uppercase)
            PLANT,        -- Changed from plant to PLANT
            CURRENT_STOCK,
            SAFETY_STOCK,
            REORDER_POINT,
            STOCK_STATUS,
            SUPPLY_STATUS,
            RECOMMENDED_ORDER_QTY,
            SUPPLIER_CONFIDENCE_SCORE,
            PAST_DUE_REQUIREMENTS,
            NEXT_7_DAYS_REQUIREMENTS,
            ARRIVING_7_DAYS_QTY,
            AVG_LEAD_TIME,
            RELIABILITY_SCORE,
            RECOMMENDED_ACTION,
            CONFIDENCE_SCORE, 
            ACTIVE_SUPPLIERS,
            ANALYSIS_DETAILS
        FROM TABLE(analyze_inventory_status())
        WHERE stock_status IN ('CRITICAL', 'REORDER')
            OR supply_status != 'OK'
        """
        return self.session.sql(query).to_pandas()
    
    def get_demand_forecast(self, material_id, plant):
        """Get demand forecast for material"""
        query = f"""
        SELECT 
            forecast_date,
            predicted_demand,
            confidence as forecast_confidence
        FROM TABLE(predict_demand('{material_id}', '{plant}', 30))
        ORDER BY forecast_date
        """
        return self.session.sql(query).to_pandas()
    
    def search_demand_patterns(self, material_id, plant):
        """Use Cortex Search to find similar demand patterns"""
        try:
            from snowflake.core import Root
            
            # Create root from session
            root = Root(self.session)
            
            # Get the search service
            search_service = (root
                .databases["SAP_BDC_HORIZON_CATALOG"]
                .schemas["AGENTS"]
                .cortex_search_services["INVENTORY_DEMAND_SEARCH"]
            )
            
            # Build search query
            search_query = f"material {material_id} demand requirements"
            
            # Build filter
            filter_obj = {
                "@and": [
                    {"@eq": {"material_id": material_id}},
                    {"@eq": {"plant": plant}}
                ]
            }
            
            # Execute search
            response = search_service.search(
                query=search_query,
                columns=[
                    "pattern_id",
                    "material_description", 
                    "requirement_date",
                    "requirement_qty",
                    "search_text",
                    "metadata"
                ],
                filter=filter_obj,
                limit=10
            )
            
            # Parse response
            response_json = json.loads(response.to_json())
            results = response_json.get('results', [])
            
            if results:
                df = pd.DataFrame(results)
                # Extract nested metadata fields
                if 'metadata' in df.columns and not df.empty:
                    df['priority'] = df['metadata'].apply(
                        lambda x: x.get('priority') if isinstance(x, dict) else None
                    )
                    df['season'] = df['metadata'].apply(
                        lambda x: x.get('season') if isinstance(x, dict) else None
                    )
                return df
            return pd.DataFrame()
            
        except Exception as e:
            print(f"Cortex Search error: {str(e)}")
            # Fallback to direct table query
            return self.fallback_search(material_id, plant)
    
    def fallback_search(self, material_id, plant):
        """Fallback method if Cortex Search fails"""
        try:
            query = f"""
            SELECT 
                pattern_id,
                material_description,
                requirement_date,
                requirement_qty,
                search_text,
                metadata:priority as priority,
                metadata:season as season
            FROM INVENTORY_DEMAND_PATTERNS_STAGING
            WHERE material_id = '{material_id}'
                AND plant = '{plant}'
                AND requirement_date >= CURRENT_DATE
            ORDER BY requirement_date
            LIMIT 10
            """
            return self.session.sql(query).to_pandas()
        except Exception as e:
            print(f"Fallback search error: {str(e)}")
            return pd.DataFrame()
    
    def calculate_risk_score(self, row, forecast_df, patterns_df):
        """Calculate risk score using multiple factors"""
        risk = 0.0
        factors = []
        
        # Stock level risk
        if row['CURRENT_STOCK'] < row['SAFETY_STOCK']:
            risk += 0.4
            factors.append("Below safety stock")
        elif row['CURRENT_STOCK'] < row['reorder_point']:
            risk += 0.2
            factors.append("Below reorder point")
        
        # Supply chain risk
        if row['SUPPLIER_CONFIDENCE_SCORE'] < 0.7:
            risk += 0.2
            factors.append("Low supplier reliability")
        if row['AVG_LEAD_TIME'] > 14:
            risk += 0.1
            factors.append("Long lead time")
        
        # Demand risk
        if not forecast_df.empty and 'PREDICTED_DEMAND' in forecast_df.columns:
            next_7_days_demand = forecast_df.head(7)['PREDICTED_DEMAND'].sum()
            if next_7_days_demand > row['CURRENT_STOCK']:
                risk += 0.2
                factors.append("Forecasted demand exceeds stock")
        
        # Pattern risk
        if not patterns_df.empty:
            urgent_patterns = 0
            if 'PRIORITY' in patterns_df.columns:
                for _, p_row in patterns_df.iterrows():
                    priority = p_row.get('PRIORITY', '')
                    if priority and ('HIGH' in str(priority) or '"HIGH"' in str(priority)):
                        urgent_patterns += 1
            if urgent_patterns > 0:
                risk += 0.1
                factors.append("Urgent demand patterns detected")
        
        return min(risk, 1.0), factors
    
    def generate_reasoning(self, row, risk_score, factors, forecast_df):
        """Generate natural language reasoning for the decision"""
        reasoning = f"Material {row['MATERIAL_ID']} at plant {row['PLANT']}: "
        
        if risk_score > 0.7:
            reasoning += "CRITICAL - "
        elif risk_score > 0.4:
            reasoning += "WARNING - "
        else:
            reasoning += "MONITOR - "
        
        reasoning += f"Current stock: {row['CURRENT_STOCK']:.0f}, "
        reasoning += f"Safety stock: {row['SAFETY_STOCK']:.0f}, "
        reasoning += f"Reorder point: {row['REORDER_POINT']:.0f}. "
        
        if factors:
            reasoning += "Risk factors: " + ", ".join(factors) + ". "
        
        if not forecast_df.empty and 'PREDICTED_DEMAND' in forecast_df.columns:
            next_week_demand = forecast_df.head(7)['PREDICTED_DEMAND'].sum()
            reasoning += f"Forecasted next 7 days demand: {next_week_demand:.0f}. "
        
        if row.get('SUPPLIER_CONFIDENCE_SCORE'):
            reasoning += f"Supplier confidence: {row['SUPPLIER_CONFIDENCE_SCORE']:.0%}. "
        
        return reasoning
    
    def decide_action(self, row, risk_score):
        """Make autonomous decision based on risk score and thresholds"""
        if risk_score >= 0.7 and row.get('RECOMMENDED_ORDER_QTY', 0) > 0:
            return 'ORDER_IMMEDIATELY', row['RECOMMENDED_ORDER_QTY']
        elif risk_score >= 0.4 and row.get('RECOMMENDED_ORDER_QTY', 0) > 0:
            return 'PLACE_ORDER', row['RECOMMENDED_ORDER_QTY']
        elif risk_score >= 0.2:
            return 'MONITOR_ONLY', 0
        else:
            return 'NO_ACTION', 0
    
    def execute_action(self, row, decision, quantity, confidence, reasoning):
        """Execute or simulate the action"""
        if decision in ['ORDER_IMMEDIATELY', 'PLACE_ORDER'] and quantity > 0:
            # Check if we're in SIMULATION mode
            if self.run_mode.upper() == 'SIMULATION':
                # Simulation mode - just log
                action_result = f"SIMULATION: Would create PO for {quantity} units"
            else:  # AUTOMATIC mode
                try:
                    # Get first supplier from active_suppliers
                    supplier = row['active_suppliers'].split(',')[0].strip() if row['active_suppliers'] else 'UNKNOWN'
                    
                    # Call autonomous PO creation using SQL
                    result_df = self.session.sql(f"""
                        SELECT COALESCE(
                            create_autonomous_purchase_order(
                                '{row['MATERIAL_ID']}',
                                '{row['PLANT']}',
                                {quantity},
                                '{supplier}',
                                {confidence},
                                '{reasoning.replace("'", "''")}'
                            ), 
                            'PO created'
                        ) as result
                    """).collect()
                    
                    if result_df and len(result_df) > 0:
                        action_result = str(result_df[0]['RESULT'])
                    else:
                        action_result = "PO created but no result returned"
                        
                except Exception as e:
                    action_result = f"Error creating PO: {str(e)}"
        else:
            action_result = f"No action needed (confidence: {confidence:.0%})"
        
        return action_result
    
    def run(self):
        """Main agent execution loop"""
        results = []
        
        # Get items to analyze
        df = self.analyze_inventory_items()
        
        if df.empty:
            # Return a single row if no items to analyze
            return [(
                self.execution_id,
                'NONE',
                'NONE',
                'NO_ACTION',
                0.0,
                1.0,
                "No items requiring attention found"
            )]
        
        for _, row in df.iterrows():
            try:
                # Get additional data
                forecast_df = self.get_demand_forecast(row['MATERIAL_ID'], row['PLANT'])
                patterns_df = self.search_demand_patterns(row['MATERIAL_ID'], row['PLANT'])
                
                # Calculate risk
                risk_score, factors = self.calculate_risk_score(row, forecast_df, patterns_df)
                
                # Generate reasoning
                reasoning = self.generate_reasoning(row, risk_score, factors, forecast_df)
                
                # Decide action
                decision, quantity = self.decide_action(row, risk_score)
                
                # Execute action
                action_result = self.execute_action(row, decision, quantity, 1-risk_score, reasoning)
                
                results.append((
                    self.execution_id,
                    str(row['MATERIAL_ID']),
                    str(row['PLANT']),
                    decision,
                    float(quantity) if quantity else 0.0,
                    float(1-risk_score),
                    reasoning + " " + action_result
                ))
            except Exception as e:
                # Log error and continue with next item
                results.append((
                    self.execution_id,
                    str(row.get('material_id', 'UNKNOWN')),
                    str(row.get('plant', 'UNKNOWN')),
                    'ERROR',
                    0.0,
                    0.0,
                    f"Error processing item: {str(e)}"
                ))
        
        return results
$$;

call inventory_replenishment_agent('SYMULATION');
call inventory_replenishment_agent(); --create entries into log


--------------------------------------------------
-- 5. Supporting Tables for Agent Operations
--------------------------------------------------
-- Create audit log table
CREATE OR REPLACE TABLE agent_audit_log (
    audit_id VARCHAR(36) PRIMARY KEY,
    agent_name VARCHAR(100),
    action_type VARCHAR(50),
    material_id VARCHAR(18),
    plant VARCHAR(4),
    supplier_id VARCHAR(10),
    order_quantity NUMBER,
    confidence_score FLOAT,
    order_date DATE,
    expected_delivery DATE,
    agent_notes VARCHAR(1000),
    execution_status VARCHAR(20),
    created_at TIMESTAMP,
    synced_to_sap_at TIMESTAMP
);

-- Create SAP PO staging table
CREATE OR REPLACE TABLE sap_po_staging (
    po_number VARCHAR(36) PRIMARY KEY,
    material_id VARCHAR(18),
    plant VARCHAR(4),
    supplier_id VARCHAR(10),
    quantity NUMBER,
    order_date DATE,
    delivery_date DATE,
    confidence_score FLOAT,
    audit_id VARCHAR(36),
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    synced_at TIMESTAMP,
    sap_response VARIANT
);

-- Create agent performance tracking
CREATE OR REPLACE TABLE agent_performance (
    performance_id VARCHAR(36) PRIMARY KEY,
    agent_name VARCHAR(100),
    execution_id VARCHAR(20),
    execution_date DATE,
    items_analyzed NUMBER,
    orders_created NUMBER,
    total_order_value NUMBER,
    avg_confidence FLOAT,
    execution_time_seconds NUMBER,
    created_at TIMESTAMP
);

---------------------------------------
--6. Agent Monitoring and Dashboard
---------------------------------------
-- Create monitoring view
CREATE OR REPLACE VIEW agent_performance_dashboard AS
SELECT 
    DATE_TRUNC('hour', created_at) as time_bucket,
    agent_name,
    COUNT(*) as decisions_made,
    SUM(CASE WHEN action_type = 'AUTONOMOUS_PO_CREATION' THEN 1 ELSE 0 END) as pos_created,
    AVG(confidence_score) as avg_confidence,
    SUM(order_quantity) as total_quantity_ordered,
    COUNT(DISTINCT material_id) as unique_materials,
    COUNT(DISTINCT supplier_id) as unique_suppliers
FROM agent_audit_log
WHERE created_at >= DATEADD(day, -7, CURRENT_DATE)
GROUP BY 1, 2
ORDER BY 1 DESC;

-- for streamlit
GRANT CREATE STREAMLIT ON SCHEMA SAP_BDC_HORIZON_CATALOG.AGENTS TO ROLE SAP_SCENARIO_1_ROLE;

-- Create stage for Streamlit files
CREATE OR REPLACE STAGE SAP_BDC_HORIZON_CATALOG.AGENTS.streamlit_stage
DIRECTORY = (ENABLE = TRUE);

-- Create Streamlit app configuration
CREATE OR REPLACE STREAMLIT inventory_agent_dashboard
ROOT_LOCATION = '@SAP_BDC_HORIZON_CATALOG.AGENTS.streamlit_stage'
MAIN_FILE = 'inventory_agent_dashboard.py'
TITLE = 'inventory_agent_dashboard'
QUERY_WAREHOUSE = 'SAP_COMPUTE';

-- after the command above load the file from the terminal
snow stage copy ./inventory_agent_dashboard.py @SAP_BDC_HORIZON_CATALOG.AGENTS.streamlit_stage


SHOW STREAMLITS IN SCHEMA SAP_BDC_HORIZON_CATALOG.AGENTS;

-- Note: The dashboard.py file must be uploaded to the stage @SAP_BDC_HORIZON_CATALOG.AGENTS.streamlit_stage





 

 -- Supplier Performance Summary for Agent Analysis validate data creation
WITH supplier_base AS (
    SELECT 
        LIFNR,
        NAME1,
        COUNT(*) as total_pos,
        
        -- Calculate on-time deliveries (within 5 days of requested date)
        SUM(CASE 
            WHEN EINDT <= BEDAT + INTERVAL '5 days' 
                 AND (LOEKZ IS NULL OR LOEKZ = '')
            THEN 1 ELSE 0 
        END) as on_time_count,
        
        -- Calculate lead time in days for completed POs only
        AVG(CASE 
            WHEN WEMNG >= MENGE * 0.95  -- At least 95% received
                 AND EINDT IS NOT NULL 
                 AND (LOEKZ IS NULL OR LOEKZ = '')
            THEN DATEDIFF(day, BEDAT, EINDT)
            ELSE NULL 
        END) as avg_lead_time,
        
        -- Calculate reliability score based on multiple factors
        AVG(CASE 
            -- Cancelled POs
            WHEN LOEKZ = 'L' THEN 0.0
            -- Completely undelivered and overdue
            WHEN REMNG = MENGE AND EINDT < CURRENT_DATE THEN 0.1
            -- Mostly undelivered and overdue
            WHEN REMNG > MENGE * 0.5 AND EINDT < CURRENT_DATE THEN 0.2
            -- Partially delivered, late
            WHEN WEMNG < MENGE * 0.95 AND EINDT < CURRENT_DATE THEN 0.3
            -- Very late (>7 days)
            WHEN EINDT > BEDAT + INTERVAL '7 days' THEN 0.4
            -- Late (3-7 days)
            WHEN EINDT > BEDAT + INTERVAL '3 days' THEN 0.6
            -- Slightly late (1-3 days)
            WHEN EINDT > BEDAT + INTERVAL '1 day' THEN 0.8
            -- On time or early
            WHEN EINDT <= BEDAT THEN 1.0
            -- Open POs not yet due
            WHEN REMNG > 0 AND EINDT >= CURRENT_DATE THEN 0.9
            -- Default
            ELSE 0.5
        END) as avg_reliability_score,
        
        -- Count currently overdue POs
        SUM(CASE 
            WHEN REMNG > 0 AND EINDT < CURRENT_DATE 
            THEN 1 ELSE 0 
        END) as overdue_count

    FROM SAP_BDC_HORIZON_CATALOG.S4HANA_ALL_REGIONS.ME2N
    WHERE BSTYP = 'F'  -- Focus on purchase orders
    GROUP BY LIFNR, NAME1
)
SELECT 
    CONCAT(supplier_base.LIFNR, ' (', supplier_base.NAME1, ')') as "Supplier",
    supplier_base.total_pos as "Total POs",
    
    -- On-Time Percentage
    CASE 
        WHEN supplier_base.total_pos > 0 
        THEN ROUND(supplier_base.on_time_count * 100.0 / supplier_base.total_pos, 0) || '%'
        ELSE 'N/A'
    END as "On-Time %",
    
    -- Average Lead Time
    CASE 
        WHEN supplier_base.avg_lead_time IS NOT NULL 
        THEN ROUND(supplier_base.avg_lead_time, 1) || ' days'
        ELSE 'N/A'
    END as "Avg Lead Time",
    
    -- Average Reliability Score
    ROUND(supplier_base.avg_reliability_score, 2) as "Avg Reliability Score",
    
    -- Status Classification
    CASE 
        WHEN supplier_base.total_pos >= 3 AND supplier_base.avg_reliability_score >= 0.95 THEN 'Excellent'
        WHEN supplier_base.total_pos >= 3 AND supplier_base.avg_reliability_score >= 0.80 THEN 'Good'
        WHEN supplier_base.total_pos >= 3 AND supplier_base.avg_reliability_score >= 0.70 THEN 'Good (long lead)'
        WHEN supplier_base.total_pos >= 3 AND supplier_base.avg_reliability_score >= 0.50 THEN 'Fair'
        WHEN supplier_base.total_pos >= 3 AND supplier_base.avg_reliability_score < 0.50 AND supplier_base.overdue_count > 2 THEN 'POOR - CRISIS'
        WHEN supplier_base.total_pos >= 3 AND supplier_base.avg_reliability_score < 0.50 THEN 'POOR - CRITICAL'
        WHEN supplier_base.total_pos < 3 THEN 'Unknown'
        ELSE 'N/A'
    END as "Status",
    
    -- Additional context for agent
    supplier_base.overdue_count as "Overdue POs"

FROM supplier_base
WHERE supplier_base.LIFNR IS NOT NULL
ORDER BY supplier_base.LIFNR,
    -- Order by worst performers first
    CASE 
        WHEN supplier_base.avg_reliability_score < 0.50 THEN 1
        WHEN supplier_base.avg_reliability_score IS NULL THEN 2
        WHEN supplier_base.avg_reliability_score < 0.70 THEN 3
        ELSE 4
    END,
    supplier_base.avg_reliability_score ASC;

/*
Supplier Performance Summary for Agent Analysis
Supplier	Total POs	On-Time %	Avg Lead Time	Avg Reliability Score	Status
VEN-001 (SteelCo)	    5	80%	    13.2 days	0.85	Good
VEN-002 (PlastiCorp)	5	100%	6.4 days	0.98	Excellent
VEN-003 (ElectroWorld)	5	80%	    21.2 days	0.88	Good (long lead)
VEN-005 (ElectroComp)	3	0%	     N/A	    0.30	POOR - CRITICAL
VEN-006 (ChemSupply)	5	80%	     10.4 days	0.86	Good
VEN-007 (RawMaterials)	7	29%	   19.5 days	0.45	POOR - CRISIS
VEN-008 (NewSupplier)	1	N/A	    N/A	        0.70	Unknown
*/





 -- Query the inventory semantic view to see current status
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
    next_7_days_requirements,
    arriving_7_days_qty,
    avg_lead_time,
    reliability_score,
    reorder_trigger_amount,
    excess_over_safety,
    available_stock
FROM INVENTORY_SEMANTIC_VIEW
WHERE stock_status IN ('CRITICAL', 'REORDER')
ORDER BY 
    CASE stock_status WHEN 'CRITICAL' THEN 1 WHEN 'REORDER' THEN 2 ELSE 3 END,
    current_stock;

-- Run agent in SIMULATION mode to see decisions
SELECT * FROM TABLE(inventory_replenishment_agent('SIMULATION'));


-- Test demand prediction for critical items
SELECT * FROM TABLE(predict_demand('ELEC-001-IC-MAIN', 'PL01', 30));

-- Search for urgent demand patterns
SELECT 
    pattern_id,
    material_description,
    requirement_date,
    requirement_qty,
    search_text,
    metadata:priority as priority
FROM INVENTORY_DEMAND_SEARCH
WHERE requirement_date <= DATEADD(day, 7, CURRENT_DATE)
    AND metadata:priority = 'HIGH'
ORDER BY requirement_date;

-- Test PO creation for ELEC-001-IC-MAIN
CALL create_autonomous_purchase_order(
    'ELEC-001',
    'PL01',
    10000,
    'SUP-ELE02',
    0.95,
    'Critical stock situation with high confidence supplier'
);

-- Check staging table
SELECT * FROM sap_po_staging ORDER BY created_at DESC;



-- Current inventory crisis summary
SELECT 
    stock_status,
    COUNT(*) as material_count,
    SUM(current_stock) as total_stock,
    SUM(safety_stock) as total_safety,
    SUM(recommended_order_qty) as total_recommended_order,
    AVG(supplier_confidence_score) as avg_supplier_confidence
FROM INVENTORY_SEMANTIC_VIEW
GROUP BY stock_status;



