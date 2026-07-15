# Lesson 017: Observability, Cost Tracking & Logs

## Objectives

- Enable and configure Amazon Bedrock Model Invocation Logging to CloudWatch and S3.
- Compare monitoring, tracing, and logging ecosystems across Bedrock, OpenAI, and Vertex AI.
- Capture latency, input/output token counts, and cost statistics dynamically in Rails 8.
- Provision CloudWatch Log Groups and S3 audit buckets for Bedrock using Terraform.

---

## Theory

Deploying LLMs to production without observability is like flying a plane blindfolded. Unlike deterministic software, LLM completions vary, costs scale with token size, and response times (latencies) depend on queue congestion and prompt complexity. **Observability** provides the tools to monitor token costs, response latencies, error frequencies, and payload compliance in real time.

### 1. Bedrock Model Invocation Logging

Amazon Bedrock can capture raw request/response payloads automatically:

- **Destination Options**: Logs can be routed to **Amazon CloudWatch Logs** (for fast indexing, search, and alarms) or **Amazon S3** (for cost-effective, long-term compliance storage).
- **Security & PII**: Because logs capture prompts and completions, they may contain PII. Encryption keys (AWS KMS) must be configured to secure logs at rest.
- **Log Payload**: Contains the model ID, timestamp, prompt text, completion text, input/output token sizes, and invocation status.

### 2. Core CloudWatch Metrics for Bedrock

Amazon Bedrock automatically publishes metrics to the `AWS/Bedrock` namespace:

- **`Invocations`**: The total count of API requests.
- **`InvocationLatency`**: The time taken (in milliseconds) for the model to compile and return the request.
- **`InputTokenCount` & `OutputTokenCount`**: Metrics measuring exact token usage.

### 3. Multi-Cloud Comparison: Observability Ecosystems

| Monitoring Aspect | Amazon Bedrock (CloudWatch) | OpenAI (Usage API / Dashboards) | Google Vertex AI (Cloud Logging) |
| :--- | :--- | :--- | :--- |
| **System Metrics** | CloudWatch Metrics (`AWS/Bedrock` namespace) | Standard usage dashboard (limited real-time alerts) | Google Cloud Monitoring (Vertex AI metrics) |
| **Payload Logging** | Managed Model Invocation Logging (CloudWatch/S3) | Requires custom gateway proxy or middleware | Cloud Logging (integrated payload logs configuration) |
| **Tracing / Auditing** | AWS CloudTrail integration | Admin audit logs for organization actions | GCP Cloud Audit Logs |
| **Alerting Alarms** | CloudWatch Alarms (alarms on error rates or billing) | Billing budget limit alerts only | GCP Monitoring alerts and budgets |

---

## Architecture Diagram: Observability & Logging Pipeline

```text
       +------------------+                   +--------------------+
       |   User Request   | =================> | Rails Backend App  |
       +------------------+                    +--------------------+
                                                         ||
                                                         || 1. Invoke Model
                                                         \/
+=====================================================================================+
|                                AWS Bedrock Runtime                                  |
|                                                                                     |
|   Step 1: Executes generation.                                                      |
|   Step 2: Returns response payload containing token metrics.                        |
|   Step 3: Background pipeline sends full payload log (if enabled).                  |
|                                                                                     |
+=====================================================================================+
             ||                                                     ||
             || (Auto publish metrics)                              || (Model Invocation Log)
             \/                                                     \/
+-----------------------+                             +-------------------------------+
| Amazon CloudWatch     |                             | Amazon S3 Audit Bucket        |
| (Alarms & Metrics)    |                             | (Compliance & KMS encrypted)  |
+-----------------------+                             +-------------------------------+
```

---

## AWS CLI Walkthrough

### Step 1: Configuring Model Invocation Logging via CLI

Submit a log configuration enabling CloudWatch and S3 delivery. Run this command using your `personal` profile:

```bash
aws bedrock put-model-invocation-logging-configuration \
  --logging-config '{"cloudWatchConfig":{"logGroupName":"/aws/bedrock/model-invocations","roleArn":"arn:aws:iam::087063916319:role/BedrockLoggingRole","largeDataDeliveryS3Config":{"bucketName":"bedrock-large-payload-logs"}},"s3Config":{"bucketName":"bedrock-raw-completions-logs"},"textDataDeliveryEnabled":true}' \
  --profile personal
```

---

## Step-by-Step Integrations

### 1. Ruby

Invoke the Converse API using your `personal` credentials, read the usage metrics returned in the metadata block, and print calculated token costs:

```ruby
require 'aws-sdk-bedrockruntime'

# Unit pricing per 1 million tokens for amazon.nova-micro-v1:0
# Input: $0.035 / 1M tokens, Output: $0.140 / 1M tokens
NOVA_INPUT_PRICE = 0.035 / 1_000_000
NOVA_OUTPUT_PRICE = 0.140 / 1_000_000

client = Aws::BedrockRuntime::Client.new(
  region: 'us-east-1',
  credentials: Aws::SharedCredentials.new(profile_name: 'personal')
)

response = client.converse(
  model_id: 'amazon.nova-micro-v1:0',
  messages: [{ role: 'user', content: [{ text: 'Write a short marketing slogan.' }] }]
)

# Extract token metrics
usage = response.usage
input_tokens = usage.input_tokens
output_tokens = usage.output_tokens
total_tokens = usage.total_tokens

# Compute cost
total_cost = (input_tokens * NOVA_INPUT_PRICE) + (output_tokens * NOVA_OUTPUT_PRICE)

puts "Execution Metrics:"
puts "=" * 40
puts "Input Tokens:  #{input_tokens}"
puts "Output Tokens: #{output_tokens}"
puts "Total Tokens:  #{total_tokens}"
puts "Total Cost:    $#{'%.8f' % total_cost} USD"
```

### 2. Ruby on Rails 8

Implement an ActiveRecord middleware to intercept completions and record metrics in a SQLite audit log:

```ruby
# app/models/llm_invocation_metric.rb
class LlmInvocationMetric < ApplicationRecord
  validates :model_id, :prompt_tokens, :completion_tokens, :latency_ms, presence: true
end

# app/controllers/monitored_chats_controller.rb
class MonitoredChatsController < ApplicationController
  def ask
    client = Aws::BedrockRuntime::Client.new(
      region: 'us-east-1',
      credentials: Aws::SharedCredentials.new(profile_name: 'personal')
    )

    start_time = Time.now

    response = client.converse(
      model_id: 'amazon.nova-micro-v1:0',
      messages: [{ role: 'user', content: [{ text: params[:prompt] }] }]
    )

    end_time = Time.now
    latency = ((end_time - start_time) * 1000).to_i # In milliseconds

    # Record metrics to database
    LlmInvocationMetric.create!(
      model_id: 'amazon.nova-micro-v1:0',
      prompt_tokens: response.usage.input_tokens,
      completion_tokens: response.usage.output_tokens,
      latency_ms: latency
    )

    render json: {
      reply: response.output.message.content[0].text,
      tokens_used: response.usage.total_tokens,
      latency_ms: latency
    }
  end
end
```

### 3. Next.js 16

Dashboard component showing aggregated cost and usage metrics:

```typescript
// app/components/ObservabilityDashboard.tsx
'use client';

import React, { useEffect, useState } from 'react';

interface Stats {
  totalCalls: number;
  totalTokens: number;
  avgLatency: number;
  estimatedCost: number;
}

export default function ObservabilityDashboard() {
  const [stats, setStats] = useState<Stats | null>(null);

  useEffect(() => {
    // Poll Rails metrics endpoint
    fetch('/api/metrics/summary')
      .then(res => res.json())
      .then(data => setStats(data.summary));
  }, []);

  if (!stats) return <div className="text-gray-500 text-xs">Loading statistics...</div>;

  return (
    <div className="flex flex-col gap-4 p-6 bg-gray-950 text-white rounded-xl border border-gray-900 max-w-lg mx-auto">
      <h3 className="text-sm font-bold border-b border-gray-900 pb-2 text-blue-400">Observability Metrics</h3>
      <div className="grid grid-cols-2 gap-4 text-sm">
        <div className="p-3 bg-gray-900 border border-gray-800 rounded">
          <span className="text-xs text-gray-500 block">Total Requests</span>
          <span className="text-lg font-bold">{stats.totalCalls}</span>
        </div>
        <div className="p-3 bg-gray-900 border border-gray-800 rounded">
          <span className="text-xs text-gray-500 block">Total Tokens Consumed</span>
          <span className="text-lg font-bold">{stats.totalTokens}</span>
        </div>
        <div className="p-3 bg-gray-900 border border-gray-800 rounded">
          <span className="text-xs text-gray-500 block">Avg Latency (ms)</span>
          <span className="text-lg font-bold text-yellow-400">{stats.avgLatency} ms</span>
        </div>
        <div className="p-3 bg-gray-900 border border-gray-800 rounded">
          <span className="text-xs text-gray-500 block">Estimated Cost</span>
          <span className="text-lg font-bold text-green-400">${stats.estimatedCost.toFixed(5)}</span>
        </div>
      </div>
    </div>
  );
}
```

### 4. Terraform

Provision CloudWatch Log Group and S3 logging bucket:

```hcl
resource "aws_cloudwatch_log_group" "bedrock_logs" {
  name              = "/aws/bedrock/model-invocations"
  retention_in_days = 90
}

resource "aws_s3_bucket" "bedrock_audit" {
  bucket        = "masterclass-bedrock-audit-logs"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_encryption" {
  bucket = aws_s3_bucket.bedrock_audit.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

---

## Labs & Exercises

### Lab 17.1: Creating a Live Cost Calculator

1. Create a script at `labs/lesson-017/cost_calc.rb`.
2. Configure the script to verify your `personal` AWS credentials profile.
3. Accept user prompts from arguments, send query to Claude 3.5 Sonnet, and calculate exact invocation cost using current market pricing models:
   - Claude 3.5 Sonnet: Input $3.00 / 1M, Output $15.00 / 1M.
4. Output the metrics in a structured terminal dashboard.

### Exercise

Extend the Rails `MonitoredChatsController` to trigger a CloudWatch Alarm alert (or output log trace warning) if request latencies exceed `3000ms` or billing costs for a single prompt exceed `$0.01`.

---

## Quiz

See [Lesson 017 Quiz](../quizzes/lesson-017-quiz.md).

## Interview Questions

See [Lesson 017 Interview Questions](../interview/lesson-017-interview.md).

## Best Practices & Production Notes

- **Log Retentions**: CloudWatch log group retentions default to "Never Expire". Set retentions explicitly (e.g., 30 or 90 days) in production to avoid high storage charges.
- **Bypassing Logs for Large Files**: When passing base64 images or PDFs in prompts, payload sizes grow. Ensure your logging configuration only records text data or routes large payloads to S3 rather than CloudWatch to prevent log threshold bottlenecks.
- **Tracing with AWS X-Ray**: For complex multi-tier agent pipelines, integrate AWS X-Ray tracing headers to map request propagation across API gateways, Rails controllers, Lambda functions, and Bedrock models.
