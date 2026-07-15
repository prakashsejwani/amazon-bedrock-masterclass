require 'aws-sdk-bedrockruntime'
require 'json'

begin
  client = Aws::BedrockRuntime::Client.new(
    region: 'us-east-1',
    credentials: Aws::SharedCredentials.new(profile_name: 'personal')
  )

  unstructured_text = "I moved from 123 Main St, New York, NY 10001 last month. My new address is 456 Broadway Ave, Seattle, WA 98101."
  
  puts "Running extraction benchmarks (Profile: personal)..."
  puts "Source text: '#{unstructured_text}'\n"

  # 1. Zero-shot prompt
  zero_shot_prompt = <<~TEXT
    Extract all addresses from the text below. Format each as: Street, City, State, Zip.
    Text: #{unstructured_text}
  TEXT

  puts "Executing Zero-Shot Query..."
  zero_shot_response = client.converse(
    model_id: 'amazon.nova-micro-v1:0',
    messages: [{ role: 'user', content: [{ text: zero_shot_prompt }] }],
    inference_config: { temperature: 0.0, max_tokens: 150 }
  )
  puts "\nZero-Shot Output:"
  puts zero_shot_response.output.message.content[0].text
  puts "-" * 60

  # 2. Few-shot messages sequence
  few_shot_messages = [
    {
      role: 'user',
      content: [{ text: "Extract addresses from: 'Please mail the package to 789 Pine Rd, Portland, OR 97201.'" }]
    },
    {
      role: 'assistant',
      content: [{ text: "789 Pine Rd, Portland, OR, 97201" }]
    },
    {
      role: 'user',
      content: [{ text: "Extract addresses from: '#{unstructured_text}'" }]
    }
  ]

  puts "Executing Few-Shot Query..."
  few_shot_response = client.converse(
    model_id: 'amazon.nova-micro-v1:0',
    messages: few_shot_messages,
    inference_config: { temperature: 0.0, max_tokens: 150 }
  )
  puts "\nFew-Shot Output:"
  puts few_shot_response.output.message.content[0].text
  puts "=" * 60

rescue Aws::BedrockRuntime::Errors::ServiceError => e
  puts "\nAWS Bedrock Runtime Error: #{e.message}"
rescue StandardError => e
  puts "\nError: #{e.message}"
end
