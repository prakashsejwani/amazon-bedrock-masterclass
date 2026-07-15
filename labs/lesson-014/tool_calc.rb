require 'aws-sdk-bedrockruntime'
require 'json'

# Local helper function for addition
def calculate_sum(a, b)
  { result: a + b }
end

begin
  # Initialize Bedrock client with the personal credentials profile
  client = Aws::BedrockRuntime::Client.new(
    region: 'us-east-1',
    credentials: Aws::SharedCredentials.new(profile_name: 'personal')
  )

  tool_config = {
    tools: [{
      tool_spec: {
        name: 'calculate_sum',
        description: 'Calculates the sum of two numbers a and b',
        input_schema: {
          json: {
            type: 'object',
            properties: {
              a: { type: 'number' },
              b: { type: 'number' }
            },
            required: ['a', 'b']
          }
        }
      }
    }]
  }

  prompt = "What is the sum of 4235 and 8761?"
  puts "User prompt: '#{prompt}'"
  puts "Sending request to Amazon Nova (Profile: personal)..."

  messages = [{ role: 'user', content: [{ text: prompt }] }]

  # Call 1: Request with tool configurations
  response = client.converse(
    model_id: 'amazon.nova-micro-v1:0',
    messages: messages,
    tool_config: tool_config
  )

  assistant_msg = response.output.message
  messages << { role: 'assistant', content: assistant_msg.content }

  if response.stop_reason == 'tool_use'
    tool_use = assistant_msg.content.find(&:tool_use).tool_use
    puts "\nModel requested tool: '#{tool_use.name}'"
    puts "Arguments: #{tool_use.input.to_h}"

    # Execute local addition logic
    if tool_use.name == 'calculate_sum'
      local_output = calculate_sum(tool_use.input['a'], tool_use.input['b'])
      puts "Local function result: #{local_output[:result]}"

      # Submit result in user role
      messages << {
        role: 'user',
        content: [{
          tool_result: {
            tool_use_id: tool_use.tool_use_id,
            content: [{ json: local_output }],
            status: 'success'
          }
        }]
      }

      puts "\nSending tool results back to model..."
      # Call 2: Final response compilation
      final_response = client.converse(
        model_id: 'amazon.nova-micro-v1:0',
        messages: messages,
        tool_config: tool_config
      )

      puts "\nFinal grounded answer from Bedrock:"
      puts final_response.output.message.content[0].text
    end
  else
    puts "\nModel did not call the tool. Raw response: #{assistant_msg.content[0].text}"
  end

rescue Aws::BedrockRuntime::Errors::ServiceError => e
  puts "\nAWS Bedrock Runtime Error: #{e.message}"
rescue StandardError => e
  puts "\nError: #{e.message}"
end
