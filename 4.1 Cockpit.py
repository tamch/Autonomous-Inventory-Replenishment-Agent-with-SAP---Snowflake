import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
from snowflake.snowpark.context import get_active_session

st.set_page_config(
    page_title="Inventory Replenishment Agent",
    page_icon="🤖",
    layout="wide"
)

session = get_active_session()

st.title("🤖 Autonomous Inventory Replenishment Agent")

# Sidebar for controls
with st.sidebar:
    st.header("Agent Controls")
    run_mode = st.selectbox("Run Mode", ["SIMULATION", "AUTOMATIC"])
    if st.button("Run Agent Now"):
        with st.spinner("Agent is analyzing inventory..."):
            result = session.sql(f"SELECT * FROM TABLE(inventory_replenishment_agent('{run_mode}'))").to_pandas()
            st.success(f"Agent executed! Analyzed {len(result)} items")
            st.dataframe(result)

# Main dashboard
col1, col2, col3, col4 = st.columns(4)

# Get metrics
metrics = session.sql("""
    SELECT 
        COUNT(DISTINCT material_id) as critical_items,
        AVG(confidence_score) as avg_confidence,
        SUM(order_quantity) as total_ordered,
        COUNT(*) as total_decisions
    FROM AGENTS.agent_audit_log 
    WHERE created_at >= CURRENT_DATE
""").to_pandas()

with col1:
    st.metric("Critical Items Today", metrics['CRITICAL_ITEMS'].iloc[0] if not metrics.empty else 0)
with col2:
    st.metric("Avg Confidence", f"{metrics['AVG_CONFIDENCE'].iloc[0]:.1%}" if not metrics.empty else "0%")
with col3:
    st.metric("Units Ordered", f"{metrics['TOTAL_ORDERED'].iloc[0]:,.0f}" if not metrics.empty else 0)
with col4:
    st.metric("Decisions Made", metrics['TOTAL_DECISIONS'].iloc[0] if not metrics.empty else 0)

# Recent decisions
st.subheader("Recent Agent Decisions")
recent = session.sql("""
    SELECT 
        created_at,
        material_id,
        plant,
        action_type,
        order_quantity,
        confidence_score,
        agent_notes
    FROM AGENTS.agent_audit_log
    ORDER BY created_at DESC
    LIMIT 100
""").to_pandas()
st.dataframe(recent)


col_chart1, col_chart2 = st.columns(2)
        
with col_chart1:
    st.subheader("📊 Performance Over Time")
    perf = session.sql("""
        SELECT 
            DATE_TRUNC('HOUR', created_at) AS HOUR,
            COUNT(*) AS DECISIONS,
            AVG(confidence_score) AS CONFIDENCE
        FROM AGENTS.agent_audit_log
        WHERE created_at >= DATEADD(day, -1, CURRENT_DATE)
        GROUP BY 1
        ORDER BY 1
    """).to_pandas()

    if not perf.empty:
        fig = go.Figure()

        # Decisions (primary Y)
        fig.add_trace(go.Scatter(
            x=perf['HOUR'],
            y=perf['DECISIONS'],
            name='Decisions',
            mode='lines+markers',
            line=dict(color='#4CAF50', width=2)
        ))

        # Confidence % (secondary Y)
        fig.add_trace(go.Scatter(
            x=perf['HOUR'],
            y=perf['CONFIDENCE'] * 100,  # 0–1 -> 0–100
            name='Confidence %',
            mode='lines+markers',
            line=dict(color='#2196F3', width=2),
            yaxis='y2'
        ))

        fig.update_layout(
            xaxis_title="Time",
            yaxis=dict(title="Number of Decisions"),
            yaxis2=dict(
                title="Confidence %",
                overlaying='y',
                side='right'
            ),
            #hovermode='x unified',
            height=400
        )

        st.plotly_chart(fig, use_container_width=True)
    else:
        st.info("No performance data available")

        
with col_chart2:
    st.subheader("🎯 Action Type Distribution")
    action = session.sql("""
        SELECT 
        ACTION_TYPE,
        COUNT(*) as AST
        FROM AGENTS.agent_audit_log
        WHERE created_at >= (CURRENT_DATE - INTERVAL '7 days')
        GROUP BY action_type
        ORDER BY AST DESC
        """).to_pandas()
    
    if not action.empty:
        fig = px.pie(
            action, 
            names='ACTION_TYPE',
            values='AST', 
            color_discrete_sequence=px.colors.qualitative.Set3
            )
        fig.update_layout(
            height=400,
            uniformtext_minsize=12,
            uniformtext_mode="hide",
        )
        st.plotly_chart(fig, use_container_width=True)
        #st.dataframe(action)
    else:
        st.info("No action data available")

##############

# Items needing attention
st.subheader("Items Requiring Attention")
attention = session.sql("""
    SELECT * FROM TABLE(AGENTS.analyze_inventory_status())
    WHERE stock_status IN ('CRITICAL', 'REORDER')
    ORDER BY 
        CASE stock_status WHEN 'CRITICAL' THEN 1 WHEN 'REORDER' THEN 2 ELSE 3 END,
        current_stock
    LIMIT 50
""").to_pandas()
st.dataframe(attention)