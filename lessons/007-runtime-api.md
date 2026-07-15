# Lesson 007: Bedrock Runtime API (`InvokeModel` & Streaming)

## Objectives

- Invoke Bedrock models synchronously using the `InvokeModel` API.
- Process real-time token streams using the `InvokeModelWithResponseStream` API.
- Manage differing input/output payload formats across model providers (Claude vs. Llama vs. Nova).
- Implement Server-Sent Events (SSE) streaming in Rails 8 and parse the stream in a Next.js 16 frontend.

---

## Theory

The control plane (Amazon Bedrock) is used for managing models, access, and custom jobs. The data plane (**Amazon Bedrock Runtime**) is the high-performance endpoint used to query models.

There are two primary modes of model execution:

### 1. Synchronous Invocation (`InvokeModel`)

The client sends the prompt payload and holds the HTTP connection open until the model generates the entire response.

- **Pros**: Simple to implement, easy to retry on failure.
- **Cons**: High time-to-first-token (TTFT) latency, which hurts user experience for long generations.

### 2. Streaming Invocation (`InvokeModelWithResponseStream`)

The client opens a connection and receives chunks of data as the model generates them, using standard HTTP chunked transfer encoding.

- **Pros**: Low TTFT latency, interactive and fast user experience.
- **Cons**: Requires custom event stream parsing on the client, harder to track cost statistics (tokens count) before the stream finishes.

---

## Model Payload Variations

Different model providers require different request body schemas:

- **Anthropic Claude 3 / 3.5**: Uses the Messages API structure:

  ```json
  {
    "anthropic_version": "bedrock-2023-05-31",
    "max_tokens": 1000,
    "messages": [
      { "role": "user", "content": "Hello" }
    ]
  }
  ```

- **Meta Llama 3 / 3.1 / 3.3**: Uses the standard Instruct format:

  ```json
  {
    "prompt": "user\n\nHelloassistant\n\n",
    "max_gen_len": 512,
    "temperature": 0.5
  }
  ```

- **Amazon Nova (Micro/Lite/Pro)**: Uses the messages schema:

  ```json
  {
    "messages": [
      { "role": "user", "content": [{ "text": "Hello" }] }
    ],
    "inferenceConfig": { "maxNewTokens": 1000 }
  }
  ```

---

## Architecture Diagram: Streaming Response Lifecycle

```text
+--------+       1. HTTP Request (Stream)       +--------------------+
| Client | ===================================> | Rails 8 Backend    |
+--------+                                      | ActionController   |
   ^                                            +--------------------+
   |                                                      ||
   | 4. SSE (Server-Sent Events) Stream                   || 2. InvokeModelWithResponseStream
   |    "data: { token: 'hello' }"                         \/
+------------------------------------+          +--------------------+
| Next.js Frontend UI (Dynamic React)| <======= | AWS Bedrock Runtime|
+------------------------------------+  3. Chunk| (Event Stream)     |
                                                +--------------------+
```

---

## Step-by-Step Integrations

### 1. AWS CLI

Invoke Nova Micro synchronously:

```bash
aws bedrock-runtime invoke-model \
  --model-id "amazon.nova-micro-v1:0" \
  --body '{"messages":[{"role":"user","content":[{"text":"Explain gravity."}]}],"inferenceConfig":{"maxNewTokens":100}}' \
  --region us-east-1 \
  output.txt
```

### 2. Ruby

Query Claude 3.5 Sonnet and parse the synchronous JSON response:

```ruby
require 'aws-sdk-bedrockruntime'
require 'json'

client = Aws::BedrockRuntime::Client.new(region: 'us-east-1')

body = {
  anthropic_version: 'bedrock-2023-05-31',
  max_tokens: 500,
  messages: [
    { role: 'user', content: 'Generate a 3-word slogan for a coffee shop.' }
  ]
}

response = client.invoke_model(
  model_id: 'anthropic.claude-3-5-sonnet-20241022-v2:0',
  body: body.to_json,
  content_type: 'application/json'
)

result = JSON.parse(response.body.read)
puts "Response: #{result['content'][0]['text']}"
```

### 3. Ruby on Rails 8

Implement Server-Sent Events (SSE) streaming using `ActionController::Live` to broadcast tokens back to a web browser:

```ruby
# app/controllers/chats_controller.rb
class ChatsController < ApplicationController
  include ActionController::Live

  def stream
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Last-Modified'] = Time.now.httpdate
    response.headers['X-Accel-Buffering'] = 'no' # Disable proxy buffering for Nginx

    client = Aws::BedrockRuntime::Client.new(region: 'us-east-1')
    
    body = {
      messages: [{ role: 'user', content: [{ text: params[:prompt] }] }],
      inferenceConfig: { maxNewTokens: 500 }
    }

    client.invoke_model_with_response_stream(
      model_id: 'amazon.nova-micro-v1:0',
      body: body.to_json,
      content_type: 'application/json'
    ) do |stream|
      stream.on_chunk_received do |chunk|
        # Decode base64/bytes block from Bedrock event stream
        data = JSON.parse(chunk.bytes)
        
        # Access token text based on Nova payload schema
        token = data.dig('chunk', 'bytes') ? JSON.parse(Base64.decode64(data['chunk']['bytes'])).dig('output', 'message', 'content', 0, 'text') : ""
        
        if token.present?
          response.stream.write("data: #{ { token: token }.to_json }\n\n")
        end
      end
    end
  ensure
    response.stream.close
  end
end
```

### 4. Next.js 16

Consume the SSE stream from the Rails API and render the result dynamically:

```typescript
// app/components/ChatBox.tsx
'use client';

import React, { useState } from 'react';

export default function ChatBox() {
  const [prompt, setPrompt] = useState('');
  const [response, setResponse] = useState('');
  const [loading, setLoading] = useState(false);

  const startStream = async () => {
    setResponse('');
    setLoading(true);

    const eventSource = new EventSource(
      `http://localhost:3001/chats/stream?prompt=${encodeURIComponent(prompt)}`
    );

    eventSource.onmessage = (event) => {
      const data = JSON.parse(event.data);
      if (data.token) {
        setResponse((prev) => prev + data.token);
      }
    };

    eventSource.onerror = (err) => {
      console.error('SSE connection error:', err);
      eventSource.close();
      setLoading(false);
    };
  };

  return (
    <div className="flex flex-col gap-4 p-6 bg-gray-950 text-white rounded-xl max-w-lg mx-auto">
      <textarea
        value={prompt}
        onChange={(e) => setPrompt(e.target.value)}
        placeholder="Ask something..."
        className="p-3 bg-gray-900 border border-gray-800 rounded-lg text-white outline-none focus:border-blue-500"
      />
      <button
        onClick={startStream}
        disabled={loading}
        className="py-2 bg-blue-600 rounded-lg font-bold hover:bg-blue-500 disabled:opacity-50"
      >
        {loading ? 'Generating...' : 'Send Message'}
      </button>
      <div className="p-4 bg-gray-900 rounded-lg min-h-[100px] border border-gray-800 whitespace-pre-wrap">
        {response || <span className="text-gray-600">Response will stream here...</span>}
      </div>
    </div>
  );
}
```

---

## Labs & Exercises

### Lab 7.1: Streaming Output to Console

1. Create a script at `labs/lesson-007/stream_console.rb`.
2. Configure the script to query Claude 3.5 Sonnet using `invoke_model_with_response_stream`.
3. Inside the `on_chunk_received` callback, decode the payload chunk and use `print token` to display the response in real-time in the terminal.

### Exercise

Modify the Ruby script to calculate metrics:

- Time to First Token (TTFT) in milliseconds.
- Overall generation speed in tokens per second.

---

## Quiz

1. **Which API is used to stream model completions word-by-word?**
   - A) `InvokeModel`
   - B) `InvokeModelWithResponseStream`
   - C) `Converse`
   - D) `GetModelStream`

2. **Why is it important to disable buffering (e.g. `X-Accel-Buffering: no`) in your reverse proxy when streaming SSE?**
   - A) Buffering increases encryption strength
   - B) Buffering stores tokens on disk, causing latency
   - C) Buffering blocks immediate chunk transfers, forcing the client to receive the response all at once
   - D) Buffering is incompatible with HTTPS

3. **What header must be present on a rails response to initiate an SSE connection?**
   - A) `Content-Type: application/json`
   - B) `Content-Type: text/event-stream`
   - C) `Content-Type: text/html`
   - D) `Content-Type: multipart/form-data`

### Answer Key

1: B, 2: C, 3: B

---

## Interview Questions

**Q: Contrast how you handle raw bytes from an InvokeModelWithResponseStream event between Anthropic Claude and Amazon Nova models.**

*Answer*: The event stream returns serialized JSON chunks. However, the schema of the decoded JSON differs:

- For **Anthropic**, chunk details contain fields like `type: "content_block_delta"` and the text is found inside `delta.text`.
- For **Amazon Nova**, the chunk returns base64-encoded bytes under `chunk.bytes` which must be base64-decoded and parsed as JSON to retrieve the text at `output.message.content[0].text`.

---

## Best Practices & Production Notes

- **Stream Cleanups**: Always wrap your streaming logic inside a `begin...ensure` block in Rails and call `response.stream.close` to prevent memory leaks and dangling connection sockets.
- **X-Accel-Buffering**: When deploying behind Nginx or Cloudflare, explicitly configure rules to permit streaming (disable buffering and compression) to avoid chunk serialization latency.
- **Error Handling**: Streaming errors can occur mid-generation. Ensure your frontend client is robust enough to catch EventSource disconnects and render existing tokens instead of crashing.
