# Lesson 001: Introduction to Amazon Bedrock & Generative AI on AWS

## Objectives

- Understand what Amazon Bedrock is and where it fits in the AWS Generative AI stack.
- Learn core GenAI terminologies: Foundation Models (FMs), tokens, contexts, and embeddings.
- Contrast Bedrock's managed serverless approach with running open-source models on raw virtual machines.
- Review Bedrock's security posture and data privacy guarantees.

---

## Theory

### What is Amazon Bedrock?

Amazon Bedrock is a fully managed, serverless AWS service designed to make foundation models (FMs) from leading AI companies—such as Anthropic, Meta, Mistral AI, Cohere, and Amazon—accessible via a single, unified API.

By using Bedrock, you do not need to manage underlying GPUs, orchestrate container scheduling, or build custom API scaling layers. AWS handles the operational heavy lifting, providing a high-availability endpoints network out of the box.

### The AWS Generative AI Stack

AWS conceptualizes Generative AI across three distinct layers:

1. **Infrastructure Layer**: For ML experts building models from scratch. Consists of AWS Trainium, Inferentia, and Nvidia H100 GPUs on Amazon EC2.
2. **Model Integration Layer (Amazon Bedrock)**: For software developers building application features. Provides ready-to-use models via serverless APIs.
3. **Application Layer**: For business users. Turnkey tools like Amazon Q Business and Amazon Q Developer.

```text
+-------------------------------------------------------------+
| 3. Application Layer (Amazon Q Business, Amazon Q Developer)|
+-------------------------------------------------------------+
| 2. Model Integration Layer (Amazon Bedrock APIs & Agents)   |
+-------------------------------------------------------------+
| 1. Infrastructure Layer (EC2, Trainium, Inferentia, GPUs)    |
+-------------------------------------------------------------+
```

### Core Concepts & Terminologies

- **Foundation Model (FM)**: A large-scale neural network pre-trained on vast datasets (text, images, code), designed to be adapted to a wide range of downstream tasks.
- **Tokens**: The basic units of text processed by LLMs. A token can be a word, character, or sub-word. In English, 1 token is roughly equivalent to 4 characters or 0.75 words.
- **Context Window**: The maximum number of input/output tokens a model can process in a single invocation.
- **Embeddings**: High-dimensional mathematical vectors representing the semantic meaning of text, images, or audio. Used for similarity searches in vector databases.

### Security and Data Privacy

In enterprise environments, data privacy is non-negotiable. Amazon Bedrock guarantees:

- **No Training on Customer Data**: Your inputs, prompts, and completions are **never** used to train the base foundation models, nor are they shared with third-party model providers.
- **Data Isolation**: All customer data is encrypted in transit (TLS 1.2/1.3) and at rest (using AWS KMS keys). It remains strictly inside the customer's Virtual Private Cloud (VPC) boundary.

---

## Architecture Diagram

This diagram demonstrates how client applications safely query Bedrock without exposing sensitive company data to the public internet:

```text
+------------------+     (Private VPC Endpoint)     +-------------------+
|  Your Application| =============================> |   Amazon Bedrock  |
|  (ECS / Lambda)  |                                |   Serverless API  |
+------------------+                                +-------------------+
         ||                                                   ||
         || (TLS 1.3 Encryption)                              || (Internal Routing)
         \/                                                   \/
+------------------+                                +-------------------+
| Customer S3 Bucket|                                |  Foundation Model |
| (Encrypted KMS)  |                                |  (Claude, Nova)   |
+------------------+                                +-------------------+
```

---

## AWS Console Walkthrough

To begin using Amazon Bedrock, you must request access to the desired foundation models:

1. Sign in to the **AWS Management Console** and navigate to the **Amazon Bedrock** service page.
2. Ensure you are in a supported region (e.g., `us-east-1` (N. Virginia) or `us-west-2` (Oregon)).
3. In the left-hand navigation pane, scroll to the bottom and click on **Model access**.
4. Click **Modify model access** in the top right.
5. Check the boxes next to the models you wish to use (e.g., Anthropic Claude, Amazon Nova).
6. Click **Save changes**. The request status will transition to *Access granted* (usually within a few minutes).

---

## Step-by-Step Integrations

### 1. AWS CLI

```bash
aws bedrock list-foundation-models --region us-east-1 --output table
```

### 2. Ruby

```ruby
require 'aws-sdk-bedrock'

# Create a Bedrock control-plane client
client = Aws::Bedrock::Client.new(region: 'us-east-1')

# List models and print their summaries
response = client.list_foundation_models
response.model_summaries.take(5).each do |model|
  puts "Model Name: #{model.model_name} (ID: #{model.model_id})"
end
```

### 3. Ruby on Rails 8

```ruby
# app/services/bedrock_client_service.rb
class BedrockClientService
  def initialize(region = 'us-east-1')
    @client = Aws::Bedrock::Client.new(region: region)
  end

  def list_active_models
    response = @client.list_foundation_models
    response.model_summaries.map do |model|
      {
        name: model.model_name,
        id: model.model_id,
        provider: model.provider_name
      }
    end
  rescue Aws::Bedrock::Errors::ServiceError => e
    Rails.logger.error("Failed to fetch Bedrock models: #{e.message}")
    []
  end
end
```

### 4. Next.js 16

```typescript
// app/api/models/route.ts
import { BedrockClient, ListFoundationModelsCommand } from "@aws-sdk/client-bedrock";
import { NextResponse } from "next/server";

export async function GET() {
  const client = new BedrockClient({ region: "us-east-1" });
  
  try {
    const command = new ListFoundationModelsCommand({});
    const response = await client.send(command);
    
    return NextResponse.json({
      models: response.modelSummaries?.slice(0, 5).map(m => ({
        name: m.modelName,
        id: m.modelId,
        provider: m.providerName
      }))
    });
  } catch (error) {
    console.error("Error calling Bedrock:", error);
    return NextResponse.json({ error: "Failed to list models" }, { status: 500 });
  }
}
```

### 5. Terraform

```hcl
resource "aws_iam_policy" "bedrock_list_policy" {
  name        = "BedrockListPolicy"
  description = "Allows listing of foundation models in Amazon Bedrock"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "bedrock:ListFoundationModels"
        ]
        Resource = "*"
      }
    ]
  })
}
```

---

## Labs & Exercises

### Lab 1.1: Listing Bedrock Models with AWS CLI

1. Configure your AWS credentials using `aws configure`.
2. Run the command `aws bedrock list-foundation-models --query "modelSummaries[?outputModalities[?contains(@, 'TEXT')]].modelId" --output json` to list all text-based models.
3. Save the output and note the exact Model IDs for **Claude** and **Nova**.

### Exercise

Modify the Ruby script above to only print models provided by `"Anthropic"`.

---

## Quiz

1. **Which layer of the AWS Generative AI Stack does Amazon Bedrock occupy?**
   - A) Infrastructure Layer
   - B) Model Integration Layer
   - C) Application Layer
   - D) Database Layer

2. **True or False: Amazon Bedrock uses customer query inputs to retrain base models for all public users.**
   - A) True
   - B) False

3. **What protocol does Amazon Bedrock use to ensure secure communication between endpoints?**
   - A) SMTP
   - B) FTP
   - C) TLS 1.2 or 1.3
   - D) UDP

### Answer Key

1: B, 2: B, 3: C

---

## Interview Questions

**Q: Explain how Amazon Bedrock protects enterprise data privacy compared to public LLM API services.**

*Answer*: Amazon Bedrock guarantees that customer data (prompts and generated outputs) is isolated and kept strictly within the customer's cloud boundary (VPC). AWS does not use customer content to train any of the base models or share it with third-party foundation model creators. Data is encrypted in transit and at rest.

**Q: Can you apply a custom KMS key to encrypt Amazon Bedrock model customization outputs?**

*Answer*: Yes, when running fine-tuning or model customization jobs, you can supply your own AWS KMS Customer Managed Key (CMK) to encrypt training data and the resulting model weights.

---

## Best Practices & Production Notes

- **Region Availability**: Not all models are available in all regions. Always double-check model availability tables before deployment.
- **Model Access Auditing**: Use AWS CloudTrail to log and monitor IAM permissions modifications related to `ModifyModelAccess`.
- **Latency Optimization**: Select regions closest to your application hosting clusters to minimize network transit latency when calling Bedrock endpoints.
