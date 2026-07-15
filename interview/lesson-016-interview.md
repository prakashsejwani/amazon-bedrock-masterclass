# Interview Questions - Lesson 016: AI Guardrails & Safety

**Q: Explain the difference between PII 'BLOCK' and PII 'ANONYMIZE' actions inside a Bedrock Guardrail policy, and when you use each.**

*Answer*:

- **PII BLOCK**: Immediately halts request execution. If PII (such as a credit card number) is detected, the API stops generation and returns a `stop_reason: "guardrail_intervened"`, serving the configured blocked message. Use this for high-risk data compliance constraints (e.g., stopping users from inputting raw credit card numbers or passwords).
- **PII ANONYMIZE**: Replaces the PII value in the prompt text with a generic classification label (e.g., replacing `"john@gmail.com"` with `"[EMAIL]"`) and forwards the sanitized prompt to the LLM. Use this when you still want the model to process the request (e.g., writing a summary of an email) without exposing the raw private data values.

---
