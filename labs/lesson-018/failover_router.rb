require 'aws-sdk-bedrockruntime'

begin
  # Initialize Bedrock client using the user's personal profile
  client = Aws::BedrockRuntime::Client.new(
    region: 'us-east-1',
    credentials: Aws::SharedCredentials.new(profile_name: 'personal')
  )

  primary_model = 'invalid-model-id-to-force-failover'
  fallback_model = 'us.amazon.nova-micro-v1:0'
  prompt = ARGV[0] || 'Provide a 3-step production backup plan.'

  puts "Initializing High-Availability Model Router..."
  puts "Primary Model:  '#{primary_model}'"
  puts "Fallback Model: '#{fallback_model}'"
  puts "Prompt:         '#{prompt}'"
  puts "=" * 80

  messages = [{ role: 'user', content: [{ text: prompt }] }]

  begin
    # Step 1: Attempt invocation on primary endpoint
    puts "\nAttempting primary model execution..."
    response = client.converse(
      model_id: primary_model,
      messages: messages
    )
    puts "Success using primary model!"
    puts response.output.message.content[0].text

  rescue Aws::BedrockRuntime::Errors::ServiceError, StandardError => e
    # Step 2: Catch failure and route to fallback geographic profile
    puts "\n[WARNING] Primary model execution failed: #{e.class} - #{e.message}"
    puts "Redirecting traffic to fallback model: '#{fallback_model}'..."

    start_time = Time.now
    response = client.converse(
      model_id: fallback_model,
      messages: messages
    )
    end_time = Time.now
    latency_ms = ((end_time - start_time) * 1000).to_i

    puts "\nSuccess using fallback cross-region model!"
    puts "-" * 80
    puts response.output.message.content[0].text.strip
    puts "-" * 80
    puts "\nFailover Metrics:"
    puts " -> Redirect Latency: #{latency_ms} ms"
    puts " -> Target Model:     #{fallback_model}"
    puts " -> Token Count:      #{response.usage.total_tokens} tokens"
  end
  puts "=" * 80

rescue StandardError => e
  puts "\nFatal Error in router middleware: #{e.message}"
end
