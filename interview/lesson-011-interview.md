# Interview Questions - Lesson 011: Structured Outputs & JSON Mode

**Q: Explain how forcing structured outputs (JSON Schemas) differs from simply asking a model to "return JSON format" inside the prompt text.**

*Answer*: Asking a model to return JSON in a text prompt relies entirely on the model's instruction-following accuracy. The model can still make mistakes, such as adding markdown comments (e.g. ` ```json `), omitting keys, or outputting trailing commas.
Forcing structured outputs via schemas operates at the token-generation level. The API constraint engine alters the probability distribution of outgoing tokens to ensure that only characters forming a valid syntax structure matching the JSON Schema can be generated.

---
