require 'aws-sdk-bedrockruntime'
require 'json'

# Pricing models (per 1 million tokens)
PRICING = {
  'amazon.nova-micro-v1:0' => { input: 0.035, output: 0.140 },
  'anthropic.claude-3-5-sonnet-20241022-v2:0' => { input: 3.00, output: 15.00 }
}

begin
  # Initialize Bedrock client using the user's personal profile
  client = Aws::BedrockRuntime::Client.new(
    region: 'us-east-1',
    credentials: Aws::SharedCredentials.new(profile_name: 'personal')
  )

  # Support choosing model
  model_id = ARGV[0] || 'amazon.nova-micro-v1:0'
  prompt = ARGV[1] || 'Explain the concept of quantum computing in one sentence.'

  unless PRICING.key?(model_id)
    puts "Error: Unsupported model. Choose either 'amazon.nova-micro-v1:0' or 'anthropic.claude-3-5-sonnet-20241022-v2:0'."
    exit 1
  end

  puts "Executing model: '#{model_id}' (Profile: personal)..."
  puts "Prompt: '#{prompt}'\n"

  start_time = Time.now

  # Execute converse query
  response = client.converse(
    model_id: model_id,
    messages: [{ role: 'user', content: [{ text: prompt }] }]
  )

  end_time = Time.now
  latency_ms = ((end_time - start_time) * 1000).to_i

  # Extract token metrics
  usage = response.usage
  input_tokens = usage.input_tokens
  output_tokens = usage.output_tokens
  total_tokens = usage.total_tokens

  # Calculate cost
  model_rates = PRICING[model_id]
  input_cost = (input_tokens / 1_000_000.0) * model_rates[:input]
  output_cost = (output_tokens / 1_000_000.0) * model_rates[:output]
  total_cost = input_cost + output_cost

  puts "Response Output:"
  puts "-" * 80
  puts response.output.message.content[0].text.strip
  puts "-" * 80
  puts "\nObservability & Cost Analysis Metrics:"
  puts "=" * 50
  puts "Input Tokens:       #{input_tokens} tokens"
  puts "Output Tokens:      #{output_tokens} tokens"
  puts "Total Tokens:       #{total_tokens} tokens"
  puts "Response Latency:   #{latency_ms} ms"
  puts "Input Billing Cost: $#{'%.8f' % input_cost} USD"
  puts "Output Billing Cost:$#{'%.8f' % output_cost} USD"
  puts "Total Invoc Cost:   $#{'%.8f' % total_cost} USD"
  puts "=" * 50

rescue Aws::BedrockRuntime::Errors::ServiceError => e
  puts "\nAWS Bedrock Runtime Error: #{e.message}"
rescue StandardError => e
  puts "\nError: #{e.message}"
end
