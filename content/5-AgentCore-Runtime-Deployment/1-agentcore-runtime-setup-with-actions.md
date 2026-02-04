---
title: "1. AgentCore Runtime Setup"
weight: 10
---

In this section, you'll deploy the health check agent you developed earlier to AgentCore.

### Confirm SNS subscription

To enable email notifications in this module, you need to confirm your Simple Notification Service (SNS) subscription. The setup script you ran earlier sent a confirmation email to the address you provided. Note: Your email address is stored temporarily and will be removed when this workshop session ends.

:::alert{header="Action Required" type="warning"}
1. Go to your email inbox and look for an email with subject "AWS Notification - Subscription Confirmation".
2. Click on the confirmation link to complete the SNS subscription.
:::

::::expand{header="🔐 Screenshot (click to expand)"}
![WSSignin](/static/dat302-images/snssubscription.jpg)
::::


### Health Check Agent for AgentCore

For this module, you will work with a pre-created agent similar to the health check agent: it contains the same logic and tools, with one enhancement: a `send_email_notification` tool that enables the agent to email recommendations to operators.

**Pre-created agent file** :  `/workshop/agentcore/healthcheck_agentcore.py`

### Hosting on Bedrock AgentCore

To host agent on Bedrock AgentCore, you will use two main commands:
1. `agentcore configure` — configures the agent to be deployed on Bedrock AgentCore.
2. `agentcore launch` — deploys the agent on Bedrock AgentCore.

:::alert{header="Action Required" type="warning"}
Run the following commands in the terminal:
:::

:::code{language=python showLineNumbers=false showCopyAction=true}
cd /workshop/agentcore
agentcore configure \
    --entrypoint healthcheck_agentcore.py \
    --name baked_healthcheck_agentcore \
    --execution-role "$AGENTCORE_ROLE_ARN" \
    --requirements-file requirements.txt \
    --vpc \
    --subnets "$SUBNET1,$SUBNET2" \
    --security-groups "$SECURITY_GROUP_ID" \
    --non-interactive
agentcore launch \
    --env AWS_REGION=$AWSREGION \
    --env AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID \
    --env AURORA_CLUSTER_ID=apgpg-dat302 \
    --env AURORA_SECRET_ID=apgpg-dat302-secret \
    --env BEDROCK_MODEL_ID=$BEDROCK_MODEL_ID \
    --env SNS_TOPIC_ARN=$SNS_TOPIC_ARN
:::

Once the agentcore launch command completes, you can check the status of your agent to confirm it is ready.

:::alert{header="Action Required" type="warning"}
Run the following command in your terminal to check agent status:
:::

:::code{language=python showLineNumbers=false showCopyAction=true}
agentcore status --agent baked_healthcheck_agentcore | grep -i "endpoint"
:::

Look for the Endpoint in the output. If you see DEFAULT (READY), it means the agent has been successfully deployed and is ready to use.

::::expand{header="🔐 Screenshot (click to expand)"}
![WSSignin](/static/dat302-images/endpointready.jpg)
::::

