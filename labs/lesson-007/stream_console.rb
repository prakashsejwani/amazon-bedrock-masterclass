require 'aws-sdk-bedrockruntime'
require 'json'
require 'base64'

begin
  client = Aws::BedrockRuntime::Client.new(region: 'us-east-1')

  prompt = ARGV[0] || "Write a short creative poem about cloud computing."
  puts "Sending prompt to Amazon Nova Micro: '#{prompt}'"
  puts "Streaming response:\n\n"

  body = {
    messages: [{ role: 'user', content: [{ text: prompt }] }],
    inferenceConfig: { maxNewTokens: 500 }
  }

  client.invoke_model_with_response_stream(
    model_id: 'amazon.nova-micro-v1:0',
    body: body.to_json,
    content_type: 'application/json'
  ) do |stream|
    stream.on_chunk_received do |chunk|
      data = JSON.parse(chunk.bytes)
      
      if data.dig('chunk', 'bytes')
        decoded = JSON.parse(Base64.decode64(data['chunk']['bytes']))
        token = decoded.dig('output', 'message', 'content', 0, 'text')
        print token if token
        $stdout.flush
      end
    end
  end
  puts "\n\nStream Finished."

rescue Aws::BedrockRuntime::Errors::ServiceError => e
  puts "\nAWS Bedrock Runtime Error: #{e.message}"
rescue StandardError => e
  puts "\nError: #{e.message}"
end
