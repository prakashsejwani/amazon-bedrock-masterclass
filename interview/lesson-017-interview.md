# Interview Questions - Lesson 017: Observability, Cost Tracking & Logs

**Q: Contrast how Bedrock handles observability logging natively compared to custom gateway setups on OpenAI.**

*Answer*: Bedrock provides a fully managed infrastructure-level logging engine via AWS config. By enabling **Model Invocation Logging**, all payloads are automatically intercepted at the gateway layer and securely routed to CloudWatch or S3 without modifying application source code.

OpenAI does not have a native API logging sink. Developers must implement custom middleware proxies (e.g. LiteLLM, Langfuse, Portkey, or custom API gateways) to intercept request/response payloads, which increases infrastructure complexity and introduces single points of failure.

---
