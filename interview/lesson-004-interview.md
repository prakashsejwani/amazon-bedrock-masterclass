# Interview Questions - Lesson 004: Bedrock Foundation Models (Claude, Nova, Llama, Mistral) & Model Selection

**Q: If you are building a real-time conversational agent, how would you design a multi-model pipeline to optimize cost and performance?**

*Answer*: I would employ a tiered routing strategy:

- Use a lightweight, low-cost model like **Nova Micro** for initial query intent categorization and simple information retrieval tasks.
- If the router detects that the query requires code analysis, complex reasoning, or database schema interactions, escalate the query to **Claude 3.5 Sonnet**.
- Use **Nova Lite** if the user uploads images or documents. This keeps latency low and costs optimal, reserving high-cost reasoning models only for queries that truly require them.

---
