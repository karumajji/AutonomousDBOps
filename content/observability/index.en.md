---
title : "First stop: database observability"
weight : 05
---

Your first stop in a crisis situation is usually the observability dashboard, where you identify what's going on with your database. You'll do the same in this session.

RDS/Aurora provides CloudWatch Database Insights, a one-stop observability feature that gives you a fleet-wide view of database health. 

:::alert{header="Goal" type="info"}
Learn how to identify database performance issues using CloudWatch Database Insights.
:::

### Step 1: Access Database Insights

:::alert{header="Action Required" type="warning"}
1. In AWS Console, use the search bar to find **Database Insights** and click on it.
:::

::::expand{header="🔐 Screenshot (click to expand)"}
![WSSignin](/static/dat302-images/searchdbinsights.jpg)
::::


### Step 2: Fleet Health Overview

Once you're in **Database Insights**, you'll see the **Fleet Health Dashboard**, which displays your database instances in an intuitive honeycomb visualization. Each hexagon represents a database instance running in your AWS account, making it easy to quickly spot issues across your entire database fleet at a glance.

1. For this workshop, your Aurora PostgreSQL cluster consists of **one primary instance** and **one reader instance**, so you should see two hexagons. Notice that one hexagon appears in red — this is Database Insights' way of indicating that something is wrong with that instance. The red color signals performance issues that require immediate attention.

2. You'll also notice that an **alarm** has been triggered and is showing in an **active state**. This is exactly what you'd see in a real production environment when your database is experiencing performance problems.

![WSSignin](/static/dat302-images/dbinsights1.jpg)  



As you view the data, pay attention to the patterns you observe — these will help you understand what's causing the performance degradation.

### Step 3: Analyze Database Load

:::alert{header="Action Required" type="warning"}
1. Switch to the Database Instance view by clicking the **Database Instance** radio button on the left
2. Change the time period to **30m** using the time selector at the top
:::

1. **Instance focus** - The view shows a specific database instance.

2. **Time period** - The graph displays a recent time slice.

3. **Database Load (DB Load) graph** - This measures session activity in your database. DB Load is a key metric in Database Insights, collected every second for real-time monitoring.

4. **Wait events** - The default view is sliced by Waits, showing what resources sessions are waiting for. Understanding wait patterns helps identify bottlenecks.

5. **CPU waits** - The most common wait type is CPU. High CPU waits typically indicate too many concurrent connections competing for resources, or query plans using CPU-intensive operations (like sequential scans). These often result from workload changes, inefficient queries, or missing indexes.

![Database Instance View](/static/dat302-images/dbinstanceview.jpg)


Let's see if we can narrow this down further. 


### Step 4: Identify Top SQL

:::alert{header="Action Required" type="warning"}
In Database Insights, scroll down to DB Load Analysis section and view the Top SQL.
:::

::::expand{header="🔐 Screenshot (click to expand)"}
![DB Load Analysis](/static/dat302-images/dbload.jpg)
::::



As you view the **Top SQL** statements, you should notice some clear patterns emerging. There's a `DELETE` statement that's consuming an excessive amount of database resources - often a red flag, as DELETE operations can be particularly expensive if they're not properly optimized. You'll also see `SELECT` statements on the *employees* table that are showing up high in the resource consumption list.

These queries represent your **performance bottlenecks**. In a real production environment, these would be the queries you'd focus on optimizing first because they're having the biggest impact on overall database performance. This approach - identifying the most expensive queries first - is exactly how experienced DBAs troubleshoot performance issues. Rather than trying to optimize everything at once, you focus your efforts on the queries that will give you the biggest performance improvement.

### Step 5: Deep Dive - Execution Plans

Now that you've identified the problematic queries, it's time to understand why they're performing poorly. This requires examining the **execution plans** — the step-by-step approach PostgreSQL uses to execute each query. Execution plans reveal whether queries are using indexes efficiently, performing unnecessary scans, or using suboptimal joins.

In **Aurora PostgreSQL**, you can turn on tracking of execution plans using the `aurora_compute_plan_id` parameter. Each executed query gets a plan identifier reused for subsequent executions.

This feature is disabled by default (`aurora_compute_plan_id = 0`). You can enable it by setting it to `1` in the parameter group.

The parameter can be enabled on an existing cluster **without rebooting the instance**, and it can be turned on temporarily while investigating performance issues. For this workshop, it is already enabled to save on time. 

:::alert{header="Action Required" type="warning"}
Navigate to Top SQL, select the first query (`DELETE`), and scroll down to Plans.
:::


::::expand{header="🔐 Screenshot (click to expand)"}
![WSSignin](/static/dat302-images/executionplan.jpg)
::::



When analyzing execution plans, focus on high cost operations. Also, look for **sequential scans** instead of **index scans** — a sign that PostgreSQL is reading entire tables rather than using indexes. If you see sequential scans on large tables, especially in `WHERE` clauses or `JOIN` conditions, adding an appropriate index can dramatically improve performance. 

::::expand{header="🔐 screenshot (click to expand)"}
![WSSignin](/static/dat302-images/seqscan.jpg)
::::



These are exactly the optimization opportunities that AI agents can automatically identify and fix. Before proceeding further, remove selection on `DELETE` query.

:::alert{header="Action Required" type="warning"}
On DB Load graph, you will notice that graph is scoped to a single `DELETE` statement. Click on **X** next to SQL statement to remove the focus from a single query.
:::

::::expand{header="🔐 Screenshot (click to expand)"}
![WSSignin](/static/dat302-images/removescope.jpg)
::::


### Step 6: Analyze Database Metrics

:::alert{header="Action Required" type="warning"}
Scroll down and navigate to Database Telemetry and click on the Metrics tab. Take note of the current values for these key metrics:
:::


- **CPU Utilization** shows you how hard your database server is working. Database Insights reports CPU usage by the database engine as `os.cpuUtilization.nice.avg`. What do you notice here?

- **Queries per Second** indicates the volume of queries hitting your database. Currently, it is in the low double digits, so the database is not processing a large number of queries at this time.

- **Tuples: Reads (Tuples per second)** shows how much data is being read by queries. You will observe a high number of tuples (in the millions) being returned. 

Record these values—you'll compare them later when we implement AI-driven implementation. These are the same metrics that AI agents will automatically analyze to detect and fix performance issues.

::::expand{header="🔐 Screenshot (click to expand)"}
![Database Telemetry](/static/dat302-images/dbtelemetry.jpg)
::::


### Step 7: Aurora PostgreSQL Client

With the steps above, you now have a good understanding of problem statement. 

Database Insights makes it easier by bringing all metrics in single place, but we can take it further by providing metrics to AI to generate tailored recommendations. 

But before you transition to next section on Agentic AI, let's configure our client instance.

:::alert{header="Action Required" type="warning"}
1. Go to the tab where you have opened **VS Code Server**. Any pop-ups in the lower-right corner can be safely ignored or closed.
2. Click **Explorer** to view files in the workshop directory. 
3. The terminal at the bottom right is where you'll run commands. 
4. Later, you'll open multiple terminals by clicking the **+** icon as shown below.
:::

::::expand{header="🔐 Screenshot (click to expand)"}
![WSSignin](/static/dat302-images/ws-vscodeserver.jpg)
::::



:::alert{header="Action Required" type="warning"}
In the terminal, run the following commands to install Python packages, set up the PostgreSQL client, export environment variables, and set up Bedrock AgentCore.

When copying and pasting these commands into the VS Code terminal, your browser may ask for permission — go ahead and allow it.

While running, you will see a message to enter your **email address**. This is for Simple Notification Service (SNS) that you will use in the last module. Enter your email and press enter for the script to proceed.
:::

:::code{language=bash showLineNumbers=false showCopyAction=true}
# ---------------------------------------------------------
# Prompt user for email address
# ---------------------------------------------------------
read -p "📧 Enter email address for database alerts: " EMAIL_ADDRESS
echo "--------------------------------"
echo "Alert email address: $EMAIL_ADDRESS"
echo "--------------------------------"
echo "📨 Creating SNS topic for database alerts..."
SNS_TOPIC_ARN=$(aws sns create-topic --name agentcore-database-alerts --query 'TopicArn' --output text)
echo "export SNS_TOPIC_ARN=\"$SNS_TOPIC_ARN\"" >> ~/.bashrc
echo "SNS Topic ARN: $SNS_TOPIC_ARN"

echo "📬 Subscribing $EMAIL_ADDRESS to SNS topic..."
aws sns subscribe --topic-arn "$SNS_TOPIC_ARN" --protocol email --notification-endpoint "$EMAIL_ADDRESS"

echo "✅ Check your email ($EMAIL_ADDRESS) and confirm the SNS subscription."
echo "✅ SNS Topic created and configured: $SNS_TOPIC_ARN"

source /etc/environment
AGENTCORE_ROLE_ARN="arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/AgentCoreDBOpsRole"
echo "export AGENTCORE_ROLE_ARN=\"$AGENTCORE_ROLE_ARN\"" >> ~/.bashrc

# Get VPC configuration from Aurora cluster
SECURITY_GROUP_ID=$(aws rds describe-db-clusters --db-cluster-identifier apgpg-dat302 --region $AWSREGION --query 'DBClusters[0].VpcSecurityGroups[0].VpcSecurityGroupId' --output text)
VPC_ID=$(aws ec2 describe-security-groups --group-ids $SECURITY_GROUP_ID --query 'SecurityGroups[0].VpcId' --output text)
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=*Private*" --query 'Subnets[*].SubnetId' --output text)
SUBNET1=$(echo $SUBNET_IDS | cut -d' ' -f1)
SUBNET2=$(echo $SUBNET_IDS | cut -d' ' -f2)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "export SECURITY_GROUP_ID=$SECURITY_GROUP_ID" >> ~/.bashrc
echo "export VPC_ID=$VPC_ID" >> ~/.bashrc
echo "export SUBNET1=$SUBNET1" >> ~/.bashrc
echo "export SUBNET2=$SUBNET2" >> ~/.bashrc
echo "export AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID" >> ~/.bashrc

cat /etc/environment >> ~/.bashrc
# Source for current session
source ~/.bashrc

echo "⏳ Please wait while the environment is being prepared..."
bash /workshop/agentcore/setup_agentcore.sh \
  > /workshop/agentcore/setup_agentcore_$(date +%F).log 

echo "Setup complete." 
:::

### Summary of Initial Investigation

Congratulations — you've completed the first step in this investigation! You've learned how to use **CloudWatch Database Insights** to form initial hypotheses about database performance issues. The root cause appears to be poor query performance due to missing optimizations — typically indexes that would allow PostgreSQL to access data more efficiently. 

Next, you'll see how a **database agent** can access the same metrics and execution plans, propose a fix with minimal impact, and remediate the issue in production.

**Ready to see how Agentic AI can automate this entire process?**
