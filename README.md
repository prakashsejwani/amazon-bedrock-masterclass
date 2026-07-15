# The Ultimate Amazon Bedrock Masterclass (2026 Edition)

Welcome to the **Ultimate Amazon Bedrock Masterclass**, a comprehensive production-grade curriculum designed to take you from a cloud developer to an enterprise AI systems architect. 

This repository contains all the curriculum docs, code samples, backend APIs, client frontends, and infrastructure blueprints needed to build and scale production-ready applications with **Amazon Bedrock**.

## 📖 What is Inside?

- **Documentation Website**: A Nextra-powered developer portal.
- **Masterclass Book**: Generate Markdown, PDF, EPUB, or HTML copies of the course text.
- **Enterprise Project Capstone**: A real-world application featuring:
  - **Ruby on Rails 8** API with real-time SSE streaming.
  - **Next.js 16 (App Router)** frontend using Tailwind CSS and shadcn/ui.
  - **Terraform Infrastructure** for AWS IAM, S3, ECS, Lambda, and CloudWatch.
- **18 Detailed Lessons**: Filled with theory, architecture diagrams, labs, quizzes, and interview questions.

---

## 🗺️ Curriculum Syllabus

| Lesson | Focus Area | Technologies |
| :--- | :--- | :--- |
| **001** | [Introduction to Amazon Bedrock & Generative AI on AWS](lessons/001-introduction.md) | AWS Basics, Foundation Models |
| **002** | [AWS Console Walkthrough & Model Access Setup](lessons/002-console-walkthrough.md) | AWS Console, Model Settings |
| **003** | [Dev Environment Setup](lessons/003-dev-setup.md) | Ruby 3.4, Rails 8, Node.js, Next.js |
| **004** | Foundation Models (Claude, Nova, Llama, Mistral) | Model Selection Criteria |
| **005** | Workbench & Playgrounds | Text, Chat, Image Playgrounds |
| **006** | IAM Security, Policies, & API Access | IAM Policies, Secrets Manager |
| **007** | Bedrock Runtime API (`InvokeModel`) | Ruby SDK, Node SDK, AWS CLI |
| **008** | Converse API (Unified Multi-turn Dialogues) | Converse API, Conversational State |
| **009** | Streaming Responses with Server-Sent Events (SSE) | Rails ActionController::Live, SSE |
| **010** | Advanced Prompt Engineering & Converse Parameters | Temperature, TopP, System Prompts |
| **011** | Structured Outputs & JSON Mode | JSON Schema, Type Validation |
| **012** | Vector Embeddings & pgvector on Rails | Embeddings API, pgvector |
| **013** | Retrieval-Augmented Generation (RAG) | Bedrock Knowledge Bases, OpenSearch |
| **014** | Function Calling & Tool Use | Conversational Agents, Custom Tools |
| **015** | Agents for Amazon Bedrock | Agent Orchestration, Action Groups |
| **016** | Guardrails for Amazon Bedrock | Safety Filters, PII Masking, Blocklists |
| **017** | Monitoring, Logging, and Cost Management | CloudWatch, CloudTrail, Cost Explorer |
| **018** | Production Architecture & Scaling | ECS, Lambda, API Gateway, Terraform |

---

## 🛠️ Getting Started

### Local Setup
Clone this repository and follow the setup instructions in the lessons:

```bash
# Clone the repository
git clone https://github.com/prakashsejwani/amazon-bedrock-masterclass.git
cd amazon-bedrock-masterclass

# Follow Lesson 003 to install dependencies and run the backend/frontend services
```

## 📜 License
This project is licensed under the [MIT License](LICENSE).
