# Lesson 014: Function Calling & Tool Use

## Objectives

- Understand the lifecycle of Function Calling (Tool Use) inside dialogue systems.
- Formulate JSON schemas for tool definitions using the Bedrock Converse API.
- Compare function calling schemas and payloads across Bedrock, OpenAI, and Vertex AI.
- Implement an automated tool execution event loop in Ruby.
- Build a citation and tool-log dashboard in Next.js 16.

---

## Theory

Large Language Models are excellent at processing language, but they cannot execute shell commands, read fresh live database records, or trigger background jobs directly. **Function Calling (Tool Use)** solves this. It lets developers define local functions (tools) that the model can request to execute by outputting structured parameters when a user prompt requires external data.

### 1. The Tool Use Lifecycle

Function calling operates as a multi-turn conversation loop:

```text
+--------+            1. Prompt: "What is the weather in Seattle?"            +-------+
| Client | =================================================================> | Model |
|        |                  (Sends weather tool schema)                       |       |
+--------+                                                                    +-------+
    ^                                                                             ||
    || 3. Executes Weather(location: "Seattle") locally                          || 2. Returns stop_reason:
    ||    and retrieves: "Sunny, 72F"                                             ||    "tool_use" specifying
    ||                                                                            \/    args: {location: "Seattle"}
+--------+                                                                    +-------+
| Client | =================================================================> | Model |
|        |            4. Submits tool_result message block:                   |       |
+--------+               "toolUseId: tool_123, status: success, json: ..."    +-------+
    ^                                                                             ||
    ||                                                                            || 5. Returns final textual
    ||                                                                            ||    response incorporating
    ||                                                                            \/    weather output.
+-------------------------------------------------------------------------------------+
| Final output: "The weather in Seattle is sunny and 72F."                           |
+-------------------------------------------------------------------------------------+
```

### 2. Multi-Cloud Comparison: Tool Calling Schemas

| Aspect / Feature | Amazon Bedrock (Converse) | OpenAI (Chat Completions) | Google Vertex AI (Gemini) |
| :--- | :--- | :--- | :--- |
| **Tool Spec Parameter** | `toolConfig` | `tools` | `tools` |
| **Schema Standard** | JSON Schema (in `inputSchema`) | JSON Schema (in `parameters`) | JSON Schema (in `parameters`) |
| **Model Response** | Content block: `toolUse` | Content block: `tool_calls` | Content block: `functionCall` |
| **Submit Result Role** | `user` with `toolResult` block | `tool` with `tool_call_id` | `user` with `functionResponse` |
| **Status Field** | Explicit: `status: "success/error"` | Not supported (inferred by text) | Not supported |

---

## Architecture Diagram: Tool Use Execution Flow

```text
+-------------------+      1. Request with Tool Specs       +--------------------+
| Rails API Service | ====================================> | AWS Bedrock Runtime|
| (SigV4 personal)  |                                       | (Nova / Claude)    |
+-------------------+                                       +--------------------+
         ^                                                             ||
         ||                                                            || 2. Returns stop_reason:
         || 4. Re-invoke Converse with tool result data                \/    "tool_use" & args
+-------------------+                                       +--------------------+
| Local Execution   | <==================================== | Tool Request Block |
| (get_weather task)|          3. Executes locally          | (Extract args)     |
+-------------------+                                       +--------------------+
```

---

## AWS CLI Walkthrough

### Step 1: Requesting a Tool Call

Configure a weather tool and ask a query requiring weather details. Run this command using your `personal` profile:

```bash
aws bedrock-runtime converse \
  --model-id "amazon.nova-micro-v1:0" \
  --messages '[{"role":"user","content":[{"text":"Is it raining in Tokyo?"}]}]' \
  --tool-config '{"tools":[{"toolSpec":{"name":"get_weather","description":"Checks weather for location","inputSchema":{"json":{"type":"object","properties":{"location":{"type":"string"}},"required":["location"]}}}}]}' \
  --profile personal
```

### Step 2: Evaluating the Tool Use Request

The model responds with a tool use block instead of textual dialogue:

```json
{
  "output": {
    "message": {
      "role": "assistant",
      "content": [
        {
          "toolUse": {
            "toolUseId": "tooluse_tokyo_1",
            "name": "get_weather",
            "input": {
              "location": "Tokyo"
            }
          }
        }
      ]
    }
  },
  "stopReason": "tool_use"
}
```

### Step 3: Submitting the Tool Result

To complete the cycle, you submit the dialogue history *plus* the model's tool use request *plus* your function execution output:

```bash
aws bedrock-runtime converse \
  --model-id "amazon.nova-micro-v1:0" \
  --messages '[{"role":"user","content":[{"text":"Is it raining in Tokyo?"}]},{"role":"assistant","content":[{"toolUse":{"toolUseId":"tooluse_tokyo_1","name":"get_weather","input":{"location":"Tokyo"}}}]},{"role":"user","content":[{"toolResult":{"toolUseId":"tooluse_tokyo_1","content":[{"json":{"weather":"Heavy rain, 18C"}}],"status":"success"}}]}]' \
  --tool-config '{"tools":[{"toolSpec":{"name":"get_weather","description":"Checks weather","inputSchema":{"json":{"type":"object","properties":{"location":{"type":"string"}},"required":["location"]}}}}]}' \
  --profile personal
```

The model reads this history and prints: *"Yes, it is currently raining heavily in Tokyo with a temperature of 18C."*

---

## Step-by-Step Integrations

### 1. Ruby: The Automated Tool Loop

Implement a script that detects tool requests, calls local methods, and returns results to Bedrock:

```ruby
require 'aws-sdk-bedrockruntime'
require 'json'

# Define local tool functions
def get_weather(location)
  if location.downcase.include?('tokyo')
    { weather: 'Heavy rain, 18C' }
  else
    { weather: 'Sunny, 22C' }
  end
end

client = Aws::BedrockRuntime::Client.new(
  region: 'us-east-1',
  credentials: Aws::SharedCredentials.new(profile_name: 'personal')
)

tool_config = {
  tools: [{
    tool_spec: {
      name: 'get_weather',
      description: 'Fetches live weather reports for a city',
      input_schema: {
        json: {
          type: 'object',
          properties: { location: { type: 'string' } },
          required: ['location']
        }
      }
    }
  }]
}

messages = [{ role: 'user', content: [{ text: 'Should I take an umbrella in Tokyo today?' }] }]

# Turn 1: Send query with tools
response = client.converse(
  model_id: 'amazon.nova-micro-v1:0',
  messages: messages,
  tool_config: tool_config
)

assistant_message = response.output.message
messages << { role: 'assistant', content: assistant_message.content }

if response.stop_reason == 'tool_use'
  tool_use = assistant_message.content.find(&:tool_use).tool_use
  puts "Model requested tool: #{tool_use.name} with inputs #{tool_use.input.to_h}"

  # Execute local logic
  result = if tool_use.name == 'get_weather'
             get_weather(tool_use.input['location'])
           else
             { error: 'Unknown tool' }
           end

  # Turn 2: Send tool results back
  messages << {
    role: 'user',
    content: [{
      tool_result: {
        tool_use_id: tool_use.tool_use_id,
        content: [{ json: result }],
        status: 'success'
      }
    }]
  }

  final_response = client.converse(
    model_id: 'amazon.nova-micro-v1:0',
    messages: messages,
    tool_config: tool_config
  )

  puts "\nFinal Answer: #{final_response.output.message.content[0].text}"
end
```

### 2. Ruby on Rails 8

Implement a controller action executing tool callbacks dynamically based on request actions:

```ruby
# app/controllers/agent_tools_controller.rb
class AgentToolsController < ApplicationController
  def query
    client = Aws::BedrockRuntime::Client.new(
      region: 'us-east-1',
      credentials: Aws::SharedCredentials.new(profile_name: 'personal')
    )

    messages = params[:messages] || []

    # Simple tool definition passed to Bedrock
    tool_config = {
      tools: [{
        tool_spec: {
          name: 'get_stock_price',
          description: 'Gets current stock price for symbol',
          input_schema: {
            json: {
              type: 'object',
              properties: { symbol: { type: 'string' } },
              required: ['symbol']
            }
          }
        }
      }]
    }

    response = client.converse(
      model_id: 'amazon.nova-micro-v1:0',
      messages: messages,
      tool_config: tool_config
    )

    render json: {
      message: response.output.message.to_h,
      stop_reason: response.stop_reason
    }
  end
end
```

### 3. Next.js 16

Tool execution logs visualizer showing tool state transitions:

```typescript
// app/components/ToolLogger.tsx
'use client';

import React, { useState } from 'react';

interface LogEntry {
  toolName: string;
  args: any;
  result?: any;
  status: 'pending' | 'success' | 'failed';
}

export default function ToolLogger() {
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [prompt, setPrompt] = useState('');
  const [answer, setAnswer] = useState('');

  const runLoop = async () => {
    setLogs([]);
    setAnswer('');

    let messages = [{ role: 'user', content: [{ text: prompt }] }];
    let keepGoing = true;

    while (keepGoing) {
      const res = await fetch('/api/tools/query', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ messages })
      });
      const data = await res.json();

      messages.push(data.message);

      if (data.stop_reason === 'tool_use') {
        const toolUse = data.message.content.find((c: any) => c.toolUse).toolUse;

        // Log the call
        const newLog: LogEntry = { toolName: toolUse.name, args: toolUse.input, status: 'pending' };
        setLogs(prev => [...prev, newLog]);

        // Execute local mock logic
        let toolResult = { price: 150.0 };

        // Update log with success
        setLogs(prev => prev.map(l => l.toolName === toolUse.name ? { ...l, result: toolResult, status: 'success' } : l));

        messages.push({
          role: 'user',
          content: [{
            toolResult: {
              toolUseId: toolUse.toolUseId,
              content: [{ json: toolResult }],
              status: 'success'
            }
          }]
        });
      } else {
        setAnswer(data.message.content[0].text);
        keepGoing = false;
      }
    }
  };

  return (
    <div className="flex flex-col gap-4 p-6 bg-gray-950 text-white rounded-xl border border-gray-900 max-w-md mx-auto">
      <input
        value={prompt}
        onChange={(e) => setPrompt(e.target.value)}
        placeholder="e.g. Check stock price for AAPL"
        className="p-2 bg-gray-900 border border-gray-800 rounded text-sm outline-none"
      />
      <button onClick={runLoop} className="py-2 bg-blue-600 rounded text-sm font-bold">
        Run Agent Loop
      </button>

      {logs.length > 0 && (
        <div className="flex flex-col gap-2">
          <p className="text-xs text-gray-500 font-bold">Execution Logs:</p>
          {logs.map((l, idx) => (
            <div key={idx} className="p-3 bg-gray-900 border border-gray-800 rounded text-xs">
              <span className="text-blue-400 font-bold">Tool called: {l.toolName}</span>
              <pre className="text-gray-400 mt-1">Args: {JSON.stringify(l.args)}</pre>
              {l.result && <pre className="text-green-400 mt-1">Result: {JSON.stringify(l.result)}</pre>}
            </div>
          ))}
        </div>
      )}

      {answer && (
        <p className="p-3 bg-gray-900 border border-gray-800 rounded text-sm">{answer}</p>
      )}
    </div>
  );
}
```

---

## Labs & Exercises

### Lab 14.1: Building a Dynamic Calculator Tool

1. Create a script at `labs/lesson-014/tool_calc.rb`.
2. Configure the script to verify your `personal` AWS credentials profile.
3. Define a tool structure `calculate_sum` accepting `a: number` and `b: number`.
4. Run a query: `"What is 4235 + 8761?"`
5. Implement the execution block, return the calculated sum to Bedrock, and print the final grounded output text response.

### Exercise

Add a second tool `multiply_values` accepting `x: number` and `y: number` to the script. Execute a prompt that requires calling both tools sequentially (e.g. `"Add 15 and 20, then multiply the result by 3"`) and inspect the multi-step trace.

---

## Quiz

See [Lesson 014 Quiz](../quizzes/lesson-014-quiz.md).

## Interview Questions

See [Lesson 014 Interview Questions](../interview/lesson-014-interview.md).

## Best Practices & Production Notes

- **Handling Tool Errors**: If a local tool execution fails (e.g., database timeout), submit a `toolResult` with `status: "error"` and the error message in the JSON block. This allows the model to attempt a recovery or gracefully report the failure to the user.
- **Minimizing Latency**: Each function call requires a full HTTP round-trip (Client -> Bedrock -> Client -> Tool -> Client -> Bedrock -> Client). Keep tool structures simple and run tool executions in parallel if the model requests multiple tool calls in a single turn.
- **Schema Simplification**: Keep tool descriptions concise. Long schemas consume context tokens and increase latency.
