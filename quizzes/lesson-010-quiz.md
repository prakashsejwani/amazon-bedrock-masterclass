# Quiz - Lesson 010: Advanced Prompt Engineering & Converse Parameters

1. **Why are XML tags specifically useful inside prompts for models like Claude and Llama?**
   - A) They are required to authenticate the request
   - B) They encrypt the user prompt
   - C) They clearly partition instructions from inputs, helping the model ignore injection attempts
   - D) They decrease network transmission sizes

2. **How should few-shot examples be structured inside the Converse API message payload?**
   - A) Inside a single string prompt
   - B) Inside the `system` parameter block
   - C) As alternating `user` and `assistant` message nodes in the `messages` array
   - D) In the `additionalModelRequestFields` config

3. **In which parameter does OpenAI accept system-level behavior instructions compared to Bedrock's root `system` array parameter?**
   - A) A message node with `role: "system"`
   - B) The `systemInstruction` parameter
   - C) The `stop` sequence block
   - D) A metadata property

## Answer Key

1: C, 2: C, 3: A

---
