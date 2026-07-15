# Lesson 012: Vector Embeddings & pgvector on Rails

## Objectives

- Understand the mathematical and semantic role of vector embeddings in AI systems.
- Generate text embeddings using Bedrock's Amazon Titan and Cohere Embed models.
- Compare embeddings models, pricing, and dimensions across Bedrock, OpenAI, and Vertex AI.
- Configure pgvector in Rails 8 to store embeddings and perform semantic similarity searches.

---

## Theory

Generative AI models excel at synthesis, but searching through vast repositories of corporate data requires a different tool: **Vector Embeddings**. An embedding is a high-dimensional vector (an array of floating-point numbers) representing the semantic meaning of a block of text.

When texts are converted into vectors, we can calculate the distance between them using linear algebra. Words or sentences with similar meanings will sit close to each other in this high-dimensional vector space, regardless of whether they share the same keywords.

### 1. Distance Metrics

To find semantically similar documents, vector databases calculate the distance between vectors using:

- **Cosine Similarity**: Measures the angle between two vectors. Highly effective for comparing text documents of varying lengths.
- **Euclidean Distance (L2)**: Measures the straight-line distance between two coordinates.
- **Inner Product (Dot Product)**: Computes the projection of one vector onto another. Extremely fast if vectors are normalized to unit length.

### 2. Multi-Cloud Comparison: Embeddings Landscape

| Feature / Model | Amazon Bedrock (Titan V2) | OpenAI (text-embedding-3-large) | Google Vertex AI (text-embeddings) |
| :--- | :--- | :--- | :--- |
| **Max Input Tokens** | `8,192` tokens | `8,191` tokens | `3,072` tokens |
| **Output Dimensions** | Configurable: `256`, `512`, `1024` | Configurable: `256` to `3,072` | Configurable: `128` to `768` |
| **Dimensional Tuning** | Supported natively in Titan V2 | Supported via matryoshka cuts | Supported natively |
| **Cost Profile** | Extremely Low ($0.020 / 1M) | Low ($0.130 / 1M) | Low ($0.025 / 1M) |

---

## Architecture Diagram: Vector Search Pipeline

```text
+-------------------+      1. Generate Embedding      +--------------------+
| Rails API Service | =============================> | AWS Bedrock Runtime|
| (Neighbor query)  |                                 | (SigV4 personal)   |
+-------------------+                                 +--------------------+
         ||                                                     ||
         || 3. Cosine similarity query                          || 2. Returns vector
         \/                                                     \/    e.g. [0.15, -0.89...]
+-------------------+
| PostgreSQL DB     |
| (pgvector index)  |
+-------------------+
```

---

## AWS CLI Walkthrough

### Step 1: Generating Embeddings via Titan Text V2

Generate a 1024-dimension normalized vector from a text string using your `personal` profile:

```bash
aws bedrock-runtime invoke-model \
  --model-id "amazon.titan-embed-text-v2:0" \
  --body '{"inputText":"AI Engineering on AWS","dimensions":1024,"normalize":true}' \
  --profile personal \
  response.json
```

### Step 2: Inspecting the Vector Coordinates

The output JSON file contains the raw vector array:

```json
{
  "embedding": [
    0.015243,
    -0.089201,
    0.034105,
    "..."
  ],
  "inputTextTokenCount": 5
}
```

---

## Step-by-Step Integrations

### 1. Ruby

Generate embeddings using Cohere's Multilingual Embed model:

```ruby
require 'aws-sdk-bedrockruntime'
require 'json'

client = Aws::BedrockRuntime::Client.new(
  region: 'us-east-1',
  credentials: Aws::SharedCredentials.new(profile_name: 'personal')
)

body = {
  texts: ['Artificial Intelligence is reshaping enterprise software.'],
  input_type: 'search_document'
}

response = client.invoke_model(
  model_id: 'cohere.embed-multilingual-v3',
  body: body.to_json,
  content_type: 'application/json'
)

result = JSON.parse(response.body.read)
vector = result['embeddings'][0]
puts "Generated vector dimension size: #{vector.length}"
puts "First 3 coordinates: #{vector.take(3)}"
```

### 2. Ruby on Rails 8 with pgvector

Store and query vectors in PostgreSQL using the standard `neighbor` gem.

#### Add Dependency

```ruby
# Gemfile
gem 'neighbor'
```

#### Database Migration

Create a table with a vector column (Titan Text V2 default dimension is 1024):

```ruby
class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    enable_extension "vector" # Enable pgvector extension in Postgres

    create_table :documents do |t|
      t.text :content
      t.vector :embedding, limit: 1024 # Store 1024-dimension float vectors
      t.timestamps
    end
  end
end
```

#### Rails Model

```ruby
# app/models/document.rb
class Document < ApplicationRecord
  has_neighbors :embedding # Declare neighbor vector columns

  # Callback to auto-generate embedding using Bedrock before saving
  before_save :generate_embedding, if: :content_changed?

  private

  def generate_embedding
    client = Aws::BedrockRuntime::Client.new(
      region: 'us-east-1',
      credentials: Aws::SharedCredentials.new(profile_name: 'personal')
    )

    payload = {
      inputText: content,
      dimensions: 1024,
      normalize: true
    }

    response = client.invoke_model(
      model_id: 'amazon.titan-embed-text-v2:0',
      body: payload.to_json,
      content_type: 'application/json'
    )

    result = JSON.parse(response.body.read)
    self.embedding = result['embedding']
  end
end
```

#### Performing Semantic Search

```ruby
# Querying nearest neighbors using cosine distance
query_text = "machine learning pipelines"
query_vector = generate_query_vector(query_text) # Utility method

similar_docs = Document.nearest_neighbors(:embedding, query_vector, distance: :cosine).limit(5)
similar_docs.each do |doc|
  puts "Content: #{doc.content} (Distance: #{doc.neighbor_distance})"
end
```

### 3. Next.js 16

Render a semantic search interface:

```typescript
// app/components/SemanticSearch.tsx
'use client';

import React, { useState } from 'react';

interface SearchResult {
  id: number;
  content: string;
  distance: number;
}

export default function SemanticSearch() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<SearchResult[]>([]);
  const [loading, setLoading] = useState(false);

  const handleSearch = async () => {
    setLoading(true);
    try {
      const res = await fetch(`/api/search?q=${encodeURIComponent(query)}`);
      const data = await res.json();
      setResults(data.results);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col gap-4 p-6 bg-gray-950 text-white rounded-xl border border-gray-900 max-w-md mx-auto">
      <div className="flex gap-2">
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Enter concept query..."
          className="flex-1 p-2 bg-gray-900 border border-gray-800 rounded text-sm outline-none"
        />
        <button
          onClick={handleSearch} disabled={loading}
          className="px-4 py-2 bg-blue-600 rounded text-sm font-bold"
        >
          {loading ? 'Searching...' : 'Search'}
        </button>
      </div>

      <div className="flex flex-col gap-2">
        {results.map((r) => (
          <div key={r.id} className="p-3 bg-gray-900 border border-gray-800 rounded">
            <p className="text-sm">{r.content}</p>
            <span className="text-xs text-gray-500 mt-2 block">Cosine Distance: {r.distance.toFixed(4)}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
```

### 4. Terraform

Provision a PostgreSQL database with pgvector enabled:

```hcl
resource "aws_db_instance" "postgres" {
  identifier           = "masterclass-postgres"
  engine               = "postgres"
  engine_version       = "15.4" # pgvector is supported natively on RDS Postgres 15+
  instance_class       = "db.t4g.micro"
  allocated_storage     = 20
  db_name              = "vector_db"
  username             = "db_admin"
  password             = "supersecretpassword123"
  parameter_group_name = "default.postgres15"
  skip_final_snapshot  = true
}
```

---

## Labs & Exercises

### Lab 12.1: Checking Cosine Distance Math

1. Create a script at `labs/lesson-012/cosine_distance.rb`.
2. Configure the script to load the `personal` AWS credentials profile.
3. Query Titan Text V2 to generate embeddings for:
   - `vec_a`: `"The weather is warm and sunny."`
   - `vec_b`: `"It is a hot day outside with clear skies."`
   - `vec_c`: `"Global economic markets dropped today."`
4. Implement a cosine distance calculator method in Ruby:

   ```ruby
   def dot_product(v1, v2)
     v1.zip(v2).map { |x, y| x * y }.reduce(:+)
   end
   ```

5. Calculate and print the distance between `vec_a` and `vec_b`, and `vec_a` and `vec_c` to observe semantic partitioning.

### Exercise

Extend the Rails `Document` model callback to truncate output vector dimensions to `256` elements instead of `1024` using Amazon Titan's native dimension-reduction parameter, comparing latency differences.

---

## Quiz

See [Lesson 012 Quiz](../quizzes/lesson-012-quiz.md).

## Interview Questions

See [Lesson 012 Interview Questions](../interview/lesson-012-interview.md).

## Best Practices & Production Notes

- **Dimension Limits**: Always lock your vector limits explicitly in migrations (e.g. `t.vector :embedding, limit: 1024`). Changing dimensions later requires rewriting the column and rebuilding indexes.
- **Normalization**: Always enable `"normalize": true` in Titan parameters. If vectors are normalized to unit length, cosine similarity calculations compile faster, as the denominator in the formula is simplified to 1.
- **Index Optimization**: For database collections exceeding 10,000+ entries, create an **IVFFlat** or **HNSW** vector index in PostgreSQL to avoid sequential tables scans, ensuring searches remain sub-millisecond.
