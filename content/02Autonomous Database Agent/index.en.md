---
title : "Use Database Agent to diagnose and remediate"
weight : 07
---

In the previous module, you manually investigated a database performance issue — just like a DBA would every day. 

Now, you'll see how an **AI agent** can automate the entire investigation and even implement fixes automatically. We'll demonstrate the end goal using a **prebuilt agent** that can analyze database metrics, identify performance bottlenecks, recommend optimizations with explanations, and implement fixes autonomously. This lets you experience the outcome before building your own agents in the next module.

:::alert{header="Goal" type="info"}
Demonstrate how AI can turn a manual investigation into automated analysis with intelligent recommendations and safe implementations.
:::

### Step 1: Start Your Database Agent

:::alert{header="Action Required" type="warning"}
In VS Code Server, open a new terminal, and run the following command to start the database agent:
:::

:::code{language=bash showLineNumbers=false showCopyAction=true}
python /workshop/bootstrap/supervisor_agent_baked.py
:::

As part of the setup, we've already created a **database agent** for you to use in this module. But hang tight — once you see the impact of an autonomous agent, you'll also learn how to build one yourself.

:::alert{header="Whats happening behind the scenes?" type="info"}
When the agent starts, it connects to multiple tools — specialized capabilities that give the agent "superpowers" for database analysis.
When you see the **"Request:"** prompt, your database agent is ready and waiting for your questions. The agent runs locally on your VS Code server instance, giving you full control over its operations.
::: 

::::expand{header="🔐 Screenshot (click to expand)"}
![Start Database Agent](/static/dat302-images/startdbagent.jpg)
::::


### Step 2: Interactive Database Analysis

#### Question 1: Get Current Database Metrics

:::alert{header="Action Required" type="warning"}
**Copy and paste** the following question at the agent prompt and press **Enter**:
:::

:::code{language=bash showLineNumbers=false showCopyAction=true}
On my primary/writer instance of Aurora cluster, what is current CPU utilization, number of database connections, and average QueriesFinished metric in last 60 mins?
:::

:::alert{header="What did database agent do?" type="info"}
The agent selects the appropriate tools: first, `discover_aurora_clusters` to identify the Aurora primary instance, and then `get_metric_statistics` to retrieve CPU utilization, connection counts, and queries-per-second metrics. It analyzes the last 60 minutes of data to provide a complete view of recent performance trends. This is the same information you gathered manually from Database Insights in the previous module — but now the AI agent retrieves it automatically and presents it **conversationally**.
::: 

::::expand{header="🔐 Screenshot (click to expand)"}
![First Question](/static/dat302-images/firstquestion.jpg)
::::


#### Question 2: Full Analysis and Implement Fixes

:::alert{header="Action Required" type="warning"}
Ask the agent to analyze the database, identify bottlenecks, and implement fixes. **Copy and paste** the following question:
:::

:::code{language=bash showLineNumbers=false showCopyAction=true}
Review database activity and identify root cause of high CPU utilization. Implement fixes one at a time and only ones that will have minimal impact on production.
:::


:::alert{header="What's Happening" type="info"}
The agent is now performing a comprehensive analysis that includes analyzing database metrics to identify the root cause, examining execution plans to understand query performance issues, implementing fixes automatically that have minimal impact, and providing recommendations for operators to run during off-peak hours or maintenance windows.
::: 


If the agent is working correctly, it should automatically create two critical indexes:
- An index on the **email** field in the **employees** table
- Second index on **last_name** field with operator `text_pattern_ops` to optimize pattern matching queries

:::alert{header="Why This Is Significant" type="info"}
The agent didn't just identify the problems - it actually fixed them. It created indexes using `CREATE INDEX CONCURRENTLY`, which means no downtime or blocking of other database operations. This is exactly what an experienced DBA would do.
::: 

::::expand{header="🔐 Screenshot (click to expand)"}
![Fourth Question](/static/dat302-images/fourthaquestion.jpg)
::::




### Step 3: Verify the Results

#### Check Database Load in Database Insights

:::alert{header="Action Required" type="warning"}
Switch back to Database Insights in your browser and look at the database load graph:
1. Switch the **Sliced by** dropdown to **Waits**
2. **Select** the time period to **10m** using Custom option
3. Click on **refresh**
:::


::::expand{header="🔐 Screenshot (click to expand)"}
![Database Insights Load](/static/dat302-images/dbinsightsdbload.jpg)
::::


:::alert{header="What to look for?" type="info"}
You should see a reduction in the CPU-dominant wait event pattern after the agent implemented the index optimizations.
::: 

#### Analyze Key Performance Metrics in Database Insights

:::alert{header="Action Required" type="warning"}
Switch to the Database Telemetry tab in Database Insights and examine these critical metrics:
:::

1. **CPU Utilization**: Should be lower after optimization
2. **Queries (Per second)**: Should go up after optimization
3. **Tuples: Reads (Tuples per second)**: This should go down. Fewer tuple reads mean the database is retrieving data more efficiently, reducing I/O and CPU usage

:::alert{header="Note" type="info"}
Metrics can take up to couple of mins to update. Refresh the dashboard every few seconds to see the latest data.
:::

::::expand{header="🔐 Screenshot (click to expand)"}
![Database Telemetry](/static/dat302-images/qps-dbinsights.jpg)
::::


:::alert{header="Success Indicator" type="info"}
If queries per second have increased, your e-commerce app is now processing more customer activity — the ultimate sign of improved performance.
::: 

:::alert{header="Action Required" type="warning"}
Back in the terminal, quit the database agent by typing `exit` and press enter:
:::

:::code{language=bash showLineNumbers=false showCopyAction=true}
exit
:::

### What You Just Experienced

You witnessed database operations transform from manual investigation across multiple dashboards to automated AI-powered analysis with automatic fixes. The agent gathered database metrics, interpreted execution plans like a senior DBA, implemented optimizations using non-blocking operations, and explained its reasoning in plain English. This demonstrates how agentic AI handles routine database troubleshooting.


### What's Next

Now that you've experienced the power of AI-driven database operations, you're ready to learn how to build these capabilities yourself. In the upcoming modules, you'll discover:

1. How to create database agent with tools to access Aurora PostgreSQL metrics
2. How to integrate multiple AI agents for comprehensive database operations
