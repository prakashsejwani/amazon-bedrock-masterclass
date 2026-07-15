# Quiz - Lesson 014: Function Calling & Tool Use

1. **How does an LLM execute a tool?**
   - A) The model executes Python code locally inside the AWS sandbox
   - B) The model outputs structured JSON arguments identifying which tool to execute, leaving execution logic to the client code
   - C) The model requests access to the developer's command line directly
   - D) The model queries the internet via the tool schema

2. **In which Converse API message role must the `toolResult` block be submitted?**
   - A) `system`
   - B) `assistant`
   - C) `user`
   - D) `tool`

3. **What is the purpose of the `toolUseId` string property?**
   - A) It encrypts the function arguments
   - B) It acts as a correlation ID to tie the tool result back to the specific tool invocation requested by the model
   - C) It defines the billing threshold for the function execution
   - D) It specifies the IAM role required to execute the tool

## Answer Key

1: B, 2: C, 3: B

---
