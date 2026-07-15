# Quiz - Lesson 006: IAM Security, Resource Policies, & API Keys

1. **How are Bedrock runtime API calls authenticated?**
   - A) API keys issued by Anthropic
   - B) Standard AWS IAM credentials using SigV4 request signatures
   - C) OAuth JWT tokens from Google
   - D) Local SSH keys

2. **Which model resource identifier is the most secure to use inside a production IAM policy?**
   - A) `Resource: "*"`
   - B) `Resource: "arn:aws:bedrock:us-east-1::foundation-model/*"`
   - C) `Resource: "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-5-sonnet-20241022-v2:0"`
   - D) `Resource: "arn:aws:s3:::my-bucket"`

3. **Which API action must you permit in your IAM policy to use the unified Converse interface?**
   - A) `bedrock:InvokeModel`
   - B) `bedrock:RunChat`
   - C) `bedrock:Converse`
   - D) `bedrock:StartConversation`

## Answer Key

1: B, 2: C, 3: C

---
