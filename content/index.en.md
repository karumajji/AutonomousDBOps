---
title: "DAT302 | Autonomous DBOps: Agentic AI for maintaining databases"
weight: 0
---
> ⏱️ **Total Time**: 45 minutes (core modules) + 10 minutes (optional AgentCore deployment)


### Introduction

Imagine this: It's 2 AM on a Tuesday. Your database cluster - the beating heart of your e-commerce platform is suddenly choking. CPU is pegged at 95%, queries are timing out, and you are on-call to fix the issue. 

**Here's the kicker: you have exactly 30 mins to identify the culprits, tune the database, and get things stable before the leadership wakes up demanding answers.**

Sounds familiar? We've all been here - manually sifting through CloudWatch metrics, tweaking parameters in panic, and crossing our fingers that a VACUUM ANALYZE doesn't make things worse. But what if you didn't have to? What if you have an autonomous Database Agent - a reasoning sidekick - that could diagnose the bottlenecks, hypothesize fixes, and even implement them autonomously, all while explaining its logic like a senior DBA on caffeine?

Today, in this builder session, we're diving headfirst into that world. There is a running Aurora PostgreSQL database that's already experiencing performance issues. **Your mission : restore database to healthy performance**. We will help you to develop a self-healing database with AI Agents powered by the Strands framework, that can act independently to achieve specific goals. You'll watch them in action — parsing logs, querying metrics, generating SQL optimizations, and iterating on configs — all in real time.

### What you will build today (Architecture)

You’ll explore agentic AI for database operations by building :

1. **Health Check Agent** — identifies top queries by execution time, retrieves execution plans, detects index and table bloat, identifies unused indexes, and generates recommendations.

2. **Actions Agent** — implements database optimizations including creating indexes concurrently, updating table statistics with ANALYZE, and reclaiming space with VACUUM.

3. You’ll then build a **Supervisor Agent** that coordinates both agents, forming an autonomous system that identifies issues, proposes fixes, and applies them with minimal production impact.

4. **(Optional)** You’ll deploy the **Health Check Agent** to the Bedrock AgentCore runtime. When triggered by CloudWatch alarms — such as CPU exceeding 80% — the agent will automatically diagnoses the issue and emails recommendations to operator.


![WSSignin](/static/dat302-images/architecture.jpg)


:::alert{header="Note" type="warning"}
This builder session uses pre-provisioned AWS accounts at AWS re\:Invent 2025. Resources created during the session will not generate charges on your personal AWS account. Access to your account will remain active only for the duration of the session and will be revoked once the session concludes.
:::

**AWS Services Used:**
- [Amazon Aurora PostgreSQL](https://aws.amazon.com/rds/aurora/) - is a fully managed, PostgreSQL-compatible database engine. In this builder session, a database cluster has been provisioned for you, consisting of one primary instance and one reader instance.
- [CloudWatch Database Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Database-Insights.html) - is a feature that centralizes database telemetry and simplifies performance troubleshooting.
- [Amazon Bedrock AgentCore](https://aws.amazon.com/bedrock/agentcore/) - is a secure, serverless runtime purpose-built for deploying and scaling dynamic AI agents and tools. It supports any open-source agent framework, including Strands.
- [AWS Strands SDK](https://strandsagents.com/latest/) is a simple-to-use, code-first framework for building agents.

:::alert{type="info"}
**Browser Recommendation**: Use Chrome, Firefox, or Edge (latest versions). 
:::

## Important Consideration

:::alert{header="Production Safety Guidelines" type="warning"}
**Agentic AI excels at analyzing complex database metrics, parsing through logs, and generating comprehensive recommendations.** The technology has reached a maturity level where it can significantly accelerate troubleshooting and optimization workflows.

**However, we strongly recommend against fully automating remediation steps without careful planning and human oversight, especially in production environments.** The final decision to implement changes should involve human review and approval.
:::




## ✋ Getting Help

:::alert{type="warning"}
**Need Assistance?** Raise your hand and a AWS staff member will assist you. 
:::

## Before going to next module

:::alert{header="Action Required" type="warning"}
Open the following in separate browser tabs:

1. **AWS Console** - Click the option shown in the screenshot below to open AWS Console in a new tab.
2. **VS Code Server** - Find the URL in the **Event outputs** section on the workshop home page. Open it in a new tab and ignore any pop-ups.

You should now have three tabs open:

- Workshop guide (this page)
- AWS Console
- VS Code Server

Once ready, proceed to [**Observability**](/observability/). 
:::

![WSSignin](/static/dat302-images/aws-console.jpg)

