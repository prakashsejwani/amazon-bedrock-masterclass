# Interview Questions - Lesson 018: Production Architecture & Scaling

**Q: Explain the Circuit Breaker pattern in LLM system architectures, and why it is critical.**

*Answer*: The Circuit Breaker pattern prevents an application from repeatedly calling an upstream service that is currently down or failing (e.g. a model experiencing a major outage or severe throttling). Instead of forcing every user request to wait for a 10-second timeout, the circuit breaker "trips" (opens) after a defined error threshold is reached. Subsequent requests immediately fail or route to a fallback endpoint (e.g. switching from Claude to Llama, or switching from Bedrock to a backup OpenAI endpoint) without hitting the broken upstream service. Once a recovery timeout expires, the circuit breaker allows a few probe requests to pass (half-open state) and fully closes if they succeed.

---
