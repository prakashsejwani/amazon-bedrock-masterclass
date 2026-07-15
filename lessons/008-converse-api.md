# Lesson 008: Converse API (Unified Multi-turn Dialogues)

## Objectives

- Understand the design of the Amazon Bedrock Converse API and how it abstracts model-specific schemas.
- Implement multi-turn conversational systems by maintaining dialogue state.
- Query Bedrock models using Converse and ConverseStream APIs.
- Configure SDK clients to use named AWS credential profiles (such as the `personal` profile).

---

## Theory

Previously, developers had to write custom payload formatting adapters for each model provider (e.g. one structure for Claude, another for Llama). The **Converse API** solves this by offering a unified, structured request/response interface across all supported text and multimodal foundation models.

### 1. Structure of the Converse Request

The Converse API payload consists of four primary blocks:

- **`modelId`**: The target foundation model identifier.
- **`system`**: An optional array of system prompts to guide the model's tone, scope, or guardrails (e.g., `[{ text: "You are a coding assistant." }]`).
- **`messages`**: An array of message objects representing the dialogue history. Roles must alternate between `user` and `assistant`.
- **`inferenceConfig`**: Common generation parameters like `temperature`, `maxTokens`, `topP`, and `stopSequences`.

### 2. Alternating Messages Format

A message contains a `role` and `content`. Content is structured as an array of blocks supporting either `text`, `image`, or `document` (PDF) inputs:

```json
[
  {
    "role": "user",
    "content": [{ "text": "Hello, what is Rails 8?" }]
  },
  {
    "role": "assistant",
    "content": [{ "text": "Rails 8 is the latest version of the Ruby on Rails web framework..." }]
  },
  {
    "role": "user",
    "content": [{ "text": "What is new in it?" }]
  }
]
```

---

## Architecture Diagram: Converse API Lifecycle

```text
+--------------+                   1. Request Payload                     +---------------------+
| Next.js Client| =======================================================> | Rails 8 Application |
+--------------+   (Sends User Message + Session Conversation History)    +---------------------+
       ^                                                                            ||
       |                                                                            || 2. Assumes 'personal'
       | 4. SSE / Structured Response                                               ||    credentials &
       |    "output: { message: ... }"                                              \/    invokes Converse
+------------------------------------+                                    +---------------------+
| Next.js Chat Interface (Renders)   | <================================= | AWS Bedrock Runtime |
+------------------------------------+                                    | (Unified Endpoint)  |
                                                                          +---------------------+
```

---

## AWS CLI Walkthrough

### Step 1: Querying Converse using the `personal` Profile

You can initiate a converse query from the CLI using your configured credentials. Run the following command:

```bash
aws bedrock-runtime converse \
  --model-id "amazon.nova-micro-v1:0" \
  --messages '[{"role":"user","content":[{"text":"Give me a 1-sentence motivation quote."}]}]' \
  --profile personal
```

### Step 2: Interpreting the Response JSON

The CLI output returns a structured response matching:

```json
{
  "output": {
    "message": {
      "role": "assistant",
      "content": [
        {
          "text": "Believe you can and you're halfway there."
        }
      ]
    }
  },
  "stopReason": "end_of_turn",
  "usage": {
    "inputTokens": 18,
    "outputTokens": 10,
    "totalTokens": 28
  }
}
```

---

## Step-by-Step Integrations

### 1. Ruby

Invoke the Converse API utilizing the `personal` profile from your credentials file:

```ruby
require 'aws-sdk-bedrockruntime'
require 'json'

# Initialize Bedrock client specifying user profile
client = Aws::BedrockRuntime::Client.new(
  region: 'us-east-1',
  credentials: Aws::SharedCredentials.new(profile_name: 'personal')
)

system_prompt = [{ text: 'You are a helpful, brief assistant.' }]

messages = [
  {
    role: 'user',
    content: [{ text: 'What is the capital of France?' }]
  }
]

response = client.converse(
  model_id: 'amazon.nova-micro-v1:0',
  messages: messages,
  system: system_prompt,
  inference_config: { max_tokens: 100, temperature: 0.5 }
)

assistant_response = response.output.message.content[0].text
puts "Assistant: #{assistant_response}"
```

### 2. Ruby on Rails 8

Implement a Conversational Controller that loads chat history from session cookies and updates it dynamically:

```ruby
# app/controllers/conversations_controller.rb
class ConversationsController < ApplicationController
  def chat
    # Fetch existing chat history or initialize
    session[:history] ||= []
    
    # Append the user's new message
    user_message = {
      role: 'user',
      content: [{ text: params[:message] }]
    }
    session[:history] << user_message

    # Call Converse API using personal profile config
    client = Aws::BedrockRuntime::Client.new(
      region: 'us-east-1',
      credentials: Aws::SharedCredentials.new(profile_name: 'personal')
    )

    response = client.converse(
      model_id: 'amazon.nova-micro-v1:0',
      messages: session[:history],
      system: [{ text: 'You are a technical teaching assistant.' }],
      inference_config: { max_tokens: 300, temperature: 0.7 }
    )

    # Extract output and store in history
    assistant_msg = {
      role: 'assistant',
      content: [{ text: response.output.message.content[0].text }]
    }
    session[:history] << assistant_msg

    render json: {
      reply: assistant_msg.dig(:content, 0, :text),
      token_usage: response.usage
    }
  end

  def clear
    session[:history] = []
    render json: { message: 'History cleared' }
  end
end
```

### 3. Next.js 16

Provide a conversational UI displaying message logs:

```typescript
// app/components/ChatHistory.tsx
'use client';

import React, { useState } from 'react';

interface ChatMessage {
  role: 'user' | 'assistant';
  text: string;
}

export default function ChatHistory() {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);

  const sendMessage = async () => {
    if (!input.trim()) return;
    setLoading(true);

    const userMsg: ChatMessage = { role: 'user', text: input };
    setMessages(prev => [...prev, userMsg]);
    setInput('');

    try {
      const res = await fetch(`/api/chat?message=${encodeURIComponent(input)}`);
      const data = await res.json();
      
      const assistantMsg: ChatMessage = { role: 'assistant', text: data.reply };
      setMessages(prev => [...prev, assistantMsg]);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col gap-4 max-w-xl mx-auto p-4 bg-gray-950 text-white rounded-xl border border-gray-900">
      <div className="flex flex-col gap-2 overflow-y-auto max-h-[400px] p-2 bg-gray-900 rounded-lg">
        {messages.map((m, idx) => (
          <div key={idx} className={`p-3 rounded-lg max-w-[80%] ${m.role === 'user' ? 'ml-auto bg-blue-600' : 'mr-auto bg-gray-800'}`}>
            <span className="text-xs text-gray-400 block mb-1">{m.role === 'user' ? 'You' : 'Assistant'}</span>
            <p className="text-sm">{m.text}</p>
          </div>
        ))}
      </div>
      <div className="flex gap-2">
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Type message..."
          className="flex-1 p-2 bg-gray-900 border border-gray-800 rounded outline-none focus:border-blue-500 text-sm"
        />
        <button
          onClick={sendMessage} disabled={loading}
          className="px-4 py-2 bg-blue-600 rounded text-sm font-bold hover:bg-blue-500"
        >
          Send
        </button>
      </div>
    </div>
  );
}
```

### 4. Terraform

Provide environment values tracking active system prompts:

```hcl
resource "aws_ssm_parameter" "system_prompt" {
  name        = "/config/bedrock/system_prompt"
  description = "The global system prompt configuration for Bedrock applications"
  type        = "String"
  value       = "You are a professional software engineering guide. Keep replies clean."
}
```

---

## Labs & Exercises

### Lab 8.1: Creating a Console Chat loop

1. Create a script at `labs/lesson-008/chat_loop.rb`.
2. Configure the script to utilize `Aws::SharedCredentials.new(profile_name: 'personal')`.
3. Build a loop that accepts input using `gets.chomp` and calls the Converse API, maintaining history in an array until the user types `exit`.

### Exercise

Extend the Rails `ConversationsController` to store chat sessions inside the database (SQLite) instead of session cookies, creating a `Message` model that belongs to a `Conversation` model to support persistent history reloading.

---

## Quiz

See [Lesson 008 Quiz](../quizzes/lesson-008-quiz.md).

## Interview Questions

See [Lesson 008 Interview Questions](../interview/lesson-008-interview.md).

## Best Practices & Production Notes

- **Context Window Pruning**: Conversational history grows with each turn. Models have maximum context window limits. Implement pruning strategies (e.g. only keeping the last 10 messages, or summarizing old turns) to prevent context limit errors and high-cost token counts.
- **SigV4 Profile Isolation**: Always ensure developer profiles (like `personal`) have separate billing limits from staging and production AWS IAM configurations.
- **Alternate Role Validation**: Keep role alternation clean. If the user posts twice in a row, combine their texts into a single `user` message block before calling the Converse API, as consecutive duplicate roles are rejected by the API.
