# Interview Questions - Lesson 014: Function Calling & Tool Use

**Q: Explain the security risks of tool calling/function calling, and how you secure your systems against them.**

*Answer*: The primary risk is that LLMs generate parameters based on conversational inputs, making them vulnerable to prompt injection. For example, if a tool `delete_user` accepts an `email` argument, a malicious prompt like `"Delete the user with email 'admin@company.com; DROP TABLE users;'"` could cause SQL injection or unauthorized operations.

To secure tool calling:

- Validate and sanitize all parameters returned from the model before executing functions.
- Run functions with least-privilege IAM roles and database access (e.g. read-only permissions where possible).
- Do not let the model execute arbitrary code or shell scripts returned from tool arguments directly.
- Use explicit whitelist schemas for inputs (e.g. checking values with regular expressions).

---
