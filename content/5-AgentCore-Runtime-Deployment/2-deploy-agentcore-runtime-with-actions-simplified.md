---
title: "2. Create Lambda to trigger AgentCore Runtime"
weight: 20
---

In the previous module, you deployed the agent to AgentCore. Now you'll build the automation that triggers the agent when the database is under stress.

You'll use a CloudWatch Alarm to detect when CPU usage exceeds 80%, and a Lambda function to invoke the agent automatically.

### Setting up Lambda and CloudWatch Alarm trigger

In this section, we will:

1. Create a Lambda function that will invoke the deployed agent in AgentCore.

2. Set up a trigger so that the Lambda function executes automatically whenever a CloudWatch Alarm enters the ALARM state (CPU Utilization > 80%).

:::alert{header="Action Required" type="warning"}
Run the following shell script in your terminal that will do above two steps for us:
:::

:::code{language=python showLineNumbers=false showCopyAction=true}
bash /workshop/agentcore/setup-lambda-cwalarmtrigger.sh
:::

### Trigger the Workflow

Now that the automation is set up, let's see the workflow in action by dropping the indexes. This will cause a CPU spike to trigger the alarm.

:::alert{header="Action Required" type="warning"}
Run the following command in terminal:
:::

:::code{language=bash showLineNumbers=false showCopyAction=true}
psql -t -c "SELECT 'DROP INDEX IF EXISTS ' || i.indexname || ';' FROM pg_indexes i JOIN pg_class c ON i.indexname = c.relname JOIN pg_index idx ON c.oid = idx.indexrelid WHERE i.tablename = 'employees' AND array_length(idx.indkey, 1) = 1 AND EXISTS (SELECT 1 FROM pg_attribute a WHERE a.attrelid = idx.indrelid AND a.attnum = idx.indkey[0] AND a.attname IN ('email', 'last_name'));SELECT pg_stat_statements_reset();" | psql
:::

CPU will start increasing over the next 2-3 minutes. Continue to the next module to verify the workflow.


::::expand{header="🔐 Optional # Want to review components deployed in first step by setup-lambda-cwalarmtrigger.sh?  (click to expand)"}

If you want to explore the components created by `setup-lambda-cwalarmtrigger.sh`, start by running the following command in a new terminal:

:::code{language=python showLineNumbers=false showCopyAction=true}
aws cloudwatch describe-alarms \
  --alarm-names dat302-autodbops-labs-aurora-writer-cpu-alarm \
  --query 'MetricAlarms[0].{Threshold:Threshold,Actions:AlarmActions[0],State:StateValue}' \
  --output table
:::

This CLI command shows the CloudWatch Alarm action triggered when CPU exceeds 80%. As you can see from the output, it triggers the Lambda function.

Now let's look at the Lambda code by running the following CLI command:


:::code{language=python showLineNumbers=false showCopyAction=true}
aws lambda get-function --function-name database-operations-invoker \
  --query 'Code.Location' --output text | \
  xargs curl -s | \
  python3 -c "import sys, zipfile, io; z=zipfile.ZipFile(io.BytesIO(sys.stdin.buffer.read())); print(z.read('database-operations-invoker.py').decode())" | \
  grep -E -A 15 "(prompt\s*=|invoke_agent_runtime)"
:::

The output shows code snippets from the Lambda function. First, it displays the prompt defined for the agent, then the call to `invoke_agent_runtime` API. This API invokes the agent deployed on Bedrock AgentCore.

So when database instance CPU breaches 80%, the Lambda function is triggered and invokes the agent.

::::


### Summary and Next Step

You've deployed a Lambda function that invokes the agent, configured a CloudWatch Alarm to trigger it when CPU exceeds 80%, and initiated a CPU spike. In the next module, you'll verify the automated workflow is working.
