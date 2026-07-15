# Lesson 015: Agents & Orchestration

## Objectives

- Understand the Reasoning and Acting (ReAct) architectural loop powering autonomous agents.
- Configure Action Groups and Knowledge Bases within Bedrock Agents.
- Compare Agent architectures across Amazon Bedrock, OpenAI Assistants, and Vertex AI Agent Builder.
- Programmatically invoke agents using the `InvokeAgent` API and parse stream traces.
- Deploy secure IAM agent trust boundaries using Terraform.

---

## Theory

Single tool calling (function calling) is reactive: the model requests a function, the application executes it, and the conversation ends. In contrast, **Autonomous Agents** can plan and execute multi-step actions independently. Given a complex goal (e.g. *"Audit user prakash's transactions, refund any duplicate payments, and send them a summary email"*), an agent will automatically determine the sequence of steps, execute actions, read files, evaluate outcomes, and run loops until the task is complete.

### 1. The ReAct (Reasoning + Acting) Framework

Amazon Bedrock Agents utilize the **ReAct** pattern to solve tasks:

- **Thought**: The agent analyzes the user prompt and current state to determine what logical step to take next.
- **Action**: The agent executes an action (e.g. invoking an Action Group tool API or querying a Knowledge Base).
- **Observation**: The agent reads the output of the action (e.g. data returned from a database or search results) and uses it to update its knowledge.
- **Repeat**: The agent continues this loop until it has sufficient information to return a final response.

### 2. Bedrock Agent Core Components

- **Agent Instructions**: High-level system guidelines defining the agent's persona, domain boundaries, and authority limits.
- **Action Groups**: The set of actions the agent can perform. Linked to either **AWS Lambda functions** (for direct execution) or defined as **local API schemas** (using "Return of Control" patterns where client applications execute the logic).
- **Knowledge Bases**: Grounding data repositories the agent can search to resolve facts.
- **Traces**: Comprehensive logs generated during execution, categorized into *Pre-Processing*, *Orchestration* (ReAct steps), and *Post-Processing*.

### 3. Multi-Cloud Comparison: Agent Frameworks

| Aspect / Feature | Amazon Bedrock (Agents) | OpenAI (Assistants API) | Google Vertex AI (Agent Builder) |
| :--- | :--- | :--- | :--- |
| **Execution Engine** | Fully managed ReAct planner | Managed assistant execution thread | Managed Goal/Play-based orchestrators |
| **API Action Schema** | OpenAPI JSON schemas (Action Groups) | JSON schemas (Function tools) | OpenAPI specifications (Tool connectors) |
| **Grounding Sources** | Amazon Bedrock Knowledge Bases | Assistants File Search tool | Vertex AI Search / Data Stores |
| **Reasoning Visibility** | Full trace access (Orchestration steps) | Limited (runs opacity backend) | Step logs and transition state traces |
| **Code Execution** | AWS Lambda sandbox integrations | Hosted code interpreter sandbox | Extensions and Google Cloud Run integrations |

---

## Architecture Diagram: Bedrock Agent Execution Loop

```text
               +--------------------------------------------------------------+
               |                         USER PROMPT                          |
               +--------------------------------------------------------------+
                                              ||
                                              \/
                           +-------------------------------------+
                           |    Aws::BedrockAgentRuntime::Client |
                           +-------------------------------------+
                                              ||
                                              \/
                       +---------------------------------------------+
                       |             Pre-Processing Trace            |
                       +---------------------------------------------+
                                              ||
                                              \/
                 +=========================================================+
                 |            Orchestration Loop (ReAct Loop)              |
                 |                                                         |
                 |   Thought: "I need to get Prakash's user ID."           |
                 |   Action: Call get_user(name: "Prakash")                |
                 |   Observation: User ID is "USR-9981"                    |
                 |                                                         |
                 +=========================================================+
                                              ||
                                              \/
                       +---------------------------------------------+
                       |            Post-Processing Trace            |
                       +---------------------------------------------+
                                              ||
                                              \/
               +--------------------------------------------------------------+
               |                        FINAL ANSWER                          |
               +--------------------------------------------------------------+
```

---

## AWS CLI Walkthrough

### Step 1: Invoking an Agent

Submit a complex request to your agent using your `personal` profile credentials:

```bash
aws bedrock-agent-runtime invoke-agent \
  --agent-id "AGENT99812" \
  --agent-alias-id "ALIAS99812" \
  --session-id "user-session-001" \
  --input-text "Reimburse duplicate transaction records for Prakash." \
  --profile personal \
  output.bin
```

*Note*: Because the response is returned as an event stream, the output is saved as a binary block containing formatted frame chunks.

---

## Step-by-Step Integrations

### 1. Ruby

Invoke the agent and parse the event stream to capture both text chunks and reasoning traces:

```ruby
require 'aws-sdk-bedrockagentruntime'

client = Aws::BedrockAgentRuntime::Client.new(
  region: 'us-east-1',
  credentials: Aws::SharedCredentials.new(profile_name: 'personal')
)

response = client.invoke_agent(
  agent_id: 'AGENT99812',
  agent_alias_id: 'ALIAS99812',
  session_id: 'session-rb-100',
  input_text: 'Verify reimbursement logs for Prakash.'
)

response.completion.each do |event|
  # Process text chunks
  if event.respond_to?(:chunk) && event.chunk
    print event.chunk.bytes
    $stdout.flush
  # Process reasoning traces
  elsif event.respond_to?(:trace) && event.trace
    trace = event.trace.trace
    if trace.orchestration_trace
      rationale = trace.orchestration_trace.rationale
      puts "\n[Thought]: #{rationale.text}" if rationale
    end
  end
end
```

### 2. Ruby on Rails 8

Implement a live-streaming agent chat endpoint in your API controller:

```ruby
# app/controllers/agent_chats_controller.rb
class AgentChatsController < ApplicationController
  include ActionController::Live

  def ask
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['X-Accel-Buffering'] = 'no'

    client = Aws::BedrockAgentRuntime::Client.new(
      region: 'us-east-1',
      credentials: Aws::SharedCredentials.new(profile_name: 'personal')
    )

    client.invoke_agent(
      agent_id: ENV.fetch('BEDROCK_AGENT_ID'),
      agent_alias_id: ENV.fetch('BEDROCK_AGENT_ALIAS_ID'),
      session_id: params[:session_id] || "session-#{SecureRandom.hex(4)}",
      input_text: params[:prompt]
    ) do |stream|
      stream.completion.each do |event|
        if event.respond_to?(:chunk) && event.chunk
          payload = { token: event.chunk.bytes }
          response.stream.write("data: #{payload.to_json}\n\n")
        elsif event.respond_to?(:trace) && event.trace
          # Forward traces to showcase the agent's "thinking" process in the UI
          trace_payload = { trace: format_trace(event.trace.trace) }
          response.stream.write("data: #{trace_payload.to_json}\n\n")
        end
      end
    end
  rescue => e
    response.stream.write("data: #{ { error: e.message }.to_json }\n\n")
  ensure
    response.stream.close
  end

  private

  def format_trace(trace)
    if trace.orchestration_trace&.rationale
      "Thought: #{trace.orchestration_trace.rationale.text}"
    elsif trace.orchestration_trace&.invocation_input
      "Action: Calling Tool API #{trace.orchestration_trace.invocation_input.action_group_invocation_input&.action_group_name}"
    else
      nil
    end
  end
end
```

### 3. Next.js 16

Agent chat dashboard rendering the assistant response alongside live thinking traces:

```typescript
// app/components/AgentChatConsole.tsx
'use client';

import React, { useState } from 'react';

interface TraceLog {
  timestamp: string;
  detail: string;
}

export default function AgentChatConsole() {
  const [prompt, setPrompt] = useState('');
  const [reply, setReply] = useState('');
  const [traces, setTraces] = useState<TraceLog[]>([]);
  const [loading, setLoading] = useState(false);

  const handleSend = () => {
    setReply('');
    setTraces([]);
    setLoading(true);

    const eventSource = new EventSource(
      `/api/agent/ask?prompt=${encodeURIComponent(prompt)}&session_id=user-101`
    );

    eventSource.onmessage = (event) => {
      const data = JSON.parse(event.data);

      if (data.token) {
        setReply(prev => prev + data.token);
      }

      if (data.trace) {
        setTraces(prev => [...prev, { timestamp: new Date().toLocaleTimeString(), detail: data.trace }]);
      }

      if (data.done) {
        eventSource.close();
        setLoading(false);
      }
    };

    eventSource.onerror = () => {
      eventSource.close();
      setLoading(false);
    };
  };

  return (
    <div className="grid grid-cols-2 gap-6 max-w-4xl mx-auto p-6 bg-gray-950 text-white rounded-xl border border-gray-900">
      <div className="flex flex-col gap-4">
        <h3 className="text-md font-bold">Autonomous Agent Console</h3>
        <textarea
          value={prompt}
          onChange={(e) => setPrompt(e.target.value)}
          placeholder="Ask the agent to perform multi-step auditing..."
          className="p-3 bg-gray-900 border border-gray-800 rounded text-sm min-h-[100px]"
        />
        <button onClick={handleSend} disabled={loading} className="py-2 bg-blue-600 rounded text-sm font-bold">
          {loading ? 'Orchestrating...' : 'Submit Task'}
        </button>
        <div className="p-4 bg-gray-900 border border-gray-800 rounded min-h-[120px] text-sm whitespace-pre-wrap">
          {reply || <span className="text-gray-600">Final response...</span>}
        </div>
      </div>

      <div className="flex flex-col gap-2 border-l border-gray-900 pl-6">
        <p className="text-xs text-gray-500 font-bold">Agent Reasoning Trace Logs</p>
        <div className="flex flex-col gap-2 overflow-y-auto max-h-[300px] p-2 bg-gray-900/40 rounded border border-gray-900">
          {traces.length === 0 && <span className="text-xs text-gray-700">No traces received yet.</span>}
          {traces.map((t, idx) => (
            <div key={idx} className="p-2 bg-gray-900 border-l-2 border-blue-500 rounded text-[10px]">
              <span className="text-gray-500 block mb-1">{t.timestamp}</span>
              <p className="text-gray-300">{t.detail}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
```

### 4. Terraform

Provision the IAM Role and Trust Relationship policies required for Bedrock Agents:

```hcl
resource "aws_iam_role" "agent_role" {
  name = "bedrock-agent-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "agent_permissions" {
  name = "bedrock-agent-permissions-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:Retrieve"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "agent_attach" {
  role       = aws_iam_role.agent_role.name
  policy_arn = aws_iam_policy.agent_permissions.arn
}
```

---

## Labs & Exercises

### Lab 15.1: Inspecting the Orchestration Trace

1. Create a script at `labs/lesson-015/agent_trace.rb`.
2. Configure the script to verify your `personal` AWS credentials profile.
3. Call `invoke_agent` with trace logs enabled (`enable_trace: true` or configuration equivalent).
4. Parse the output completion stream, capture the orchestration steps, and print each **Rationale (Thought)** and **Invocation Input (Action)** text block directly to the console.

### Exercise

Extend the Rails `AgentChatsController` to filter and strip out pre-processing and post-processing logs, only broadcasting orchestration traces containing tool invocations to clean up the UI view.

---

## Quiz

1. **What framework does Bedrock use to sequence agent reasoning and execution?**
   - A) Chain of Thought (CoT)
   - B) Reasoning and Acting (ReAct)
   - C) Matryoshka prompt cuts
   - D) JSON Schema Validation

2. **In which trace category can you monitor the agent's tool invocation arguments?**
   - A) Pre-Processing
   - B) Orchestration
   - C) Post-Processing
   - D) Guardrail evaluation

3. **What client namespace is instantiated to invoke Bedrock Agents at runtime?**
   - A) `Aws::Bedrock::Client`
   - B) `Aws::BedrockRuntime::Client`
   - C) `Aws::BedrockAgent::Client`
   - D) `Aws::BedrockAgentRuntime::Client`

### Answer Key

1: B, 2: B, 3: D

---

## Interview Questions

**Q: Explain how Amazon Bedrock Agents memory works and how sessions are maintained across multiple turns.**

*Answer*: Bedrock Agents manage session state and memory automatically at the service layer using a unique `sessionId` string supplied in the runtime request. When the client makes successive calls to `InvokeAgent` using the same `sessionId`, the service reloads the conversation history (including observations and reasoning traces) from its internal state store. This eliminates the need for developers to save message logs in local databases or pass raw historical lists in every request.

---

## Best Practices & Production Notes

- **Pre-Processing Validation**: Agents spend considerable time executing pre-processing loops to evaluate if a user prompt is safe or in-scope. If prompt bounds are locked down, you can bypass pre-processing or post-processing stages to decrease end-to-end response latency.
- **Trace Cleaning**: Traces can be extremely verbose. In production, log raw traces to CloudWatch for debugging but only parse and stream key rationales to end-users to avoid UI clutter.
- **Session Expirations**: Session data is automatically expired by the service after a configurable period of inactivity (typically 30 minutes). Design your client applications to handle session timeout errors gracefully by instantiating a new session ID if a call fails.
