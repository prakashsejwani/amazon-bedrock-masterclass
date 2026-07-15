# Lesson 005: Playgrounds, Workbench, & Model Evaluation

## Objectives

- Understand the capabilities of the Text, Chat, and Image Playgrounds in the AWS Console.
- Configure inference parameters: Temperature, Top P, Top K, and Stop Sequences.
- Learn the role of the Model Evaluation Workbench in benchmark testing.
- Implement a front-end client to control model parameter parameters dynamically.

---

## Theory

Prototyping in playrooms is the first step in prompt design. However, moving prompts to production requires tuning model parameters and validating accuracy systematically.

### 1. Inference Parameters Explained

- **Temperature**: Controls the randomness of the model's outputs. Value ranges from `0` to `1` (or `2` depending on model specifications).
  - **Lower Temperature (~0.1)**: Highly deterministic, repetitive, focused. Best for coding, JSON extraction, and facts.
  - **Higher Temperature (~0.9)**: Diverse, creative, unpredictable. Best for creative writing, brainstorming, and roleplay.
- **Top P (Nucleus Sampling)**: Selects from the smallest set of tokens whose cumulative probability exceeds P (e.g. `0.9` means checking top 90% likely words). Keep Top P at 1.0 if tuning Temperature.
- **Stop Sequences**: String markers that tell the model to cease token generation immediately (e.g. `\nUser:` or `</json>`).

### 2. Model Evaluation (Workbench)

The Workbench allows you to run **Model Evaluation Jobs** to measure how different models perform on custom datasets. Evaluators measure:

- **Accuracy**: Semantic similarity to ground truth responses.
- **Robustness**: Handling of prompt injection attacks or spelling errors.
- **Toxicity**: Rate of harmful or offensive generations.

Evaluations can be:

- **Automatic**: Compares generations with a reference dataset using algorithms.
- **Human**: AWS Managed Workforces or your own internal subject matter experts rank model completions.

---

## Architecture Diagram: Model Evaluation Job Pipeline

```text
+-------------------+      1. Upload Benchmark Dataset     +--------------------+
| Benchmarker (User)| ===================================> | Secure S3 Bucket   |
+-------------------+                                      +--------------------+
         ||                                                          ||
         || 2. Start Eval Job                                        || (Fetches Prompts)
         \/                                                          \/
+-------------------+      3. Invokes models & stores results+--------------------+
| Bedrock Workbench | ===================================> | CloudWatch Metrics |
| (Evaluation Job)  |                                      | & S3 Reports       |
+-------------------+                                      +--------------------+
```

---

## AWS Console Walkthrough

### Step 1: Using the Playgrounds

1. Open the **AWS Console** and search for **Amazon Bedrock**.
2. Click **Chat** under **Playgrounds** in the left sidebar.
3. Select **Meta Llama 3.3 70B Instruct** as the model.
4. On the right-hand panel, expand **Configurations**.
5. Set **Temperature** to `0.2` and type: `"Explain quantum computing in one sentence."` Click **Run**.
6. Increase **Temperature** to `0.9` and run the prompt multiple times to observe the diversity of outputs.

### Step 2: Setting up a Model Evaluation Job

1. In the Bedrock sidebar, click on **Model evaluation** under **Workbench**.
2. Click **Create evaluation job**.
3. Under **Job type**, select **Automatic** or **Human** evaluation.
4. Enter a job name and select the target model (e.g. `amazon.nova-lite-v1:0`).
5. Choose your evaluation metrics (e.g. Accuracy, Toxicity).
6. Under **Dataset**, upload a benchmark JSONL file (e.g., matching `{ "prompt": "...", "referenceResponse": "..." }`) stored in S3.
7. Click **Create** to launch the analysis.

---

## Step-by-Step Integrations

### 1. AWS CLI

Start a simple model evaluation job tracking metrics:

```bash
aws bedrock create-evaluation-job \
  --job-name "nova-lite-eval-01" \
  --evaluation-config '{"automated":{"datasetMetricConfigs":[{"metricName":"Accuracy","datasetSimilarityMetricConfigs":[{"similarityMetricName":"Semantic"}]}]}}' \
  --role-arn "arn:aws:iam::123456789012:role/BedrockEvaluationRole" \
  --region us-east-1
```

### 2. Ruby

List running model evaluation jobs:

```ruby
require 'aws-sdk-bedrock'

client = Aws::Bedrock::Client.new(region: 'us-east-1')

begin
  response = client.list_evaluation_jobs(max_results: 10)
  response.job_summaries.each do |job|
    puts "Job Name: #{job.job_name} | Status: #{job.status}"
  end
rescue Aws::Bedrock::Errors::ServiceError => e
  puts "Failed to retrieve jobs: #{e.message}"
end
```

### 3. Ruby on Rails 8

An auditor database logger to track token metrics and prompt parameters inside Rails models:

```ruby
# app/services/prompt_logger_service.rb
class PromptLoggerService
  def self.log_invocation(user_id, model_id, prompt, parameters, output, tokens)
    # Mock ActiveRecord database call
    Rails.logger.info({
      user_id: user_id,
      model_id: model_id,
      prompt: prompt,
      temperature: parameters[:temperature],
      top_p: parameters[:top_p],
      input_tokens: tokens[:input],
      output_tokens: tokens[:output],
      created_at: Time.current
    }.to_json)
  end
end
```

### 4. Next.js 16

Parameter configuration sliders UI component:

```typescript
// app/components/ParameterSlider.tsx
'use client';

import React, { useState } from 'react';

interface Config {
  temperature: number;
  topP: number;
}

export default function ParameterSlider({ onChange }: { onChange: (cfg: Config) => void }) {
  const [temp, setTemp] = useState(0.7);
  const [topP, setTopP] = useState(0.9);

  const handleTempChange = (val: number) => {
    setTemp(val);
    onChange({ temperature: val, topP });
  };

  const handleTopPChange = (val: number) => {
    setTopP(val);
    onChange({ temperature: temp, topP: val });
  };

  return (
    <div className="flex flex-col gap-4 p-4 bg-gray-900 border border-gray-800 rounded-lg text-white max-w-sm">
      <h3 className="text-md font-bold mb-2">Inference Settings</h3>
      
      <div className="flex flex-col gap-1">
        <div className="flex justify-between text-xs">
          <span>Temperature</span>
          <span>{temp}</span>
        </div>
        <input
          type="range" min="0" max="1" step="0.05"
          value={temp}
          onChange={(e) => handleTempChange(parseFloat(e.target.value))}
          className="w-full h-2 bg-gray-700 rounded-lg appearance-none cursor-pointer"
        />
      </div>

      <div className="flex flex-col gap-1">
        <div className="flex justify-between text-xs">
          <span>Top P (Nucleus)</span>
          <span>{topP}</span>
        </div>
        <input
          type="range" min="0" max="1" step="0.05"
          value={topP}
          onChange={(e) => handleTopPChange(parseFloat(e.target.value))}
          className="w-full h-2 bg-gray-700 rounded-lg appearance-none cursor-pointer"
        />
      </div>
    </div>
  );
}
```

### 5. Terraform

IAM role policy for evaluation jobs, granting access to benchmark datasets inside S3:

```hcl
resource "aws_iam_role" "bedrock_eval_role" {
  name = "BedrockModelEvaluationRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "eval_s3_policy" {
  name        = "BedrockEvalS3Policy"
  description = "Allows Model Evaluation Workbench to read data and write results to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::masterclass-benchmarks",
          "arn:aws:s3:::masterclass-benchmarks/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::masterclass-eval-reports/*"
      }
    ]
  })
}
```

---

## Labs & Exercises

### Lab 5.1: Testing Parameter Effects

1. Open the Chat Playground with Llama 3.3.
2. Ask: `"Complete this sentence with a random noun: The forest was full of..."`
3. With **Temperature** set to `0.0`, run the query 5 times. Notice if the completion changes.
4. Set **Temperature** to `1.0`, run the query 5 times. Compare the generated nouns.

### Exercise

Extend the React `ParameterSlider` component to include a text input block to configure **Stop Sequences** (maximum 3 strings, such as `["\n", "User:"]`).

---

## Quiz

1. **Which parameter directly controls the diversity and creative randomness of model generations?**
   - A) Top P
   - B) Temperature
   - C) Stop Sequences
   - D) Max Tokens

2. **When setting up an Automatic Model Evaluation job, where must the benchmark dataset be uploaded?**
   - A) GitHub repository
   - B) Local filesystem
   - C) Amazon S3 bucket
   - D) Secrets Manager

3. **What happens when the model encounters one of your configured Stop Sequences?**
   - A) It throws an API error
   - B) It stops generating further tokens and immediately returns the result
   - C) It erases the context window
   - D) It restarts prompt processing

### Answer Key

1: B, 2: C, 3: B

---

## Interview Questions

**Q: If your model output is cut off midway through a sentence, which inference parameter should you check first?**

*Answer*: The first parameter to check is **Max Tokens (or Max Output Length)**. If this parameter value is set too low, the model will cease generation once the output tokens limit is hit. You should increase this value or inspect the Stop Sequences parameter to ensure it is not triggering premature terminations.

---

## Best Practices & Production Notes

- **Benchmarking Consistency**: Never rely on a single user prompt to evaluate model changes. Maintain a test set of 100+ standard question/answer prompt datasets to benchmark accuracy changes using the workbench before releasing updates.
- **Isolate Parameters**: Avoid tuning both Temperature and Top P simultaneously, as both control token sampling probability and can mask the effects of each other.
- **Production Guardrails**: In production code, lock Temperature to `0.0` or `0.1` for structured JSON operations to guarantee consistent payload processing, reserving high values exclusively for conversational or creative features.
