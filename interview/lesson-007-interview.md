# Interview Questions - Lesson 007: Bedrock Runtime API (`InvokeModel` & Streaming)

**Q: Contrast how you handle raw bytes from an InvokeModelWithResponseStream event between Anthropic Claude and Amazon Nova models.**

*Answer*: The event stream returns serialized JSON chunks. However, the schema of the decoded JSON differs:

- For **Anthropic**, chunk details contain fields like `type: "content_block_delta"` and the text is found inside `delta.text`.
- For **Amazon Nova**, the chunk returns base64-encoded bytes under `chunk.bytes` which must be base64-decoded and parsed as JSON to retrieve the text at `output.message.content[0].text`.

---
