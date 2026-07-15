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

### 1. Credentials Configuration

Clone the repository and set up your AWS credentials named profile:

```bash
# Clone the repository
git clone https://github.com/prakashsejwani/amazon-bedrock-masterclass.git
cd amazon-bedrock-masterclass

# Configure your personal developer credentials profile
aws configure --profile personal
```

### 2. Running Rails & Next.js (Node.js) Together

To run the full stack locally with active AI integration integrations:

#### Terminal 1: Ruby on Rails 8 Backend API

```bash
cd code/rails

# Install server dependencies
bundle install

# Run database migrations
bundle exec rails db:migrate

# Start the Rails API server on port 3001
bundle exec rails server -p 3001
```

#### Terminal 2: Next.js 16 (Node.js) Frontend Client

```bash
cd code/nextjs

# Install node dependencies
npm install

# Start the Next.js development server
npm run dev
```

Open your browser and navigate to `http://localhost:3000`. The frontend will communicate directly with the Rails API backend running at `http://localhost:3001`.

---

### 3. Under the Hood: How the AI Integration Works

```text
+-------------------+                    +--------------------+                    +======================+
| Next.js Client UI | =================> | Rails Backend API  | =================> |  AWS Bedrock Gateway |
| (Port 3000)       |   Converse Query   | (Port 3001)        |   SigV4 API Call   | (Virginia / Oregon)  |
+-------------------+                    +--------------------+                    +======================+
          ^                                        ||                                         ||
          ||                                       ||                                         ||
          ||                                       \/                                         \/
          ||                              +--------------------+                     +--------------------+
          ||                              | AWS SDK Client     | <================== | Response Stream    |
          =============================== | (SigV4 Personal)   |  Server-Sent Events | (Model Completion) |
                Token Delta Streams       +--------------------+                     +--------------------+
```

1. **User Action**: When you input a chat prompt, trigger a security safety check, or run an orchestration task, the Next.js client initiates a `POST` request to the Rails API backend.
2. **SigV4 Authentication**: The Rails app instantiates the AWS SDK client, loads your local `personal` profile credentials, and automatically formats, signs, and authorizes the HTTP query using the **AWS Signature Version 4 (SigV4)** signing standard.
3. **Bedrock Invocations**: The query is sent to Amazon Bedrock endpoints (e.g. `converse` or `invoke_agent`). Bedrock processes the query, applying Guardrail checks and RAG retrieval pipelines natively.
4. **Server-Sent Events (SSE)**: Bedrock streams the response tokens back to Rails. The Rails controller intercepts this stream and proxies it in real time to the Next.js client browser using standard **Server-Sent Events (SSE)**.

---

### 4. Deploying to Production on AWS (Amazon Bedrock)

When ready to transition from local development to AWS, follow this production architecture:

```text
+--------------+      HTTPS       +---------------------+      Private IP      +------------------------+
|  User Client | ===============> | Application Load    | ===================> | ECS Tasks (AWS Fargate)|
|  (Browser)   |                  | Balancer (ALB)      |                      | (Rails & Next.js)      |
+--------------+                  +---------------------+                      +------------------------+
                                                                                           ||
                                                                                           || KMS / IAM Auth
                                                                                           \/
+----------------------+          +----------------------+                     +========================+
| Amazon RDS Postgres  | <======= | Amazon S3 Audit      | <================== | AWS Bedrock Service    |
| (pgvector enabled)   |   VPC    | (KMS Encrypted logs) |                     | (Models/Agents/Guard)  |
+----------------------+          +----------------------+                     +========================+
```

#### A. Containerizing the Runtimes

- Build and push Docker images for `code/rails` and `code/nextjs` to **Amazon Elastic Container Registry (ECR)**.
- Deploy the container instances to **Amazon Elastic Container Service (ECS)** on **AWS Fargate** or **AWS App Runner** for serverless scaling.

#### B. Provisioning Databases

- Deploy an **Amazon RDS PostgreSQL** instance inside your private VPC.
- Enable the **`pgvector` extension** to host high-dimensional semantic search indexes for RAG integrations.

#### C. Setting up IAM Policies

Attach an **IAM Task Role** directly to your ECS Tasks. Never hardcode access keys. The Task Role must allow access to Bedrock APIs:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream",
        "bedrock:Retrieve",
        "bedrock:InvokeAgent"
      ],
      "Resource": "*"
    }
  ]
}
```

#### D. Logging & Auditing

- Enable **Model Invocation Logging** pointing to an Amazon S3 bucket encrypted with AWS KMS.
- Pipe execution logs to Amazon CloudWatch for error rates monitoring and latency alerts.

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
