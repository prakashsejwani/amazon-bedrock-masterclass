# Lesson 011: Structured Outputs & JSON Mode

## Objectives

- Enforce structured model responses using JSON schemas.
- Compare structured output configurations across Bedrock, OpenAI, and Vertex AI.
- Parse and validate model completions against ActiveModel definitions in Rails 8.
- Render dynamic Next.js UI elements directly mapped from the returned JSON payloads.

---

## Theory

By default, LLMs return raw conversational text. For APIs, this is problematic because application logic expects formatted data payloads (e.g. database fields, metrics arrays, or command arguments). **Structured Outputs** force the model's token selection engine to strictly follow a pre-defined JSON Schema.

### 1. JSON Mode vs. Strict Schemas

- **JSON Mode**: Instructs the model to output a valid JSON block, but does not guarantee the schema layout or presence of specific properties.
- **Strict JSON Schema**: Restricts model token grammar generation to only select paths that resolve within a defined schema. If the model attempts to emit invalid properties, the parser halts.

### 2. Multi-Cloud Comparison: JSON Schema Enforcement

- **Amazon Bedrock (Converse API)**:
  - Enforces schema matching primarily through **Tool Use (Function Calling)** configurations where the tool schema serves as the output structure.
  - Models like **Amazon Nova** support explicit `responseFormat` properties targeting JSON outputs.
- **OpenAI (Chat Completions)**:
  - Supports `response_format: { type: "json_schema", json_schema: { ... } }` with `strict: true` validation.
- **Google Cloud Vertex AI (Gemini)**:
  - Employs `responseSchema` configurations passed directly inside `generationConfig`.

---

## Architecture Diagram: Structured Outputs Flow

```text
+-------------------+      1. Request with JSON Schema      +--------------------+
| Rails API Service | ====================================> | AWS Bedrock Runtime|
| (ActiveModel validation)                                  | (SigV4 personal)   |
+-------------------+                                       +--------------------+
         ^                                                             ||
         ||                                                            || 2. Enforces JSON
         || 4. Map parsed JSON to database records                     \/    token grammar
+-------------------+                                       +--------------------+
| SQLite Database   | <==================================== | Structured Output  |
| (Saves clean data)|          3. Validate schema           | (Valid JSON block) |
+-------------------+             and properties            +--------------------+
```

---

## AWS CLI Walkthrough

### Step 1: Requesting Structured Outputs via Tool Use Configuration

We can force Bedrock to return JSON structure by declaring a mock tool schema and instructing the model to use it. Run this command using the `personal` profile:

```bash
aws bedrock-runtime converse \
  --model-id "amazon.nova-micro-v1:0" \
  --messages '[{"role":"user","content":[{"text":"Extract information from: Prakash lives in Seattle and works in Tech."}]}]' \
  --tool-config '{"tools":[{"toolSpec":{"name":"SaveProfile","description":"Saves user profile","inputSchema":{"json":{"type":"object","properties":{"name":{"type":"string"},"location":{"type":"string"},"industry":{"type":"string"}},"required":["name","location","industry"]}}}}],"toolChoice":{"tool":{"name":"SaveProfile"}}}' \
  --profile personal
```

### Step 2: Evaluating the Structured JSON Output

The API skips dialogue text and directly calls the tool with correctly structured inputs:

```json
{
  "output": {
    "message": {
      "role": "assistant",
      "content": [
        {
          "toolUse": {
            "toolUseId": "tooluse_123",
            "name": "SaveProfile",
            "input": {
              "name": "Prakash",
              "location": "Seattle",
              "industry": "Tech"
            }
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

Configure a schema tool payload in Ruby using the `personal` profile to return structured data:

```ruby
require 'aws-sdk-bedrockruntime'
require 'json'

client = Aws::BedrockRuntime::Client.new(
  region: 'us-east-1',
  credentials: Aws::SharedCredentials.new(profile_name: 'personal')
)

tool_schema = {
  tools: [
    {
      tool_spec: {
        name: 'extract_product',
        description: 'Extracts product detail specifications',
        input_schema: {
          json: {
            type: 'object',
            properties: {
              title: { type: 'string' },
              price: { type: 'number' },
              in_stock: { type: 'boolean' }
            },
            required: ['title', 'price', 'in_stock']
          }
        }
      }
    }
  ],
  tool_choice: { tool: { name: 'extract_product' } }
}

response = client.converse(
  model_id: 'amazon.nova-micro-v1:0',
  messages: [{ role: 'user', content: [{ text: 'Found standard laptop for $999. Available now.' }] }],
  tool_config: tool_schema
)

tool_use = response.output.message.content[0].tool_use
puts "Extracted JSON: #{tool_use.input.to_h.to_json}"
```

### 2. Ruby on Rails 8

Implement an ActiveModel class to validate JSON responses returned from Bedrock:

```ruby
# app/models/extracted_profile.rb
class ExtractedProfile
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :name, :location, :industry

  validates :name, presence: true
  validates :location, presence: true
  validates :industry, presence: true
end

# app/services/profile_extraction_service.rb
class ProfileExtractionService
  def self.extract(unstructured_text)
    client = Aws::BedrockRuntime::Client.new(
      region: 'us-east-1',
      credentials: Aws::SharedCredentials.new(profile_name: 'personal')
    )

    tool_config = {
      tools: [{
        tool_spec: {
          name: 'save_profile',
          description: 'Saves user profile',
          input_schema: {
            json: {
              type: 'object',
              properties: {
                name: { type: 'string' },
                location: { type: 'string' },
                industry: { type: 'string' }
              },
              required: ['name', 'location', 'industry']
            }
          }
        }
      }],
      tool_choice: { tool: { name: 'save_profile' } }
    }

    response = client.converse(
      model_id: 'amazon.nova-micro-v1:0',
      messages: [{ role: 'user', content: [{ text: unstructured_text }] }],
      tool_config: tool_config
    )

    data = response.output.message.content[0].tool_use.input.to_h

    profile = ExtractedProfile.new(data)
    if profile.valid?
      profile
    else
      Rails.logger.error("Profile validation failed: #{profile.errors.full_messages}")
      nil
    end
  end
end
```

### 3. Next.js 16

Consume the Rails API and render dynamic input fields derived from the structured JSON properties:

```typescript
// app/components/DynamicProfileForm.tsx
'use client';

import React, { useState } from 'react';

interface Profile {
  name: string;
  location: string;
  industry: string;
}

export default function DynamicProfileForm() {
  const [inputText, setInputText] = useState('');
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(false);

  const handleExtract = async () => {
    setLoading(true);
    setProfile(null);

    try {
      const res = await fetch('/api/extract-profile', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: inputText })
      });
      const data = await res.json();
      if (data.profile) {
        setProfile(data.profile);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col gap-4 p-6 bg-gray-950 text-white rounded-xl border border-gray-900 max-w-md mx-auto">
      <textarea
        value={inputText}
        onChange={(e) => setInputText(e.target.value)}
        placeholder="Enter biographical context details..."
        className="p-3 bg-gray-900 border border-gray-800 rounded text-sm"
      />
      <button
        onClick={handleExtract} disabled={loading}
        className="py-2 bg-blue-600 rounded text-sm font-bold hover:bg-blue-500 disabled:opacity-50"
      >
        {loading ? 'Extracting JSON...' : 'Process Profile'}
      </button>

      {profile && (
        <div className="flex flex-col gap-3 p-4 bg-gray-900 rounded border border-gray-800 text-sm">
          <div>
            <label className="text-xs text-gray-500">Name</label>
            <input readOnly value={profile.name} className="w-full bg-transparent border-b border-gray-800 py-1" />
          </div>
          <div>
            <label className="text-xs text-gray-500">Location</label>
            <input readOnly value={profile.location} className="w-full bg-transparent border-b border-gray-800 py-1" />
          </div>
          <div>
            <label className="text-xs text-gray-500">Industry</label>
            <input readOnly value={profile.industry} className="w-full bg-transparent border-b border-gray-800 py-1" />
          </div>
        </div>
      )}
    </div>
  );
}
```

---

## Labs & Exercises

### Lab 11.1: Constructing a Struct Parser

1. Create a script at `labs/lesson-011/struct_parser.rb`.
2. Configure the script to call Bedrock using the `personal` credentials profile.
3. Supply a schema to parse flight details (`flight_number`, `departure_gate`, `delayed`).
4. Cast the returned JSON values into a Ruby `Struct` class instance.
5. Add error handling to catch formatting failures.

### Exercise

Modify the Rails `ProfileExtractionService` to raise a validation exception if the model fails to populate any required fields, returning a formatted client error message detailing the missing fields.

---

## Quiz

See [Lesson 011 Quiz](../quizzes/lesson-011-quiz.md).

## Interview Questions

See [Lesson 011 Interview Questions](../interview/lesson-011-interview.md).

## Best Practices & Production Notes

- **Required Properties**: Always define a `required` list inside your JSON Schemas. If keys are omitted from the list, the model is free to output an empty object.
- **Handling Model Halts**: Under schema constraint systems, if the model runs out of output tokens before the JSON structure is closed, the return payload will be invalid. Ensure `max_tokens` is configured high enough to complete the entire schema payload block.
- **Fallback Schemas**: Keep schema structures clean. Complex nested arrays or deeply recursive objects increase generation latency. Prefer flat, strongly-typed key-value schemas for low-latency production applications.
