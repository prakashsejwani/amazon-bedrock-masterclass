# Lesson 013: Retrieval-Augmented Generation (RAG) & Knowledge Bases

## Objectives

- Understand the architectural mechanics of Retrieval-Augmented Generation (RAG).
- Configure and sync data sources with Amazon Bedrock Knowledge Bases.
- Compare RAG architectures across Amazon Bedrock, OpenAI Assistants, and Google Vertex AI Search.
- Query Knowledge Bases programmatically using `Retrieve` and `RetrieveAndGenerate` APIs.
- Build a citation-aware RAG search interface in Rails 8 and Next.js 16.

---

## Theory

LLMs are frozen in time once trained. They do not know about your private company databases, internal documentation, or real-time event updates. **Retrieval-Augmented Generation (RAG)** solves this by retrieving relevant text segments from an external database matching the user's query, and prepending those segments into the LLM's prompt context window to generate a factually accurate, grounded response.

### 1. Bedrock Knowledge Bases Core Components

Amazon Bedrock Knowledge Bases automates the entire RAG pipeline:

- **Data Sources**: Stored in Amazon S3. Supports documents (PDFs, TXT, HTML, Word, CSV) and multimodal media files.
- **Document Parser**: Processes documents into clean text. Supports the *Bedrock Default Parser*, *Bedrock Data Automation (BDA)* (for audio/video/image extraction), and *Foundation Model Parser* (for complex document layouts like tables).
- **Chunking Strategy**: Divides parsed text into digestible segments. Supports:
  - **Fixed-size chunking**: Standard blocks with token overlaps.
  - **Hierarchical chunking**: Splits documents into parent/child structures for fine-grained retrieval with wide context.
  - **Semantic chunking**: Splits documents based on shifts in semantic meaning.
- **Vector Database**: Indexes the generated document vector coordinates. Supports *Amazon OpenSearch Serverless*, *Pinecone*, *Redis Enterprise Cloud*, and *Amazon Aurora PostgreSQL (pgvector)*.

### 2. Multi-Cloud Comparison: RAG Ecosystems

| RAG Capability | Amazon Bedrock (Knowledge Bases) | OpenAI (Assistants File Search) | Google Vertex AI (Search / Vector Search) |
| :--- | :--- | :--- | :--- |
| **Ingestion Pipeline** | Fully managed (Sync triggers embedding/indexing) | Automated via vector stores upload | Fully managed with Google Drive/Cloud Storage connectors |
| **Reranking Support** | Built-in via Cohere Rerank models | Internal vector similarity scoring | Integrated Vertex AI Reranking API |
| **API Abstractions** | Separated: `Retrieve` (chunks only) vs `RetrieveAndGenerate` (compositions) | Combined: File Search tool executes automatically inside Threads | Separated: Vector search indexes vs Vertex AI Search endpoints |
| **Structured Datastores** | Natively supports Redshift SQL conversions | Not supported | BigQuery table grounding connectors |

---

## Architecture Diagram: Retrieve vs. RetrieveAndGenerate

```text
       +--------------------------------------------------------------+
       |                         USER QUERY                           |
       +--------------------------------------------------------------+
                                       ||
                                       \/
                    +---------------------------------------+
                    |    Aws::BedrockAgentRuntime::Client   |
                    +---------------------------------------+
                     //                                   \\
                    // 1. Retrieve API                     \\ 2. RetrieveAndGenerate API
                   //                                       \\
+----------------------------------------+       +---------------------------------------+
| Query Vector Database & return raw     |       | 1. Query Vector Database for chunks.  |
| matching text chunks + citations.      |       | 2. Passes chunks to LLM to compose    |
+----------------------------------------+       |    grounded chat answer.              |
                                                 +---------------------------------------+
```

---

## AWS CLI Walkthrough

### Step 1: Performing Raw Retrieval

Query your knowledge base to return matching document chunks without generating a conversational answer. Run this command using the `personal` profile:

```bash
aws bedrock-agent-runtime retrieve \
  --knowledge-base-id "KBID123456" \
  --retrieval-query text="What is our standard remote work policy?" \
  --profile personal
```

### Step 2: Evaluating the Citation Output

The CLI returns an array of matched text blocks:

```json
{
  "retrievalResults": [
    {
      "content": {
        "text": "Employees are permitted to work remotely up to 3 days per week with manager approval..."
      },
      "location": {
        "s3Location": {
          "uri": "s3://my-company-docs/policies/remote_work.pdf"
        },
        "type": "S3"
      },
      "score": 0.892
    }
  ]
}
```

### Step 3: Executing Grounded Q&A

Submit a query that retrieves matching documentation and forwards it to Claude 3.5 Sonnet to compose an answer:

```bash
aws bedrock-agent-runtime retrieve-and-generate \
  --input text="Summarize our remote work rules." \
  --retrieve-and-generate-configuration '{"type":"KNOWLEDGE_BASE","knowledgeBaseConfiguration":{"knowledgeBaseId":"KBID123456","modelArn":"arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-5-sonnet-20241022-v2:0"}}' \
  --profile personal
```

The output contains the final grounded text inside the `output.text` parameter along with specific source references.

---

## Step-by-Step Integrations

### 1. Ruby

Initialize the `BedrockAgentRuntime` client to perform grounded document generation:

```ruby
require 'aws-sdk-bedrockagentruntime'
require 'json'

client = Aws::BedrockAgentRuntime::Client.new(
  region: 'us-east-1',
  credentials: Aws::SharedCredentials.new(profile_name: 'personal')
)

response = client.retrieve_and_generate(
  input: {
    text: 'What are the rules for business expense reimbursements?'
  },
  retrieve_and_generate_configuration: {
    type: 'KNOWLEDGE_BASE',
    knowledge_base_configuration: {
      knowledge_base_id: 'KBID123456',
      model_arn: 'arn:aws:bedrock:us-east-1::foundation-model/amazon.nova-micro-v1:0'
    }
  }
)

puts "Grounded Answer:"
puts response.output.text
```

### 2. Ruby on Rails 8

Implement a controller action to retrieve chunks and return them along with their source document URIs:

```ruby
# app/controllers/rag_searches_controller.rb
class RagSearchesController < ApplicationController
  def search
    client = Aws::BedrockAgentRuntime::Client.new(
      region: 'us-east-1',
      credentials: Aws::SharedCredentials.new(profile_name: 'personal')
    )

    response = client.retrieve(
      knowledge_base_id: ENV.fetch('BEDROCK_KB_ID'),
      retrieval_query: {
        text: params[:query]
      },
      retrieval_configuration: {
        vector_search_configuration: {
          number_of_results: 3
        }
      }
    )

    results = response.retrieval_results.map do |res|
      {
        text: res.content.text,
        source: res.location.s3_location.uri,
        score: res.score
      }
    end

    render json: { results: results }
  end
end
```

### 3. Next.js 16

Dynamic chat component displaying citations alongside the generated answer:

```typescript
// app/components/RagChat.tsx
'use client';

import React, { useState } from 'react';

interface Citation {
  text: string;
  source: string;
  score: number;
}

export default function RagChat() {
  const [query, setQuery] = useState('');
  const [answer, setAnswer] = useState('');
  const [citations, setCitations] = useState<Citation[]>([]);
  const [loading, setLoading] = useState(false);

  const handleQuery = async () => {
    setLoading(true);
    setAnswer('');
    setCitations([]);

    try {
      const res = await fetch(`/api/rag-query?q=${encodeURIComponent(query)}`);
      const data = await res.json();
      setAnswer(data.answer);
      setCitations(data.citations || []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col gap-4 p-6 bg-gray-950 text-white rounded-xl border border-gray-900 max-w-xl mx-auto">
      <div className="flex gap-2">
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Ask corporate policy question..."
          className="flex-1 p-2 bg-gray-900 border border-gray-800 rounded text-sm"
        />
        <button
          onClick={handleQuery} disabled={loading}
          className="px-4 py-2 bg-blue-600 rounded text-sm font-bold"
        >
          {loading ? 'Thinking...' : 'Ask'}
        </button>
      </div>

      {answer && (
        <div className="p-4 bg-gray-900 rounded border border-gray-800 text-sm">
          <p className="font-semibold text-blue-400 mb-2">Answer:</p>
          <p className="leading-relaxed whitespace-pre-wrap">{answer}</p>
        </div>
      )}

      {citations.length > 0 && (
        <div className="flex flex-col gap-2">
          <p className="text-xs text-gray-500 font-bold">Source References:</p>
          {citations.map((c, idx) => (
            <div key={idx} className="p-3 bg-gray-900/60 border border-gray-800/80 rounded text-xs">
              <p className="text-gray-300 italic">"...{c.text}..."</p>
              <span className="text-blue-500 block mt-2">Source: {c.source} (Match: {c.score.toFixed(2)})</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
```

### 4. Terraform

IAM role policy statement enabling Bedrock to assume permissions to sync S3 buckets and query OpenSearch Serverless:

```hcl
resource "aws_iam_role" "bedrock_kb_role" {
  name = "bedrock-kb-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "kb_s3_policy" {
  name = "bedrock-kb-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::my-company-docs",
          "arn:aws:s3:::my-company-docs/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kb_attach" {
  role       = aws_iam_role.bedrock_kb_role.name
  policy_arn = aws_iam_policy.kb_s3_policy.arn
}
```

---

## Labs & Exercises

### Lab 13.1: Running a Document Query loop

1. Create a script at `labs/lesson-013/query_kb.rb`.
2. Configure the script to verify your `personal` AWS credentials profile.
3. Accept query input parameters from terminal arguments: `ruby query_kb.rb "remote work"`.
4. Perform a `retrieve` call and print the text content of the top-ranked chunk alongside its score.

### Exercise

Extend the Rails `RagSearchesController` to filter incoming results based on metadata attributes (e.g. only returning documents where the source file path prefix matches a specific department category).

---

## Quiz

1. **What is the difference between the `Retrieve` and `RetrieveAndGenerate` APIs?**
   - A) `Retrieve` is faster; `RetrieveAndGenerate` is cheaper
   - B) `Retrieve` only returns relevant document blocks; `RetrieveAndGenerate` retrieves blocks and uses an LLM to formulate an answer
   - C) `Retrieve` only works on text; `RetrieveAndGenerate` only works on images
   - D) `Retrieve` does not use a vector store

2. **Which chunking strategy splits documents based on conceptual changes in topic rather than token length boundaries?**
   - A) Fixed-size chunking
   - B) Hierarchical chunking
   - C) Semantic chunking
   - D) SQL mapping chunking

3. **Which AWS client namespace must be instantiated to query Knowledge Bases?**
   - A) `Aws::Bedrock::Client`
   - B) `Aws::BedrockRuntime::Client`
   - C) `Aws::BedrockAgentRuntime::Client`
   - D) `Aws::STS::Client`

### Answer Key

1: B, 2: C, 3: C

---

## Interview Questions

**Q: Explain how you prevent hallucinations in a RAG pipeline deployed on Amazon Bedrock.**

*Answer*: Halucinations in RAG occur when the model answers queries using its internal training weights instead of the retrieved document context.

To prevent this:

- Enforce strict system prompt guidelines (e.g., `"You are only allowed to answer questions using the provided context. If the answer is not present, state 'I cannot find the answer in the provided documents'"`).
- Set Temperature to `0.0` to force deterministic matching.
- Track retrieval relevance scores (e.g., only pass documents into prompt context if their cosine similarity score exceeds `0.75`).
- Parse citation locations to display exactly which source document URL verified the output text block.

---

## Best Practices & Production Notes

- **Ingestion Synchronizations**: Adding files to an S3 bucket does not immediately index them in the database. You must call the `StartIngestionJob` API to sync the data source.
- **Reranker Latency Trade-Off**: Adding a reranking step (such as Cohere Rerank) increases context accuracy, but adds 100–300ms of latency to the API request. Use it only when retrieval accuracy is highly critical.
- **Vector Index Scaling**: For large vector databases, split your content sources across multiple document data source prefixes to speed up indexing sweeps and reduce search latency.
