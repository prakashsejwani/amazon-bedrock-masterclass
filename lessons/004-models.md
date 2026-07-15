# Lesson 004: Bedrock Foundation Models (Claude, Nova, Llama, Mistral) & Model Selection

## Objectives

- Understand the model catalog available on Amazon Bedrock: Anthropic Claude, Meta Llama, Amazon Nova, and Mistral AI.
- Learn to evaluate models using the trade-offs of Latency, Cost, and Quality (Accuracy).
- Implement a model router pattern to programmatically delegate tasks to the correct model.
- Configure Infrastructure-as-Code to track and manage Model IDs.

---

## Theory

Selecting the correct model is a critical decision in system design. The "perfect model" does not exist; rather, systems architects must choose models based on specific task parameters.

### 1. Anthropic Claude Series

The Claude family is optimized for advanced reasoning, complex coding, and agentic workflows.

- **Claude 3.5 Sonnet**: The industry benchmark for code generation, complex tool usage, and visual analysis. Ideal for production agents.
- **Claude 3.5 Haiku**: Exceptionally fast and cost-effective, optimized for high-volume text categorization and simple completions.
- **Claude 3 Opus**: Optimized for extremely complex mathematical and scientific reasoning.

### 2. Amazon Nova Series

Nova is Amazon’s flagship family of models, designed from the ground up to offer state-of-the-art multimodal reasoning, high speed, and low costs.

- **Nova Micro**: Text-only, extremely fast, and cost-efficient. Designed for low-latency retrieval tasks.
- **Nova Lite**: A highly efficient multimodal model. Excellent for processing video, image, and text at scale.
- **Nova Pro**: Flagship multimodal model with deep analytical, translation, and coding capabilities.

### 3. Meta Llama Series

Llama models represent Meta's open-weights contributions, hosted as a fully managed service on Bedrock.

- **Llama 3.3 70B**: Top-tier reasoning and instruct capabilities, competing directly with much larger models.
- **Llama 3.1 8B**: Lightweight and fast, ideal for summarization and low-compute tasks.

### 4. Mistral AI Series

Mistral models offer excellent multilingual support and compact efficiency.

- **Mistral Large**: Designed for complex reasoning and agent use cases.
- **Mistral Small**: Low latency, lightweight model.

---

## Model Selection Matrix

| Model family | Strengths | Use Cases | Cost Profile |
| :--- | :--- | :--- | :--- |
| **Claude** | Coding, complex logic, Tool use | Agent loops, code generation | Higher |
| **Nova** | Multimodal video/image, cost | Batch video processing, high volume | Very Low |
| **Llama** | Direct instructs, standard completions | Summarization, parsing | Moderate |
| **Mistral** | Multilingual tasks, low latency | Language translations, categorization | Moderate |

---

## Architecture Diagram: Model Routing Engine

A model routing engine dynamically selects a model based on the complexity of the input query:

```text
+-------------------+      1. Query       +--------------------+
|  User / Client    | ==================> | Model Router       |
+-------------------+                     | (Rails Service)    |
                                          +--------------------+
                                            /        |        \
                             2a. Low Cost  /         |         \ 2c. Multi-Modal
                              (Nova Micro)/  2b. Code|          \ (Nova Lite)
                                         /   (Sonnet)|           \
                                        v            v            v
                                 +----------+  +----------+  +----------+
                                 |Nova Micro|  |Claude 3.5|  |Nova Lite |
                                 +----------+  +----------+  +----------+
```

---

## Step-by-Step Integrations

### 1. AWS CLI

List all model IDs that match the provider "Anthropic":

```bash
aws bedrock list-foundation-models --query "modelSummaries[?providerName=='Anthropic'].modelId" --output json
```

### 2. Ruby

Retrieve details for a specific model class and check input modalities support:

```ruby
require 'aws-sdk-bedrock'

client = Aws::Bedrock::Client.new(region: 'us-east-1')

models = ['anthropic.claude-3-5-sonnet-20241022-v2:0', 'amazon.nova-micro-v1:0']

models.each do |model_id|
  details = client.get_foundation_model(model_identifier: model_id).model_details
  puts "ID: #{details.model_id} | Input modalities: #{details.input_modalities.join(', ')}"
end
```

### 3. Ruby on Rails 8

Implement a dynamic Model Router service that maps a task's complexity to the correct model:

```ruby
# app/services/model_router_service.rb
class ModelRouterService
  MODELS = {
    fast: 'amazon.nova-micro-v1:0',
    balanced: 'meta.llama3-3-70b-instruct-v1:0',
    complex: 'anthropic.claude-3-5-sonnet-20241022-v2:0',
    multimodal: 'amazon.nova-lite-v1:0'
  }.freeze

  def self.resolve_model(task_type)
    MODELS[task_type.to_sym] || MODELS[:balanced]
  end

  def self.invoke_for_task(task_type, payload)
    model_id = resolve_model(task_type)
    Rails.logger.info("Routing task #{task_type} to model #{model_id}")
    # Connection logic goes here in Lesson 007
    model_id
  end
end
```

### 4. Next.js 16

Provide a dropdown model selection interface in Next.js:

```typescript
// app/components/ModelSelector.tsx
'use client';

import React, { useState } from 'react';

interface Model {
  id: string;
  name: string;
  category: 'fast' | 'balanced' | 'complex';
}

const AVAILABLE_MODELS: Model[] = [
  { id: 'amazon.nova-micro-v1:0', name: 'Nova Micro (Fast)', category: 'fast' },
  { id: 'meta.llama3-3-70b-instruct-v1:0', name: 'Llama 3.3 (Balanced)', category: 'balanced' },
  { id: 'anthropic.claude-3-5-sonnet-20241022-v2:0', name: 'Claude 3.5 Sonnet (Complex)', category: 'complex' }
];

export default function ModelSelector({ onSelect }: { onSelect: (id: string) => void }) {
  const [selectedModel, setSelectedModel] = useState(AVAILABLE_MODELS[0].id);

  const handleChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const val = e.target.value;
    setSelectedModel(val);
    onSelect(val);
  };

  return (
    <div className="flex flex-col gap-2 p-4 bg-gray-900 text-white rounded-lg">
      <label htmlFor="model-select" className="text-sm font-semibold">Select Bedrock Model:</label>
      <select
        id="model-select"
        value={selectedModel}
        onChange={handleChange}
        className="p-2 bg-gray-800 border border-gray-700 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
      >
        {AVAILABLE_MODELS.map(m => (
          <option key={m.id} value={m.id}>{m.name}</option>
        ))}
      </select>
    </div>
  );
}
```

### 5. Terraform

Deploy SSM parameters to dynamically control Model IDs in your infrastructure without re-deploying code:

```hcl
resource "aws_ssm_parameter" "bedrock_default_model" {
  name        = "/config/bedrock/default_model"
  description = "The default foundation model ID for our API applications"
  type        = "String"
  value       = "anthropic.claude-3-5-sonnet-20241022-v2:0"
}

resource "aws_ssm_parameter" "bedrock_fast_model" {
  name        = "/config/bedrock/fast_model"
  description = "The low-latency foundation model ID"
  type        = "String"
  value       = "amazon.nova-micro-v1:0"
}
```

---

## Labs & Exercises

### Lab 4.1: Writing a Model Router Script

1. Create a script `labs/lesson-004/model_router.rb` that accepts a string prompt as an argument.
2. If the prompt contains the word `"code"` or `"implement"`, route the query to Claude 3.5 Sonnet.
3. If the prompt contains the word `"summarize"` or `"categorize"`, route the query to Nova Micro.
4. Print the selected Model ID and the routing reasoning.

### Exercise

Extend the Next.js dropdown selector to render input cost per 1M tokens next to each model name based on current Bedrock pricing schedules (e.g. Claude 3.5 Sonnet input is $3.00/1M, Nova Micro is $0.035/1M).

---

## Quiz

See [Lesson 004 Quiz](../quizzes/lesson-004-quiz.md).

## Interview Questions

See [Lesson 004 Interview Questions](../interview/lesson-004-interview.md).

## Best Practices & Production Notes

- **Fallback Strategy**: Always configure your routers with a fallback model ID. If a specific model encounters temporary throttling limits, gracefully fallback to another model.
- **Model Deprecation Lifecycle**: AWS deprecates older model endpoints. Track model lifecycle schedules and use SSM/Environment parameters so you can update IDs dynamically.
- **Pricing Alerts**: Multimodal invocations (video/audio processing) require large payloads. Set up AWS Budgets alert tags for Amazon Bedrock usage to catch unexpected billing spikes.
