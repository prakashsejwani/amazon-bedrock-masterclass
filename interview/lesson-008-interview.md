# Interview Questions - Lesson 008: Converse API (Unified Multi-turn Dialogues)

**Q: Why does the Converse API accept an array of content blocks rather than a single string?**

*Answer*: The Converse API is natively multimodal. By using an array of content blocks, a single message can support multiple input types simultaneously (e.g. passing a prompt text block, an image block, and a PDF document block). This removes the need to construct multi-part form payloads or encode images inside string templates manually.

---
