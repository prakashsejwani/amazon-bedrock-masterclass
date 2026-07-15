# Interview Questions - Lesson 001: Introduction to Amazon Bedrock & Generative AI on AWS

**Q: Explain how Amazon Bedrock protects enterprise data privacy compared to public LLM API services.**

*Answer*: Amazon Bedrock guarantees that customer data (prompts and generated outputs) is isolated and kept strictly within the customer's cloud boundary (VPC). AWS does not use customer content to train any of the base models or share it with third-party foundation model creators. Data is encrypted in transit and at rest.

**Q: Can you apply a custom KMS key to encrypt Amazon Bedrock model customization outputs?**

*Answer*: Yes, when running fine-tuning or model customization jobs, you can supply your own AWS KMS Customer Managed Key (CMK) to encrypt training data and the resulting model weights.

---
