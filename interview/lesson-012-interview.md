# Interview Questions - Lesson 012: Vector Embeddings & pgvector on Rails

**Q: What is the benefit of Matryoshka Embeddings (supported by models like OpenAI text-embedding-3 and Amazon Titan V2)?**

*Answer*: Matryoshka representation allows you to truncate output vector dimensions (e.g. cutting a 1024-dimension vector down to 256 dimensions) without significantly degrading semantic accuracy. This allows developers to reduce database storage requirements and speed up similarity computations (fewer numbers to calculate) while retaining high retrieval performance.

---
