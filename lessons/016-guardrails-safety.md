# Lesson 016: AI Guardrails & Safety

## Objectives

- Understand the architecture of independent AI safety boundaries.
- Configure Amazon Bedrock Guardrails to filter toxic content, PII leaks, and prompt injections.
- Compare safety policy implementations between Bedrock, Azure AI Content Safety, and Vertex AI.
- Query models with Guardrail configurations and handle `guardrail_intervened` stop reasons.
- Provision Bedrock Guardrail configurations using Terraform.

---

## Theory

If you try to secure a generative AI system solely by modifying system prompts, you will eventually fail. System prompts are mutable context; prompt injection attacks can bypass them. **AI Guardrails** represent an independent security layer that sits outside the LLM context window. Guardrails intercept both the incoming user prompt and the outgoing model response, evaluating their safety before they ever reach the target destination.

### 1. Bedrock Guardrail Protection Filters

Amazon Bedrock Guardrails provides five categories of safety configurations:

- **Content Filters**: Evaluates text against four standard categories: *Hate Speech*, *Insults*, *Sexual Content*, and *Violence*. You set filtering thresholds (Low, Medium, High) for both inputs and outputs.
- **Denied Topics**: Defines natural-language rules of what the model is blocked from discussing (e.g. *"Financial Investment Advice"*). If a query matches the topic description, it is blocked.
- **Word Filters**: Custom lists of specific words or phrases that are immediately blocked (e.g. competitor brand names, slurs, or confidential project names).
- **PII Filters**: Automatically detects and masks/blocks Personally Identifiable Information (such as Social Security Numbers, emails, credit cards, or names) using built-in classifiers or custom regex.
- **Contextual Grounding Check**: Evaluates model output text against the original source documents (used in RAG) to detect and block hallucinations or ungrounded responses.

### 2. Multi-Cloud Comparison: AI Safety Engines

| Safety Feature | Amazon Bedrock (Guardrails) | Azure AI Content Safety | Google Vertex AI (Safety Filters) |
| :--- | :--- | :--- | :--- |
| **Policy Scope** | Independent resource (applies across different models) | Independent service called via API or gateway | Bound directly to individual model configurations |
| **Denied Topics** | Supported natively (natural-language description rules) | Requires custom text classification models | Requires prompt-level context instructions |
| **PII Redactions** | Built-in masking and blocking actions | Supported via Azure Presidio integrations | Supported via Cloud Data Loss Prevention (DLP) |
| **Grounding Checks** | Supported natively in S3/Knowledge Base flows | Requires Azure AI Search custom hooks | Supported via Grounding with Google Search |

---

## Architecture Diagram: Guardrail Execution Flow

```text
       +------------------+                   +--------------------+
       |   User Query     |                   | Rails Backend App  |
       +------------------+                   +--------------------+
               ||                                       ||
               || 1. Submit Query                       || 2. Pass query with
               \/                                       \/    guardrailConfig parameters
+=====================================================================================+
|                            AWS Bedrock Guardrail Gateway                            |
|                                                                                     |
|   Step 1: Input scan (Checks for PII, Toxicity, Denied Topics)                      |
|           ==> IF BLOCKED: Returns stopReason: "guardrail_intervened" immediately.   |
|                                                                                     |
|   Step 2: Model processing (LLM generates tokens)                                   |
|                                                                                     |
|   Step 3: Output scan (Checks LLM response for PII, Toxicity, Hallucinations)       |
|           ==> IF BLOCKED: Overwrites output with standard blocked message.          |
|                                                                                     |
+=====================================================================================+
                                       ||
                                       \/
                       +-------------------------------+
                       | Final response sent to Client |
                       +-------------------------------+
```

---

## AWS CLI Walkthrough

### Step 1: Querying a Model with a Guardrail policy

Submit a query passing your `guardrailIdentifier` and `guardrailVersion` configurations. Run this command using your `personal` profile:

```bash
aws bedrock-runtime converse \
  --model-id "amazon.nova-micro-v1:0" \
  --messages '[{"role":"user","content":[{"text":"Give me stock buying advice for AAPL."}]}]' \
  --guardrail-config '{"guardrailIdentifier":"gr_investments_1","guardrailVersion":"1"}' \
  --profile personal
```

### Step 2: Evaluating a Blocked Response

If the prompt violates the denied topic rule (financial advice), the API returns:

```json
{
  "output": {
    "message": {
      "role": "assistant",
      "content": [
        {
          "text": "I am sorry, but I cannot provide financial or investment advice."
        }
      ]
    }
  },
  "stopReason": "guardrail_intervened",
  "trace": {
    "guardrail": {
      "inputAssessments": [
        {
          "topicPolicy": {
            "topics": [
              {
                "name": "financial_advice",
                "action": "BLOCKED",
                "type": "DENIED"
              }
            ]
          }
        }
      ]
    }
  }
}
```

---

## Step-by-Step Integrations

### 1. Ruby

Invoke the model with guardrails using the `personal` credentials profile, detect blocks, and parse the trace assessments:

```ruby
require 'aws-sdk-bedrockruntime'
require 'json'

client = Aws::BedrockRuntime::Client.new(
  region: 'us-east-1',
  credentials: Aws::SharedCredentials.new(profile_name: 'personal')
)

messages = [{ role: 'user', content: [{ text: 'Give me investment advice.' }] }]

response = client.converse(
  model_id: 'amazon.nova-micro-v1:0',
  messages: messages,
  guardrail_config: {
    guardrail_identifier: 'gr_investments_1',
    guardrail_version: '1'
  }
)

if response.stop_reason == 'guardrail_intervened'
  puts "[ALERT] Safety Guardrail Intervened!"
  puts "Model Output: #{response.output.message.content[0].text}"

  # Parse traces to inspect which filter blocked the request
  trace = response.trace&.guardrail
  if trace
    trace.input_assessments.each do |asm|
      if asm.topic_policy
        asm.topic_policy.topics.each do |t|
          puts "Violated Topic: #{t.name} (Action: #{t.action})"
        end
      end
    end
  end
else
  puts "Model Output: #{response.output.message.content[0].text}"
end
```

### 2. Ruby on Rails 8

Implement a controller action to intercept and log guardrail violations to the security database:

```ruby
# app/controllers/secure_chats_controller.rb
class SecureChatsController < ApplicationController
  def ask
    client = Aws::BedrockRuntime::Client.new(
      region: 'us-east-1',
      credentials: Aws::SharedCredentials.new(profile_name: 'personal')
    )

    response = client.converse(
      model_id: 'amazon.nova-micro-v1:0',
      messages: [{ role: 'user', content: [{ text: params[:prompt] }] }],
      guardrail_config: {
        guardrail_identifier: ENV.fetch('BEDROCK_GUARDRAIL_ID'),
        guardrail_version: '1'
      }
    )

    if response.stop_reason == 'guardrail_intervened'
      # Log security violation for compliance auditing
      SecurityAuditLog.create!(
        user_prompt: params[:prompt],
        action_taken: 'BLOCKED',
        violations_trace: response.trace.guardrail.to_h.to_json
      )
    end

    render json: {
      reply: response.output.message.content[0].text,
      blocked: response.stop_reason == 'guardrail_intervened'
    }
  end
end
```

### 3. Next.js 16

Chat UI that flashes a warning notification block when a request is blocked by the guardrail:

```typescript
// app/components/SecureChatPanel.tsx
'use client';

import React, { useState } from 'react';

export default function SecureChatPanel() {
  const [prompt, setPrompt] = useState('');
  const [reply, setReply] = useState('');
  const [isBlocked, setIsBlocked] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleQuery = async () => {
    setLoading(true);
    setIsBlocked(false);
    setReply('');

    try {
      const res = await fetch('/api/secure-chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ prompt })
      });
      const data = await res.json();

      setReply(data.reply);
      if (data.blocked) {
        setIsBlocked(true);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col gap-4 p-6 bg-gray-950 text-white rounded-xl border border-gray-900 max-w-md mx-auto">
      <input
        value={prompt}
        onChange={(e) => setPrompt(e.target.value)}
        placeholder="Enter conversation text..."
        className="p-2 bg-gray-900 border border-gray-800 rounded text-sm outline-none"
      />
      <button onClick={handleQuery} disabled={loading} className="py-2 bg-blue-600 rounded text-sm font-bold">
        {loading ? 'Evaluating...' : 'Send Message'}
      </button>

      {isBlocked && (
        <div className="p-3 bg-red-950/60 border border-red-900/60 rounded text-xs text-red-400">
          ⚠️ Warning: Your message violated safety rules and was blocked.
        </div>
      )}

      {reply && (
        <p className="p-3 bg-gray-900 border border-gray-800 rounded text-sm">{reply}</p>
      )}
    </div>
  );
}
```

### 4. Terraform

Provision a Bedrock Guardrail policy defining denied topics and content filter limits:

```hcl
resource "aws_bedrock_guardrail" "company_safety" {
  name                      = "company-safety-guardrail"
  description               = "Filters toxic topics, PII, and financial advice"
  blocked_input_messaging   = "I am sorry, but your query violated safety policies."
  blocked_outputs_messaging = "I am sorry, but I cannot return that generated content."

  # Content filter rules
  content_filter_config {
    filters {
      type    = "HATE"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
    filters {
      type    = "VIOLENCE"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
  }

  # Denied topics rules
  topic_policy_config {
    topics {
      name        = "financial_advice"
      definition  = "Investment planning, stocks buy recommendations, or market asset projections."
      type        = "DENIED"
      examples    = ["Which stock should I buy?", "Is Apple a buy right now?"]
    }
  }

  # PII redaction rules
  pii_policy_config {
    pii_entities {
      type   = "EMAIL"
      action = "ANONYMIZE"
    }
    pii_entities {
      type   = "CREDIT_CARD"
      action = "BLOCK"
    }
  }
}
```

---

## Labs & Exercises

### Lab 16.1: Parsing the Guardrail Trace Details

1. Create a script at `labs/lesson-016/guardrail_trace.rb`.
2. Configure the script to verify your `personal` AWS credentials profile.
3. Call `converse` passing a query that violates your guardrail policy (e.g. asking for credit card numbers or toxic text).
4. Detect the `guardrail_intervened` stop reason.
5. Loop through the `input_assessments` and `output_assessments` and print exactly which filter (Topic, Content, Word, PII) triggered the intervention.

### Exercise

Extend the Rails `SecureChatsController` to send a notification (e.g., Slack Webhook or email log alert) if a user prompt triggers the `HATE` or `VIOLENCE` content filter policy more than three times consecutively.

---

## Quiz

1. **Why is it preferred to use a Guardrail over system prompts to block forbidden topics?**
   - A) Guardrails cost less than system prompts
   - B) Guardrails run independently of model context, preventing prompt injection bypasses
   - C) Guardrails allow larger output tokens
   - D) Guardrails increase generation temperature

2. **Which stop reason is returned by the Bedrock API when a query is blocked by a guardrail policy?**
   - A) `safety_block`
   - B) `content_filter`
   - C) `guardrail_intervened`
   - D) `pii_redacted`

3. **What PII action anonymizes text inputs (e.g., replacing emails with `[EMAIL]`) instead of terminating the request?**
   - A) `BLOCK`
   - B) `ANONYMIZE`
   - C) `MASK_MD5`
   - D) `REPLACE_EMPTY`

### Answer Key

1: B, 2: C, 3: B

---

## Interview Questions

**Q: Explain the difference between PII 'BLOCK' and PII 'ANONYMIZE' actions inside a Bedrock Guardrail policy, and when you use each.**

*Answer*:

- **PII BLOCK**: Immediately halts request execution. If PII (such as a credit card number) is detected, the API stops generation and returns a `stop_reason: "guardrail_intervened"`, serving the configured blocked message. Use this for high-risk data compliance constraints (e.g., stopping users from inputting raw credit card numbers or passwords).
- **PII ANONYMIZE**: Replaces the PII value in the prompt text with a generic classification label (e.g., replacing `"john@gmail.com"` with `"[EMAIL]"`) and forwards the sanitized prompt to the LLM. Use this when you still want the model to process the request (e.g., writing a summary of an email) without exposing the raw private data values.

---

## Best Practices & Production Notes

- **Version Lockings**: Guardrails require publishing explicit versions (e.g., `"1"`). Never use the `"DRAFT"` version in production environments because subsequent edits to draft rules will alter model behaviors immediately.
- **Input vs. Output Auditing**: Output filtering is computationally more expensive because it must scan generated text before returning it. Set output strengths higher than input strengths only for highly regulated applications.
- **Latency Impacts**: A guardrail adds minor latency (typically 20–50ms) to model requests as it passes text through built-in classification models. This is a worthwhile trade-off for enterprise security compliance.
