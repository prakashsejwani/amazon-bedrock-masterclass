# Quiz - Lesson 017: Observability, Cost Tracking & Logs

1. **Which metric tracks the execution time of a Bedrock invocation model call?**
   - A) `InputTokenCount`
   - B) `InvocationLatency`
   - C) `InvocationErrorCount`
   - D) `TotalTokens`

2. **Why is it important to configure KMS encryption keys on Bedrock invocation logs?**
   - A) Without KMS, logs cannot compile
   - B) To ensure raw prompt and completion texts (which might contain sensitive user PII) are encrypted at rest
   - C) To speed up log delivery
   - D) To bypass IAM permission requirements

3. **Where are large payload logs (exceeding CloudWatch limits) routed by the logging service?**
   - A) Stored directly in the client application database
   - B) Sent to an Amazon S3 staging bucket
   - C) Dropped automatically
   - D) Forwarded to CloudTrail

## Answer Key

1: B, 2: B, 3: B

---
