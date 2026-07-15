require 'aws-sdk-bedrockruntime'

begin
  # Initialize Bedrock client with the personal profile
  client = Aws::BedrockRuntime::Client.new(
    region: 'us-east-1',
    credentials: Aws::SharedCredentials.new(profile_name: 'personal')
  )

  prompt = ARGV[0] || "What is the primary difference between Bedrock Converse and raw InvokeModel APIs?"
  messages = [{ role: 'user', content: [{ text: prompt }] }]

  puts "Initializing ConverseStream (Profile: personal)..."
  puts "Prompt: '#{prompt}'"
  puts "=" * 80

  client.converse_stream(
    model_id: 'amazon.nova-micro-v1:0',
    messages: messages
  ) do |stream|
    stream.on_message_start do |event|
      puts "[Stream Started - Role: #{event.role}]"
    end

    stream.on_content_block_delta do |event|
      print event.delta.text
      $stdout.flush
    end

    stream.on_metadata do |event|
      puts "\n" + "=" * 80
      puts "[Stream Completed - Billing Metadata]"
      puts "Input Tokens:  #{event.usage.input_tokens}"
      puts "Output Tokens: #{event.usage.output_tokens}"
      puts "Total Tokens:  #{event.usage.total_tokens}"
      puts "Latency:       #{event.metrics.latency_ms} ms"
    end
  end

rescue Aws::BedrockRuntime::Errors::ServiceError => e
  puts "\nAWS Bedrock Runtime Error: #{e.message}"
rescue StandardError => e
  puts "\nError: #{e.message}"
end
