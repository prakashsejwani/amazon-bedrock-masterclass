# Lesson 002: AWS Console Walkthrough & Model Access Setup

## Objectives

- Learn how to request and manage model access in the AWS Bedrock Console.
- Navigate the Bedrock Model Catalog, Playgrounds, and the Model Evaluation workbench.
- Understand Project-level and Account-level scopes inside Bedrock.
- Analyze model specifications (context window, input/output limits, modalities, and pricing) from the catalog.

---

## Theory

Before a developer or program can invoke a model on Amazon Bedrock, access must be explicitly granted for that model in your AWS Account. FMs are supplied by independent companies, some of which require you to agree to specific EULAs (End User License Agreements) or provide contact details before using their services.

### Project-level Scopes in Bedrock

Project scope allows developers to partition AI development resources, benchmarks, custom dashboards, and local playgrounds inside separate folders (like `default` or customized application projects).

### Catalog Metadata

The Bedrock Model Catalog acts as a centralized directory. Each model card in the catalog presents crucial developer parameters:

- **Context Window**: The maximum input length the model can process.
- **Max Output**: The maximum response length supported.
- **Input/Output Pricing**: The cost calculated per 1 million tokens.
- **Modalities**: The supported input/output formats (e.g. Text, Image, Video).

---

## Architecture Diagram

The model access request and invocation control flow:

```text
+-------------------+      1. Check IAM Policies      +--------------------+
| Developer / App   | =============================> | AWS IAM Access Gate|
+-------------------+                                 +--------------------+
         ||                                                     ||
         || 2. Request Model Access                             || (Checks Permissions)
         \/                                                     \/
+-------------------+      3. Request Execution       +--------------------+
| Bedrock Console   | =============================> | AWS Bedrock Engine |
| (Model Access UI) |                                 | (Model Access List)|
+-------------------+                                 +--------------------+
```

---

## AWS Console Walkthrough

### Step 1: Navigating the Model Catalog

1. Open the **AWS Management Console**.
2. Search for **Amazon Bedrock** and select it.
3. In the left navigation sidebar under **Project Scope**, verify your active project (e.g., select `default` project).
4. Click on the **Models** link. You will land on the **Model catalog** showing the active models page.

![AWS Console - Bedrock Model Catalog](/assets/screenshots/002_model_access.png)

### Step 2: Evaluating Model Specifications

When selecting a model (such as the **GLM 5** card from provider **Z.AI**), a detailed specifications drawer will open on the right side showing:

- **Model ID**: `zai.glm-5`
- **Context Window**: `200K tokens`
- **Max Output**: `128K tokens`
- **Pricing**: `$1.20 / 1M tokens` input, `$3.84 / 1M tokens` output.
- **Description**: Optimized for complex systems engineering, math, coding, and long-context agentic tasks.

Other models available in the catalog include:

- **Palmyra Vision 7B** (Multimodal: Text + Image input, text output; 4K context; $0.18/1M input).
- **Qwen3 Coder Next** (Text-only; 256K context; $0.60/1M input).
- **GLM 4.7 Flash** (Text-only; 203K context; $0.08/1M input).
- **Kimi K2.5** (Multimodal: Text + Image input; 256K context; $0.72/1M input).

### Step 3: Requesting Access

1. Under the **Account Scope** section of the sidebar, select **Settings** or **Model access** (depending on your AWS region layout).
2. Click **Modify model access** or **Enable model**.
3. Select your chosen model (e.g. check the boxes next to `zai.glm-5` or `amazon.nova-lite-v1:0`).
4. Click **Save changes** / **Submit** to grant access for your project scope.

---

## Step-by-Step Integrations

### 1. AWS CLI

You can query metadata and limits (such as max output tokens and input support) for a specific model ID from the catalog:

```bash
aws bedrock get-foundation-model --model-identifier zai.glm-5 --region us-east-1
```

### 2. Ruby

Retrieve details for a specific model to verify its parameters programmatically:

```ruby
require 'aws-sdk-bedrock'

client = Aws::Bedrock::Client.new(region: 'us-east-1')

begin
  response = client.get_foundation_model(
    model_identifier: 'zai.glm-5'
  )
  details = response.model_details
  puts "Model: #{details.model_name}"
  puts "Input Modalities: #{details.input_modalities.join(', ')}"
  puts "Output Modalities: #{details.output_modalities.join(', ')}"
rescue Aws::Bedrock::Errors::ServiceError => e
  puts "Failed to retrieve model details: #{e.message}"
end
```

### 3. Ruby on Rails 8

A service method to verify model access rights prior to processing text requests:

```ruby
# app/services/model_auditor_service.rb
class ModelAuditorService
  def initialize(region = 'us-east-1')
    @client = Aws::Bedrock::Client.new(region: region)
  end

  def model_supported?(model_id)
    response = @client.get_foundation_model(model_identifier: model_id)
    response.model_details.present?
  rescue Aws::Bedrock::Errors::ValidationException
    false
  rescue => e
    Rails.logger.error("Audit error: #{e.message}")
    false
  end
end
```

### 4. Next.js 16

Check model metadata details from a Next.js endpoint:

```typescript
// app/api/model-check/route.ts
import { BedrockClient, GetFoundationModelCommand } from "@aws-sdk/client-bedrock";
import { NextResponse } from "next/server";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const modelId = searchParams.get("modelId") || "zai.glm-5";

  const client = new BedrockClient({ region: "us-east-1" });

  try {
    const command = new GetFoundationModelCommand({ modelIdentifier: modelId });
    const response = await client.send(command);

    return NextResponse.json({
      modelName: response.modelDetails?.modelName,
      customizationsSupported: response.modelDetails?.customizationsSupported,
      maxOutputTokens: response.modelDetails?.responseStreamingSupported
    });
  } catch (error) {
    return NextResponse.json({ error: "Model lookup failed" }, { status: 404 });
  }
}
```

### 5. Terraform

Ensure standard developers are allowed to view model attributes but blocked from requesting model access:

```hcl
resource "aws_iam_policy" "developer_read_only_policy" {
  name        = "BedrockDeveloperReadOnlyPolicy"
  description = "Allows developers to read model metadata but blocks model access modification"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "bedrock:GetFoundationModel",
          "bedrock:ListFoundationModels"
        ]
        Resource = "*"
      },
      {
        Effect   = "Deny"
        Action   = [
          "bedrock:ModifyModelAccess"
        ]
        Resource = "*"
      }
    ]
  })
}
```

---

## Labs & Exercises

### Lab 2.1: Querying Model Capabilities via CLI

1. Run the command: `aws bedrock get-foundation-model --model-identifier zai.glm-5 --region us-east-1`
2. Check the output fields `responseStreamingSupported` and `customizationsSupported`.
3. Note if this model supports continuous stream generation.

### Exercise

Navigate to the AWS Console, open the Model Catalog, and locate the details for **Qwen3 Coder Next**. Record its context window and pricing structure.

---

## Quiz

1. **Which context window size is reported for `zai.glm-5`?**
   - A) 4K tokens
   - B) 203K tokens
   - C) 200K tokens
   - D) 256K tokens

2. **In the Model Catalog view, what does the input price represent?**
   - A) The cost per single model call
   - B) The cost calculated per 1 million input tokens
   - C) The monthly hosting fee for the model
   - D) The cost per generated word

3. **What is the project-level dropdown scope seen in the modern Bedrock sidebar?**
   - A) Region Selector
   - B) Project Scope (e.g. `default` project)
   - C) Billing Account Scope
   - D) IAM Role selector

### Answer Key

1: C, 2: B, 3: B

---

## Interview Questions

**Q: In the Bedrock Console, how does project scope differ from account scope?**

*Answer*: Project scope allows developers to partition AI development resources, benchmarks, custom dashboards, and local playgrounds inside separate folders (like `default` or customized application projects). Account scope refers to global configurations such as model access enablement, account-wide logging, billing, and global settings across the entire AWS account.

---

## Best Practices & Production Notes

- **Model Selection Audits**: Regularly audit your model catalog configurations. Lightweight models like GLM 4.7 Flash or Qwen3 Coder offer lower latency and costs, which should be used unless complex reasoning capabilities of frontier models (like GLM 5 or Claude 3.5 Sonnet) are required.
- **Monitoring Project Usage**: Make sure to tag and structure your Bedrock API keys under the appropriate project scope to ensure billing is allocated to the correct microservice or business unit.
