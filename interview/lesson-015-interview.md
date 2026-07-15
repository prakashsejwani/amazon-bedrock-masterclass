# Interview Questions - Lesson 015: Agents & Orchestration

**Q: Explain how Amazon Bedrock Agents memory works and how sessions are maintained across multiple turns.**

*Answer*: Bedrock Agents manage session state and memory automatically at the service layer using a unique `sessionId` string supplied in the runtime request. When the client makes successive calls to `InvokeAgent` using the same `sessionId`, the service reloads the conversation history (including observations and reasoning traces) from its internal state store. This eliminates the need for developers to save message logs in local databases or pass raw historical lists in every request.

---
