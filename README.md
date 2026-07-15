# Enterprise AI Engineering with Amazon Bedrock (2026)

Welcome to **Enterprise AI Engineering with Amazon Bedrock (2026)**, a comprehensive production-grade curriculum designed to take you from a cloud developer to an enterprise AI systems architect.

While this course uses **Amazon Bedrock** as the primary platform, it teaches transferable architectural patterns by comparing Bedrock with **OpenAI**, **Google Cloud Vertex AI**, and **Azure AI Foundry** throughout.

## 📖 What is Inside?

- **Documentation Website**: A Nextra-powered developer portal.
- **Printable PDF & EPUB Book**: Generate beautifully formatted and styled print-ready copies of the course text.
- **Enterprise Project Capstone**: A real-world application featuring:
  - **Ruby on Rails 8** API with real-time SSE streaming.
  - **Next.js 16 (App Router)** frontend using Tailwind CSS and shadcn/ui.
  - **Terraform Infrastructure** for AWS IAM, S3, ECS, Lambda, and CloudWatch.
- **18 Detailed Lessons**: Filled with theory, cross-cloud comparison matrices, labs, quizzes, and interview questions.

---

## 🗺️ Curriculum Syllabus

| Lesson | Focus Area | Multi-Cloud Comparison Scope |
| :--- | :--- | :--- |
| **001** | [Introduction to Enterprise AI Architecture](lessons/001-introduction.md) | Bedrock vs Vertex AI vs Azure AI Foundry vs OpenAI |
| **002** | [AWS Console & Model Access Setup](lessons/002-console-walkthrough.md) | Bedrock Model Catalog vs Vertex Model Garden vs Azure Catalog |
| **003** | [Dev Environment Setup](lessons/003-dev-setup.md) | Shared credential chains (SigV4, GCP IAM, Azure Active Directory) |
| **004** | [Bedrock Foundation Models](lessons/004-models.md) | Claude vs Gemini vs GPT-4o vs Llama |
| **005** | [Workbench, Playgrounds & Evaluation](lessons/005-workbench.md) | Bedrock Workbench vs Vertex AI Prompt Management |
| **006** | [IAM Security, Policies & API Keys](lessons/006-iam.md) | IAM role assumption vs OpenAI API Keys |
| **007** | [Bedrock Runtime API (`InvokeModel`)](lessons/007-runtime-api.md) | Bedrock InvokeModel vs OpenAI completions endpoint |
| **008** | [Converse API (Multi-turn dialogues)](lessons/008-converse-api.md) | Bedrock Converse vs OpenAI Chat Completions API |
| **009** | [Streaming Responses with Server-Sent Events](lessons/009-streaming-sse.md) | Bedrock ConverseStream vs OpenAI delta chunks vs Vertex streams |
| **010** | [Advanced Prompting & Parameters](lessons/010-prompt-engineering.md) | XML tag formatting and temperature configs across clouds |
| **011** | Structured Outputs & JSON Mode | JSON Schema validations (Bedrock vs Vertex vs OpenAI) |
| **012** | Vector Embeddings & pgvector on Rails | Cohere Embed vs OpenAI Embeddings vs Vertex Embeddings |
| **013** | Retrieval-Augmented Generation (RAG) | Bedrock Knowledge Bases vs Vertex Search vs Azure Search |
| **014** | Function Calling & Tool Use | Converse API Tools vs OpenAI Function Calling |
| **015** | Agents & Orchestration | Bedrock Agents vs Vertex AI Agent Builder vs Azure Agents |
| **016** | AI Guardrails & Safety | Bedrock Guardrails vs Azure Content Safety vs Vertex Safety |
| **017** | Observability, Cost Tracking & Logs | CloudWatch vs Google Cloud Logging vs Azure Monitor |
| **018** | Production Architecture & Scaling | Hybrid ECS/Lambda/CloudRun/Azure Container Apps scaling |

---

## 🛠️ Getting Started

### Local Setup

Clone this repository and configure your credentials:

```bash
# Clone the repository
git clone https://github.com/prakashsejwani/amazon-bedrock-masterclass.git
cd amazon-bedrock-masterclass

# Configure your AWS credentials profile
aws configure --profile personal
```

Refer to [Lesson 003](lessons/003-dev-setup.md) to set up your local Ruby on Rails and Next.js developer workspaces.

## 🎥 Publication & Media Pipelines

We have automated the publishing of our course materials into PDF books and video tutorials.

### 1. Compiling the Printable PDF Book

To concatenate all 18 lessons and generate a styled, print-ready book:

```bash
python book/compile.py
```

- This compiles all chapters into `book/book.md`.
- It creates `book/book.html`, configured with margins, cover sheets, and print-breaks defined in `book/styles.css`.
- Open `book/book.html` in Chrome and use "Print to PDF" to generate a beautiful, print-ready document.

### 2. Generating Video Screencasts & AI Voiceovers

To simulate interactive browser actions, record screens, synthesize voiceover tracks, and stitch them into video files:

1. **Capture Browser Frame Sequences**:

   ```bash
   node video/screencast.js
   ```

2. **Synthesize Audio Narration Track (Amazon Polly)**:

   ```bash
   python video/voiceover.py "Welcome to Enterprise AI Engineering with Bedrock."
   ```

3. **Stitch Frames and Audio into MP4**:

   ```bash
   ./video/stitch.sh
   ```

   *Generates `video/tutorial.mp4`.*

### 3. Publishing to the NextwareSystems YouTube Channel

We utilize the YouTube Data API v3 to automate uploads:

1. Obtain your OAuth 2.0 Credentials from the Google API Console and save them to `video/client_secrets.json`.
2. Run the uploader script to publish:

   ```bash
   python video/upload_youtube.py video/tutorial.mp4 "Enterprise AI Engineering: Lesson 014" "Description of lesson..."
   ```

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).
