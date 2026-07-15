# Lesson 002: AWS Console Walkthrough & Model Access Setup

## Objectives

- Learn how to request and manage model access in the AWS Bedrock Console.
- Navigate the Bedrock Playgrounds (Text, Chat, Image) and the Model Evaluation workbench.
- Understand the region-specific availability of foundation models.
- Set up logging for model invocation in your AWS account.

---

## Theory

Before a developer or program can invoke a model on Amazon Bedrock, access must be explicitly granted for that model in your AWS Account. FMs are supplied by independent companies, some of which require you to agree to specific EULAs (End User License Agreements) or provide contact details before using their services.

### Region-Specific Availability

Amazon Bedrock does not host all models in all regions. AWS continuously rolls out models, meaning regions like `us-east-1` (N. Virginia) and `us-west-2` (Oregon) usually get access to new models first. When designing your deployment architecture, ensure the region hosting your application is identical to or has a low-latency connection to the region where your chosen model is enabled.

### Playground vs. Workbench vs. Endpoint

- **Playgrounds**: Interactive browser-based interfaces inside the AWS Console. Great for rapid prototyping, prompt engineering testing, and immediate evaluation.
- **Model Evaluation (Workbench)**: A workflow to evaluate and compare different models based on accuracy, robustness, toxicity, and speed, using either automatic datasets or human reviewers.
- **API Endpoint**: The programmable API server exposed by AWS Bedrock for production code integration.

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

### Step 1: Navigating to Model Access

1. Open the **AWS Management Console**.
2. Search for **Amazon Bedrock** and select it.
3. On the left side navigation, click on **Model access**.
4. You will see a table displaying all foundation models, their providers, and your current access status.

![AWS Console - Bedrock Model Access](/assets/screenshots/002_model_access.png)
*(Note: Please save a screenshot of your Model Access page at assets/screenshots/002_model_access.png to complete this walkthrough).*

### Step 2: Requesting Access

1. Click **Modify model access** in the top right.
2. Check the box next to **Anthropic Claude 3** and **Amazon Nova**.
3. Scroll to the bottom and click **Next**.
4. Review the terms and conditions, then click **Submit**.
5. The status next to your checked models will update to **Access granted**.

### Step 3: Using the Chat Playground

1. In the left navigation, under **Playgrounds**, click **Chat**.
2. Click **Select model** at the top.
3. Set Category to **Anthropic** and Model to **Claude 3.5 Sonnet**, then click **Apply**.
4. Type a message in the chat input and click **Run**.
5. Observe the response latency and token count details.

---

## Step-by-Step Integrations

### 1. AWS CLI

You can query metadata and limits (such as max output tokens and input support) for a specific model ID:

```bash
aws bedrock get-foundation-model --model-identifier anthropic.claude-3-5-sonnet-20241022-v2:0 --region us-east-1
```

### 2. Ruby

Retrieve details for a specific model to verify its parameters programmatically:

```ruby
require 'aws-sdk-bedrock'

client = Aws::Bedrock::Client.new(region: 'us-east-1')

begin
  response = client.get_foundation_model(
    model_identifier: 'anthropic.claude-3-5-sonnet-20241022-v2:0'
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
  const modelId = searchParams.get("modelId") || "amazon.nova-lite-v1:0";

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

1. Run the command: `aws bedrock get-foundation-model --model-identifier amazon.nova-lite-v1:0 --region us-east-1`
2. Check the output fields `responseStreamingSupported` and `customizationsSupported`.
3. Note if this model supports continuous stream generation.

### Exercise

Navigate to the AWS Console, open the Model Access page, and request access to **Meta Llama 3.3 70B Instruct**.

---

## Quiz

1. **Why might a model fail to run in region `eu-central-1` even though it is active in `us-east-1`?**
   - A) AWS Bedrock has different credentials per region
   - B) Models are rolled out to regions incrementally based on AWS GPU updates
   - C) You must register a separate billing profile per region
   - D) Anthropic only operates in US regions

2. **In which tool can you evaluate and compare models on accuracy and response speeds?**
   - A) Model Access Console
   - B) Chat Playground
   - C) Model Evaluation Workbench
   - D) CloudWatch Logs

3. **Which IAM action must be explicitly denied to prevent users from requesting new model accesses?**
   - A) `bedrock:GetFoundationModel`
   - B) `bedrock:ModifyModelAccess`
   - C) `bedrock:InvokeModel`
   - D) `bedrock:ListFoundationModels`

### Answer Key

1: B, 2: C, 3: B

---

## Interview Questions

**Q: If your backend returns an AccessDeniedException when calling `InvokeModel`, what are the first three things you should investigate?**

*Answer*:

1. Check if the model access has been requested and granted in the Bedrock Console for that specific region.
2. Verify that the IAM Role or User calling the API has `bedrock:InvokeModel` permission for that model resource.
3. Verify that the correct AWS Region is specified in your client configuration.

---

## Best Practices & Production Notes

- **Access Segregation**: In multi-account enterprise structures, configure sandbox accounts with open model access for R&D, but restrict production accounts to only approved model IDs.
- **Cost Tracking**: Request model access only for models that fit your security and cost parameters. Active models in your list do not cost anything unless invoked, but restriction prevents accidental high-cost model usage by developers.
