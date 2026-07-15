# Lesson 018: Production Architecture & Scaling

## Objectives

- Plan and architect high-availability, production-grade enterprise generative AI systems.
- Use Amazon Bedrock Cross-Region Inference profiles to distribute request volume.
- Implement robust rate-limiting recovery wrappers with exponential backoff and jitter.
- Compare enterprise scaling configurations across Bedrock, OpenAI, and Vertex AI.

---

## Theory

Transitioning an AI project from proof-of-concept to production exposes it to real-world operational challenges: throttling exceptions, service outages, and rising hosting costs. Building a robust production architecture requires designing for high throughput, redundancy, and automated failover recovery.

### 1. Scaling Inferences & Handling Rate Limits

In cloud environments, APIs enforce rate limits to protect resource capacities. When these limits are reached, the API returns an HTTP 429 status code. In Amazon Bedrock, this throws a `ThrottlingException`.

To manage rate limits in production, developers implement two primary patterns:

- **Exponential Backoff**: Successively increasing the delay between retry attempts (e.g. 1s, 2s, 4s, 8s) to allow downstream services time to recover.
- **Jitter**: Injecting a random variance into the retry delay (e.g. retrying at 4.2s instead of exactly 4.0s) to prevent a "thundering herd" problem where multiple client instances hit the server simultaneously.

### 2. AWS Cross-Region Inference Profiles

To prevent throttling without reserving dedicated capacity, Amazon Bedrock provides **Cross-Region Inference**. Instead of routing all calls to a single AWS region, Bedrock dynamically load-balances request traffic across multiple regional endpoints within a geographic zone (such as `us` or `eu`).

To use cross-region inference, you simply query Bedrock using a **system-defined inference profile ID** instead of the raw model ID:

- **Raw Model ID**: `amazon.nova-micro-v1:0` (US-East-1 only)
- **Geographic Inference Profile ID**: `us.amazon.nova-micro-v1:0` (Auto-routes traffic between Virginia, Ohio, and Oregon)

This increases throughput quotas and improves end-to-end reliability automatically.

### 3. Provisioned Throughput

For applications requiring guaranteed throughput and zero latency variance, Bedrock offers **Provisioned Throughput**. Developers reserve dedicated capacity measured in **Model Units (MUs)** (1 MU represents a fixed number of input/output tokens per minute). Provisioned throughput guarantees constant availability, completely bypassing default rate-limiting quotas.

### 4. Multi-Cloud Comparison: Scaling Landscapes

| Scaling Feature | Amazon Bedrock | OpenAI | Google Vertex AI |
| :--- | :--- | :--- | :--- |
| **Failover Routing** | Managed natively via Geographic/Global Inference Profiles | Requires custom client-side load-balancers/gateways | Auto-routed across multi-zone regional replica pools |
| **Reserved Throughput** | Provisioned Throughput (reserving Model Units) | Requires enterprise volume commitment tiers | Provisioned throughput on custom hosted endpoints |
| **Fine-Tuning Hosting** | Custom Model endpoints (billed hourly or via provisioned MUs) | Hosted by OpenAI automatically (billed per token) | Deployable to auto-scaling endpoints (billed per node hour) |
| **Outage Redundancy** | Cross-region IAM fallback routing | Multi-organization API key fallbacks | Cross-project routing and regional backup pools |

---

## Architecture Diagram: High-Availability Failover Gateway

```text
               +--------------------------------------------------------------+
               |                        Client Request                        |
               +--------------------------------------------------------------+
                                              ||
                                              \/
                           +-------------------------------------+
                           |      HA Model Router Middleware      |
                           +-------------------------------------+
                                              ||
                    ======================================================
                    || (Primary Route)                                  || (Fallback Route)
                    || us.amazon.nova-micro-v1:0                        || us.amazon.nova-lite-v1:0
                    \/                                                  \/
         +======================+                             +======================+
         | AWS Bedrock Runtime  |                             | AWS Bedrock Runtime  |
         | (Virginia / Oregon)  |                             | (Ohio / Virginia)    |
         +======================+                             +======================+
                    ||                                                  ||
                    || (ThrottlingException / Outage)                   || (Active backup)
                    \/                                                  \/
         +----------------------+                             +----------------------+
         | Intercept & Retry    | ==========================> | Execute Backup Route |
         | (Backoff + Jitter)   |                             |                      |
         +----------------------+                             +----------------------+
```

---

## AWS CLI Walkthrough

### Step 1: Querying a Cross-Region Inference Profile

Submit a query targeting the `us` geographic profile ID instead of a single region model endpoint. Run this command using your `personal` profile:

```bash
aws bedrock-runtime converse \
  --model-id "us.amazon.nova-micro-v1:0" \
  --messages '[{"role":"user","content":[{"text":"Compile a production deployment checklist."}]}]' \
  --profile personal
```

By adding the `us.` prefix, Bedrock automatically scales the execution across multiple US regions.

---

## Step-by-Step Integrations

### 1. Ruby

Implement a client wrapper that catches rate limits (`ThrottlingException`) and automatically retries using exponential backoff and randomized jitter:

```ruby
require 'aws-sdk-bedrockruntime'

def converse_with_retry(client, model_id, messages, max_retries = 3)
  retries = 0

  begin
    client.converse(
      model_id: model_id,
      messages: messages
    )
  rescue Aws::BedrockRuntime::Errors::ThrottlingException => e
    if retries < max_retries
      retries += 1
      # Calculate delay with exponential backoff and jitter
      delay = (2**retries) + rand(0.0..1.0)
      puts "Throttled! Retrying in #{delay.round(2)} seconds (Attempt #{retries}/#{max_retries})..."
      sleep(delay)
      retry
    else
      raise e
    end
  end
end

client = Aws::BedrockRuntime::Client.new(
  region: 'us-east-1',
  credentials: Aws::SharedCredentials.new(profile_name: 'personal')
)

messages = [{ role: 'user', content: [{ text: 'Give me a 5-step reliability rule.' }] }]

response = converse_with_retry(client, 'us.amazon.nova-micro-v1:0', messages)
puts "Response: #{response.output.message.content[0].text}"
```

### 2. Ruby on Rails 8

Implement a high-availability Model Router service that falls back to a secondary model if the primary endpoint experiences service errors or throttling:

```ruby
# app/services/ha_model_router_service.rb
class HaModelRouterService
  PRIMARY_MODEL = 'us.amazon.nova-micro-v1:0'
  FALLBACK_MODEL = 'us.amazon.nova-lite-v1:0'

  def self.converse(messages)
    client = Aws::BedrockRuntime::Client.new(
      region: 'us-east-1',
      credentials: Aws::SharedCredentials.new(profile_name: 'personal')
    )

    begin
      # Try primary route
      Rails.logger.info("Routing request to primary model: #{PRIMARY_MODEL}")
      client.converse(model_id: PRIMARY_MODEL, messages: messages)
    rescue Aws::BedrockRuntime::Errors::ThrottlingException,
           Aws::BedrockRuntime::Errors::ServiceError => e
      # Failover to backup model
      Rails.logger.warn("Primary model failed: #{e.message}. Routing to fallback: #{FALLBACK_MODEL}")
      client.converse(model_id: FALLBACK_MODEL, messages: messages)
    end
  end
end
```

### 3. Next.js 16

Model Status Dashboard indicating routing and failover states:

```typescript
// app/components/ModelStatusTracker.tsx
'use client';

import React, { useState } from 'react';

interface RouteLog {
  model: string;
  status: 'SUCCESS' | 'FAILOVER' | 'RETRYING';
  timestamp: string;
}

export default function ModelStatusTracker() {
  const [prompt, setPrompt] = useState('');
  const [reply, setReply] = useState('');
  const [logs, setLogs] = useState<RouteLog[]>([]);
  const [loading, setLoading] = useState(false);

  const executeRequest = async () => {
    setLoading(true);
    setReply('');

    const initialLog: RouteLog = { model: 'us.amazon.nova-micro-v1:0', status: 'SUCCESS', timestamp: new Date().toLocaleTimeString() };

    try {
      const res = await fetch('/api/ha-chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ prompt })
      });
      const data = await res.json();

      setReply(data.reply);
      if (data.fallbackUsed) {
        setLogs(prev => [...prev, { model: 'us.amazon.nova-lite-v1:0', status: 'FAILOVER', timestamp: new Date().toLocaleTimeString() }]);
      } else {
        setLogs(prev => [...prev, initialLog]);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="grid grid-cols-2 gap-6 max-w-3xl mx-auto p-6 bg-gray-950 text-white rounded-xl border border-gray-900">
      <div className="flex flex-col gap-4">
        <h3 className="text-md font-bold">HA Failover Router Console</h3>
        <textarea
          value={prompt}
          onChange={(e) => setPrompt(e.target.value)}
          placeholder="Enter prompt..."
          className="p-3 bg-gray-900 border border-gray-800 rounded text-sm"
        />
        <button onClick={executeRequest} disabled={loading} className="py-2 bg-blue-600 rounded text-sm font-bold">
          {loading ? 'Routing...' : 'Run Query'}
        </button>
        <p className="p-3 bg-gray-900 border border-gray-800 rounded text-xs min-h-[60px]">{reply || 'Output...'}</p>
      </div>

      <div className="flex flex-col gap-2 pl-6 border-l border-gray-900">
        <p className="text-xs text-gray-500 font-bold">Routing Failover Logs</p>
        <div className="flex flex-col gap-2 overflow-y-auto max-h-[220px]">
          {logs.map((l, idx) => (
            <div key={idx} className={`p-2 rounded text-[10px] border ${l.status === 'FAILOVER' ? 'bg-yellow-950/40 border-yellow-900 text-yellow-400' : 'bg-green-950/40 border-green-900 text-green-400'}`}>
              <span className="block font-bold">{l.model}</span>
              <span>Status: {l.status} ({l.timestamp})</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
```

### 4. Terraform

Provision a Provisioned Throughput commitment model alias:

```hcl
resource "aws_bedrock_provisioned_model_throughput" "nova_reserved" {
  model_id              = "arn:aws:bedrock:us-east-1::foundation-model/amazon.nova-micro-v1:0"
  model_units           = 1 # Reserve 1 Model Unit
  provisioned_model_name = "reserved-nova-micro-production"

  # Commit to hourly / no-commitment tier depending on quotas
  commitment_duration = "None"
}
```

---

## Labs & Exercises

### Lab 18.1: Creating a Failover Benchmark script

1. Create a script at `labs/lesson-018/failover_router.rb`.
2. Configure the script to verify your `personal` AWS credentials profile.
3. Simulate a rate-limiting failure by querying a non-existent or blocked model ID.
4. Catch the error in the retry block and immediately route the query to a fallback backup model (`us.amazon.nova-micro-v1:0`).
5. Output details of the failed attempt and the successful fallback route to the console.

### Exercise

Extend the Rails `HaModelRouterService` to track successive model errors in redis cache, automatically marking a model endpoint as "offline" (Circuit Breaker pattern) if it fails 5 times in a row, bypassing it entirely for subsequent calls.

---

## Quiz

See [Lesson 018 Quiz](../quizzes/lesson-018-quiz.md).

## Interview Questions

See [Lesson 018 Interview Questions](../interview/lesson-018-interview.md).

## Best Practices & Production Notes

- **Inference Profile ARNs**: Always reference Cross-Region Inference profiles using their system ARNs or geographic prefixes (like `us.`) to distribute workloads automatically.
- **Client-Side Timeout Tuning**: LLM responses can take time. Configure read timeout values in the AWS SDK client (e.g., setting `http_read_timeout` to 60 or 90 seconds) to prevent premature client disconnects during long completion loops.
- **Circuit Breaker Limits**: Keep circuit breaker rules conservative. LLM services recovery quickly from brief bursts of throttling. Set the breaker threshold to trip only on repeated HTTP 429 or 503 errors over a 10–30 second window.
