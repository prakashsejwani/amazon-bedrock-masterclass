# Interview Questions - Lesson 009: Streaming Responses with Server-Sent Events (SSE)

**Q: Describe the complete order of events emitted during a Bedrock ConverseStream execution.**

*Answer*: The Bedrock service emits:

1. `MessageStartEvent`: Establishes the role.
2. `ContentBlockStartEvent`: Declares a new content block.
3. `ContentBlockDeltaEvent` (multiple times): Emits actual text chunks.
4. `ContentBlockStopEvent`: Finalizes the content block.
5. `MessageStopEvent`: Finalizes output generation and returns the stop reason.
6. `MetadataEvent`: Returns the billing data including exact input and output token usage count.

---
