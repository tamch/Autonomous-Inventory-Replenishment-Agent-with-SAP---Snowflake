-- test service, checked if indexed, started  and has rows
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'SAP_BDC_HORIZON_CATALOG.AGENTS.INVENTORY_DEMAND_SEARCH',
    '{
        "query": "late",
        "columns": [
            "pattern_id", 
            "material_description", 
            "requirement_date", 
            "requirement_qty", 
            "search_text", 
            "metadata"
        ],
        "limit": 10
    }'
) AS search_results;