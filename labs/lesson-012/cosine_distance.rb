require 'aws-sdk-bedrockruntime'
require 'json'

# Math helpers for vectors
def dot_product(v1, v2)
  v1.zip(v2).map { |x, y| x * y }.reduce(:+)
end

def magnitude(v)
  Math.sqrt(v.map { |x| x**2 }.reduce(:+))
end

def cosine_similarity(v1, v2)
  dot_product(v1, v2) / (magnitude(v1) * magnitude(v2))
end

begin
  # Initialize Bedrock client with the personal credentials profile
  client = Aws::BedrockRuntime::Client.new(
    region: 'us-east-1',
    credentials: Aws::SharedCredentials.new(profile_name: 'personal')
  )

  texts = {
    a: "The weather is warm and sunny.",
    b: "It is a hot day outside with clear skies.",
    c: "Global economic markets dropped today."
  }

  puts "Generating Titan Text V2 Embeddings (Profile: personal)..."
  embeddings = {}

  texts.each do |key, text|
    puts "Text [#{key}]: '#{text}'"
    payload = {
      inputText: text,
      dimensions: 1024,
      normalize: true
    }

    response = client.invoke_model(
      model_id: 'amazon.titan-embed-text-v2:0',
      body: payload.to_json,
      content_type: 'application/json'
    )

    result = JSON.parse(response.body.read)
    embeddings[key] = result['embedding']
  end

  # Calculate distances
  sim_ab = cosine_similarity(embeddings[:a], embeddings[:b])
  sim_ac = cosine_similarity(embeddings[:a], embeddings[:c])

  puts "\nSimilarity Benchmarks (higher is closer):"
  puts "=" * 60
  puts "Similarity (A to B - Sunny vs Hot Day):     #{sim_ab.round(4)}"
  puts "Similarity (A to C - Sunny vs Economics):   #{sim_ac.round(4)}"
  puts "\nCosine Distance (1 - Similarity):"
  puts "Distance A to B: #{(1.0 - sim_ab).round(4)} (Closer semantic space)"
  puts "Distance A to C: #{(1.0 - sim_ac).round(4)} (Farther semantic space)"

rescue Aws::BedrockRuntime::Errors::ServiceError => e
  puts "\nAWS Bedrock Runtime Error: #{e.message}"
rescue StandardError => e
  puts "\nError: #{e.message}"
end
