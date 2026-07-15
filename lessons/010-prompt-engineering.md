# Lesson 010: Advanced Prompt Engineering & Converse Parameters

## Objectives

- Apply advanced prompting frameworks (Few-shot learning, Chain of Thought, XML Tagging) within the Converse API.
- Understand the behavior of system prompts in setting role constraints and safety boundaries.
- Compare prompt parameters and system message formatting across Bedrock, OpenAI, and Vertex AI.
- Build a dynamic prompt template compiler in Ruby on Rails.

---

## Theory

Prompt engineering is not just "asking nicely." It is the process of structuring instructions, contextual details, examples, and output constraints to maximize model accuracy and reliability.

### 1. Key Prompting Frameworks

- **Few-Shot Prompting**: Providing a few complete examples of inputs and desired outputs inside the message array. This guides the model's tone, format, and reasoning paths without custom model training.
- **Chain of Thought (CoT)**: Instructing the model to output its step-by-step reasoning *before* providing the final answer (e.g. `"Let's think step-by-step:"`). This significantly increases accuracy for logic, math, and code tasks.
- **XML Tagging**: Models like Anthropic Claude and Meta Llama are trained specifically to parse XML tags (e.g. `<instructions>`, `<context>`, `<rules>`). Tags help separate instruction blocks from user inputs, preventing prompt injection attacks.

### 2. Multi-Cloud Comparison: Prompt Parameters & Systems

| Parameter / Feature | Amazon Bedrock (Converse) | OpenAI (Chat Completions) | Google Vertex AI (Gemini) |
| :--- | :--- | :--- | :--- |
| **System Messages** | Scoped in root `system` array param | Passed as a message block with `role: "system"` | Scoped in `systemInstruction` config |
| **Few-Shot Schema** | Alternating `user`/`assistant` message nodes | Alternating `user`/`assistant` nodes | Alternating `user`/`model` parts |
| **Temperature Range** | `0.0` to `1.0` | `0.0` to `2.0` | `0.0` to `2.0` |
| **Stop Tokens** | Explicit array in `inferenceConfig` | Explicit array in `stop` parameter | Scoped in `generationConfig.stopSequences` |

---

## Architecture Diagram: Dynamic Prompt Compilation Pipeline

```text
+-------------------+      1. Load Template & Context     +--------------------+
| Rails API Service | =============================> | S3 / Database      |
| (Compiler)        |                                 | (XML templates)    |
+-------------------+                                 +--------------------+
         ||                                                      ||
         || 2. Compiles XML Tags with dynamic user inputs        || (Fetches template)
         \/                                                      \/
+-------------------+      3. Invokes Converse API           +--------------------+
| Bedrock Converse  | =============================> | Model Execution    |
| (SigV4 personal)  |                                 | (Runs Claude/Nova) |
+-------------------+                                 +--------------------+
```

---

## AWS CLI Walkthrough

### Step 1: Querying Converse with XML Tags & System Prompts

Run the following command using the `personal` profile to pass structured context and instructions:

```bash
aws bedrock-runtime converse \
  --model-id "amazon.nova-micro-v1:0" \
  --system '[{"text":"You are a helpful customer service assistant. Respond in JSON only."}]' \
  --messages '[{"role":"user","content":[{"text":"<customer_query>I want to return a broken item.</customer_query>\n<instructions>Classify query category and return JSON matching { \"category\": \"string\" }</instructions>"}]}]' \
  --profile personal
```

### Step 2: Interpreting the Response Output

The model reads the boundaries cleanly and returns:

```json
{
  "output": {
    "message": {
      "role": "assistant",
      "content": [
        {
          "text": "{\n  \"category\": \"returns\"\n}"
        }
      ]
    }
  }
}
```

---

## Step-by-Step Integrations

### 1. Ruby

Invoke Converse with a few-shot message sequence using the `personal` credentials profile:

```ruby
require 'aws-sdk-bedrockruntime'
require 'json'

client = Aws::BedrockRuntime::Client.new(
  region: 'us-east-1',
  credentials: Aws::SharedCredentials.new(profile_name: 'personal')
)

system_prompt = [{ text: 'You translate tech slang to corporate business English.' }]

# Alternating user/assistant blocks for few-shot learning
messages = [
  { role: 'user', content: [{ text: 'This feature is fire.' }] },
  { role: 'assistant', content: [{ text: 'This feature is highly performant and valuable.' }] },
  { role: 'user', content: [{ text: 'I am AFK.' }] },
  { role: 'assistant', content: [{ text: 'I am currently away from my desk.' }] },
  { role: 'user', content: [{ text: 'We need to push this to main ASAP.' }] }
]

response = client.converse(
  model_id: 'amazon.nova-micro-v1:0',
  messages: messages,
  system: system_prompt,
  inference_config: { max_tokens: 100, temperature: 0.0 }
)

puts "Result: #{response.output.message.content[0].text}"
```

### 2. Ruby on Rails 8

Implement a prompt compiler service that loads templates and formats them with XML tags securely:

```ruby
# app/services/prompt_compiler_service.rb
class PromptCompilerService
  def self.compile_translation_prompt(user_input, language = 'Spanish')
    <<~XML
      <instructions>
        Translate the text inside <source_text> tags into #{language}.
        Do not include explanations or tags in the output.
      </instructions>
      
      <source_text>
        #{user_input.strip}
      </source_text>
    XML
  end

  def self.execute_translation(text, target_lang)
    prompt = compile_translation_prompt(text, target_lang)

    client = Aws::BedrockRuntime::Client.new(
      region: 'us-east-1',
      credentials: Aws::SharedCredentials.new(profile_name: 'personal')
    )

    response = client.converse(
      model_id: 'amazon.nova-micro-v1:0',
      messages: [{ role: 'user', content: [{ text: prompt }] }],
      inference_config: { temperature: 0.1, max_tokens: 1000 }
    )

    response.output.message.content[0].text.strip
  end
end
```

### 3. Next.js 16

Dynamic prompt builder screen letting users adjust parameters:

```typescript
// app/components/PromptBuilder.tsx
'use client';

import React, { useState } from 'react';

export default function PromptBuilder() {
  const [inputText, setInputText] = useState('');
  const [xmlContext, setXmlContext] = useState('');
  const [result, setResult] = useState('');
  const [loading, setLoading] = useState(false);

  const handleCompileAndRun = async () => {
    setLoading(true);
    setResult('');

    // Send context + raw text to Rails API translation service
    try {
      const res = await fetch(`/api/translate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: inputText, context: xmlContext })
      });
      const data = await res.json();
      setResult(data.translation);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col gap-4 p-6 bg-gray-950 text-white rounded-xl border border-gray-900 max-w-md mx-auto">
      <h3 className="text-md font-bold">XML Prompt Builder</h3>
      
      <input
        value={xmlContext}
        onChange={(e) => setXmlContext(e.target.value)}
        placeholder="XML Context (e.g. <rules>Be professional</rules>)"
        className="p-2 bg-gray-900 border border-gray-800 rounded text-sm"
      />

      <textarea
        value={inputText}
        onChange={(e) => setInputText(e.target.value)}
        placeholder="Source text to process..."
        className="p-2 bg-gray-900 border border-gray-800 rounded text-sm min-h-[80px]"
      />

      <button
        onClick={handleCompileAndRun} disabled={loading}
        className="py-2 bg-blue-600 rounded hover:bg-blue-500 text-sm font-bold disabled:opacity-50"
      >
        {loading ? 'Processing...' : 'Run Compiled Prompt'}
      </button>

      <div className="p-4 bg-gray-900 border border-gray-800 rounded text-sm min-h-[60px]">
        {result || <span className="text-gray-600">Result...</span>}
      </div>
    </div>
  );
}
```

### 4. Terraforn

Deploy SSM templates defining global system prompt instructions:

```hcl
resource "aws_ssm_parameter" "compiler_system_rules" {
  name        = "/config/bedrock/compiler_system_rules"
  description = "Standard system rules for input translations"
  type        = "String"
  value       = "You are a precise technical translator. Maintain code symbols."
}
```

---

## Labs & Exercises

### Lab 10.1: Comparing Few-Shot Learning Outputs

1. Create a script at `labs/lesson-010/few_shot_test.rb`.
2. Configure the script to load the `personal` AWS profile.
3. Test querying a model to extract address details from unstructured text:
   - Run once with a zero-shot prompt (no examples).
   - Run a second time using alternating few-shot user/assistant messages containing structured example text.
4. Compare output formatting accuracy.

### Exercise

Extend the Rails `PromptCompilerService` to include helper tags like `<metadata>` and `<schema>` automatically wrapping input values to enforce structural returns.

---

## Quiz

See [Lesson 010 Quiz](../quizzes/lesson-010-quiz.md).

## Interview Questions

See [Lesson 010 Interview Questions](../interview/lesson-010-interview.md).

## Best Practices & Production Notes

- **XML Tag Completeness**: Always close your XML tags (e.g. open `<text>` and close with `</text>`). Models are sensitive to syntactic alignment and perform better when tags are closed.
- **Dynamic Escaping**: When building prompt compilers in Rails, ensure user-supplied text does not contain closing XML tags that match your compiler tags, which would allow users to escape the context boundary.
- **Temperature for Coding**: When generating code or parsing files, keep Temperature at `0.0` to minimize formatting variation, reserving higher temperatures only for content generation.
