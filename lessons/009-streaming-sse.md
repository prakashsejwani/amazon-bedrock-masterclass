# Lesson 009: Streaming Responses with Server-Sent Events (SSE)

## Objectives

- Understand the lifecycle events emitted by the `ConverseStream` API.
- Compare Bedrock's ConverseStream event structure with OpenAI, Vertex AI, and Azure AI Foundry.
- Implement a Rails 8 live controller using `ActionController::Live` to broadcast ConverseStream events.
- Parse a Server-Sent Events (SSE) token stream in a Next.js 16 frontend and render output dynamically.
- Extract input, output, and total token usage metadata at the termination of the stream.

---

## Theory

While Lesson 007 introduced low-level model-specific runtime streaming, the modern **ConverseStream API** offers a unified streaming interface. Instead of dealing with raw base64 byte blocks or custom provider event objects, Bedrock outputs standard, parsed structural chunks regardless of the underlying foundation model.

### 1. ConverseStream Event Lifecycle

A single call to `ConverseStream` emits a stream of event objects in the following sequential order:

1. **`messageStart`**: Contains the message role (e.g. `assistant`).
2. **`contentBlockStart`**: Indicates a new content block is starting.
3. **`contentBlockDelta`**: The primary event containing text chunks inside `delta.text`.
4. **`contentBlockStop`**: Signals the current content block has ended.
5. **`messageStop`**: Indicates model completion, returning the `stopReason`.
6. **`metadata`**: Emitted at the very end. Contains the critical billing metadata: `usage.inputTokens`, `usage.outputTokens`, and `usage.totalTokens`.

### 2. Multi-Cloud Comparison: Stream Payload Architectures

To build transferable engineering patterns, let's look at how the leading AI platforms stream text completions:

- **Amazon Bedrock (ConverseStream)**:
  - **Structure**: Strongly typed lifecycle events (`messageStart`, `contentBlockDelta`, `metadata`).
  - **Token Billing**: Automatically returned in the final `metadata` event inside the stream.
  - **Payload Style**: Standardized across models (Claude, Llama, Nova).
- **OpenAI (Chat Completions Stream)**:
  - **Structure**: Stream of delta chunks containing `choices[0].delta.content`.
  - **Token Billing**: Requires setting `"stream_options": {"include_usage": true}` in the request to receive a final chunk containing usage metrics.
  - **Payload Style**: Simple but requires custom client state merging.
- **Google Cloud Vertex AI (Gemini API Streaming)**:
  - **Structure**: Stream of candidates containing `candidates[0].content.parts[0].text`.
  - **Token Billing**: Metadata is resolved from the final response object's `usage_metadata` field.
  - **Payload Style**: Part-based representation supporting mixed multimodal parts inline.
- **Azure AI Foundry (Chat Completions)**:
  - **Structure**: Inherits the OpenAI schema for compatibility, returning delta choice elements.
  - **Token Billing**: Captured using gateway custom headers or final choice payload configurations.

---

## Architecture Diagram: ConverseStream Event Flow

```text
+-------------------+             1. Initiate SSE request            +----------------------+
| Next.js Client    | =============================================> | Rails 8 API          |
| (EventSource)     |                                                | ActionController     |
+-------------------+                                                +----------------------+
         ^                                                                      ||
         || 4. Event stream: "data: { token: 'text' }"                          || 2. Calls ConverseStream
         ||    Event stream: "data: { usage: { input: ... } }"                  \/
+-------------------+                                                +----------------------+
| Client UI updates | <============================================= | AWS Bedrock Runtime  |
| (Renders chat)    |           3. Decodes and processes event       | (ConverseStream API) |
+-------------------+              stream delta & metadata blocks    +----------------------+
```

---

## AWS CLI Walkthrough

### Step 1: Querying ConverseStream using the `personal` Profile

You can stream model responses directly to your terminal by executing:

```bash
aws bedrock-runtime converse-stream \
  --model-id "amazon.nova-micro-v1:0" \
  --messages '[{"role":"user","content":[{"text":"Write a 2-line poem."}]}]' \
  --profile personal
```

### Step 2: Analyzing the Event Stream Output

The terminal displays a stream of JSON records. A `contentBlockDelta` chunk appears as:

```json
{
  "contentBlockDelta": {
    "contentBlockIndex": 0,
    "delta": {
      "text": "The stars align in quiet space,\n"
    }
  }
}
```

At the end of the stream, you will observe the metadata event:

```json
{
  "metadata": {
    "usage": {
      "inputTokens": 14,
      "outputTokens": 19,
      "totalTokens": 33
    },
    "metrics": {
      "latencyMs": 280
    }
  }
}
```

---

## Step-by-Step Integrations

### 1. Ruby

Read the event stream sequentially using the standard Ruby SDK and extract both text blocks and token counts:

```ruby
require 'aws-sdk-bedrockruntime'
require 'json'

client = Aws::BedrockRuntime::Client.new(
  region: 'us-east-1',
  credentials: Aws::SharedCredentials.new(profile_name: 'personal')
)

messages = [{ role: 'user', content: [{ text: 'Give me a 3-word motto.' }] }]

client.converse_stream(
  model_id: 'amazon.nova-micro-v1:0',
  messages: messages
) do |stream|
  stream.on_message_start do |event|
    puts "[Start Message - Role: #{event.role}]"
  end

  stream.on_content_block_delta do |event|
    print event.delta.text
    $stdout.flush
  end

  stream.on_metadata do |event|
    puts "\n\n[Metadata Usage]"
    puts "Input Tokens:  #{event.usage.input_tokens}"
    puts "Output Tokens: #{event.usage.output_tokens}"
    puts "Total Tokens:  #{event.usage.total_tokens}"
  end
end
```

### 2. Ruby on Rails 8

Configure an action in your API controller to capture ConverseStream events and stream them back to the client using `ActionController::Live`:

```ruby
# app/controllers/converse_streams_controller.rb
class ConverseStreamsController < ApplicationController
  include ActionController::Live

  def stream
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Last-Modified'] = Time.now.httpdate
    response.headers['X-Accel-Buffering'] = 'no'

    client = Aws::BedrockRuntime::Client.new(
      region: 'us-east-1',
      credentials: Aws::SharedCredentials.new(profile_name: 'personal')
    )

    messages = [{ role: 'user', content: [{ text: params[:prompt] }] }]

    client.converse_stream(
      model_id: 'amazon.nova-micro-v1:0',
      messages: messages
    ) do |stream|
      stream.on_content_block_delta do |event|
        payload = { token: event.delta.text }
        response.stream.write("data: #{payload.to_json}\n\n")
      end

      stream.on_metadata do |event|
        payload = {
          usage: {
            input: event.usage.input_tokens,
            output: event.usage.output_tokens,
            total: event.usage.total_tokens
          }
        }
        response.stream.write("data: #{payload.to_json}\n\n")
      end
    end
  rescue => e
    Rails.logger.error("Streaming error: #{e.message}")
    response.stream.write("data: #{ { error: e.message }.to_json }\n\n")
  ensure
    response.stream.close
  end
end
```

### 3. Next.js 16

Implement a client component that reads the EventSource stream and presents the dynamic text alongside final token billing statistics:

```typescript
// app/components/ConverseStreamChat.tsx
'use client';

import React, { useState } from 'react';

interface Usage {
  input: number;
  output: number;
  total: number;
}

export default function ConverseStreamChat() {
  const [prompt, setPrompt] = useState('');
  const [outputText, setOutputText] = useState('');
  const [usage, setUsage] = useState<Usage | null>(null);
  const [loading, setLoading] = useState(false);

  const handleSend = () => {
    setOutputText('');
    setUsage(null);
    setLoading(true);

    const eventSource = new EventSource(
      `http://localhost:3001/converse_streams/stream?prompt=${encodeURIComponent(prompt)}`
    );

    eventSource.onmessage = (event) => {
      const data = JSON.parse(event.data);
      
      if (data.token) {
        setOutputText(prev => prev + data.token);
      }
      
      if (data.usage) {
        setUsage(data.usage);
        eventSource.close();
        setLoading(false);
      }
      
      if (data.error) {
        console.error("Server stream error:", data.error);
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
    <div className="flex flex-col gap-4 p-6 bg-gray-950 text-white rounded-xl max-w-md mx-auto border border-gray-900">
      <textarea
        value={prompt}
        onChange={(e) => setPrompt(e.target.value)}
        placeholder="Type conversation prompt..."
        className="p-3 bg-gray-900 border border-gray-800 rounded-lg text-sm outline-none focus:border-blue-500"
      />
      <button
        onClick={handleSend} disabled={loading}
        className="py-2 bg-blue-600 rounded font-bold hover:bg-blue-500 text-sm disabled:opacity-50"
      >
        {loading ? 'Streaming...' : 'Start Stream'}
      </button>

      <div className="p-4 bg-gray-900 rounded border border-gray-800 text-sm min-h-[80px] whitespace-pre-wrap">
        {outputText || <span className="text-gray-600">Conversation stream will output here...</span>}
      </div>

      {usage && (
        <div className="p-3 bg-gray-900 border border-blue-900/40 rounded text-xs text-blue-400 flex justify-between">
          <span>Input Tokens: {usage.input}</span>
          <span>Output Tokens: {usage.output}</span>
          <span>Total: {usage.total}</span>
        </div>
      )}
    </div>
  );
}
```

---

## Labs & Exercises

### Lab 9.1: Inspecting the Metadata Block

1. Create a script at `labs/lesson-009/stream_metadata.rb`.
2. Configure the script to target `amazon.nova-micro-v1:0` and load the `personal` profile credentials.
3. Query the ConverseStream endpoint, print every text delta event, and output the final latency metrics and token usage blocks once the stream finishes.

### Exercise

Modify the Rails controller in Step 2 to also write the final usage statistics to the database when the stream is finalized (e.g. creating a billing log entry tracking invocation cost).

---

## Quiz

See [Lesson 009 Quiz](../quizzes/lesson-009-quiz.md).

## Interview Questions

See [Lesson 009 Interview Questions](../interview/lesson-009-interview.md).

## Best Practices & Production Notes

- **Stream Cleanup Hooks**: Ensure your EventSource connection is closed immediately upon receipt of the final metadata payload block on the client side. Leaving connections open can drain browser and server memory resources.
- **SSE Connection Limits**: Browsers limit the number of open EventSource connections to a single domain (typically 6 concurrent connections for HTTP/1.1). Utilize HTTP/2 or ensure chats are closed appropriately when the user navigates away.
- **Handling Interrupted Streams**: If the network connection drops mid-generation, you will not receive the final metadata block. Set up a fallback billing tracking routine to approximate token counts based on text length if the connection fails.
