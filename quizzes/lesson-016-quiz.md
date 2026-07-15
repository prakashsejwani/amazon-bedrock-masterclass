# Quiz - Lesson 016: AI Guardrails & Safety

1. **Why is it preferred to use a Guardrail over system prompts to block forbidden topics?**
   - A) Guardrails cost less than system prompts
   - B) Guardrails run independently of model context, preventing prompt injection bypasses
   - C) Guardrails allow larger output tokens
   - D) Guardrails increase generation temperature

2. **Which stop reason is returned by the Bedrock API when a query is blocked by a guardrail policy?**
   - A) `safety_block`
   - B) `content_filter`
   - C) `guardrail_intervened`
   - D) `pii_redacted`

3. **What PII action anonymizes text inputs (e.g., replacing emails with `[EMAIL]`) instead of terminating the request?**
   - A) `BLOCK`
   - B) `ANONYMIZE`
   - C) `MASK_MD5`
   - D) `REPLACE_EMPTY`

## Answer Key

1: B, 2: C, 3: B

---
