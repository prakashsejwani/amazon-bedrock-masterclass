require 'aws-sdk-bedrockruntime'
require 'json'

begin
  # Initialize Bedrock client using the user's personal profile
  client = Aws::BedrockRuntime::Client.new(
    region: 'us-east-1',
    credentials: Aws::SharedCredentials.new(profile_name: 'personal')
  )

  # Maintain history array
  history = []
  system_prompt = [{ text: "You are a concise engineering assistant. Limit your answers to 2 sentences." }]

  puts "Bedrock Converse API Chat Loop (Profile: personal)"
  puts "Type 'exit' or 'quit' to end the conversation."
  puts "=" * 60

  loop do
    print "\nYou: "
    input = $stdin.gets.chomp.strip
    break if input.downcase == 'exit' || input.downcase == 'quit'
    next if input.empty?

    # Append user turn
    history << {
      role: 'user',
      content: [{ text: input }]
    }

    print "Assistant: "
    
    # Query Bedrock using converse API
    response = client.converse(
      model_id: 'amazon.nova-micro-v1:0',
      messages: history,
      system: system_prompt,
      inference_config: { max_tokens: 200, temperature: 0.7 }
    )

    assistant_text = response.output.message.content[0].text
    puts assistant_text

    # Append assistant turn
    history << {
      role: 'assistant',
      content: [{ text: assistant_text }]
    }
  end

  puts "\nChat session ended."

rescue Aws::BedrockRuntime::Errors::ServiceError => e
  puts "\nAWS Bedrock Runtime Error: #{e.message}"
rescue StandardError => e
  puts "\nAn unexpected error occurred: #{e.message}"
end
