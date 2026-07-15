# Interview Questions - Lesson 005: Playgrounds, Workbench, & Model Evaluation

**Q: If your model output is cut off midway through a sentence, which inference parameter should you check first?**

*Answer*: The first parameter to check is **Max Tokens (or Max Output Length)**. If this parameter value is set too low, the model will cease generation once the output tokens limit is hit. You should increase this value or inspect the Stop Sequences parameter to ensure it is not triggering premature terminations.

---
