# Interview Questions - Lesson 013: Retrieval-Augmented Generation (RAG) & Knowledge Bases

**Q: Explain how you prevent hallucinations in a RAG pipeline deployed on Amazon Bedrock.**

*Answer*: Halucinations in RAG occur when the model answers queries using its internal training weights instead of the retrieved document context.

To prevent this:

- Enforce strict system prompt guidelines (e.g., `"You are only allowed to answer questions using the provided context. If the answer is not present, state 'I cannot find the answer in the provided documents'"`).
- Set Temperature to `0.0` to force deterministic matching.
- Track retrieval relevance scores (e.g., only pass documents into prompt context if their cosine similarity score exceeds `0.75`).
- Parse citation locations to display exactly which source document URL verified the output text block.

---
