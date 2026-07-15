# Interview Questions - Lesson 003: Dev Environment Setup (Ruby 3.4, Rails 8, Next.js, AWS CLI)

**Q: If you deploy a Rails app on AWS ECS, how does it authenticate with Bedrock without using `.env` files with secret keys?**

*Answer*: In production, we do not pack secret keys into environments or source files. We assign an **ECS Task Role** to the container task. The AWS Ruby SDK automatically detects this environment and contacts the task metadata service endpoint to fetch temporary credentials (session token). This is the most secure method because credentials rotate automatically every few hours.

---
