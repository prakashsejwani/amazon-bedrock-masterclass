require 'aws-sdk-bedrockruntime'
require 'json'

# Define structured flight object
Flight = Struct.new(:flight_number, :departure_gate, :delayed)

begin
  # Initialize Bedrock client with the personal credentials profile
  client = Aws::BedrockRuntime::Client.new(
    region: 'us-east-1',
    credentials: Aws::SharedCredentials.new(profile_name: 'personal')
  )

  raw_flight_info = "Flight AA-102 departing from Gate C15 is currently delayed by 30 minutes."
  puts "Source text: '#{raw_flight_info}'"
  puts "Parsing schema values (Profile: personal)..."

  tool_config = {
    tools: [{
      tool_spec: {
        name: 'save_flight',
        description: 'Saves flight details',
        input_schema: {
          json: {
            type: 'object',
            properties: {
              flight_number: { type: 'string' },
              departure_gate: { type: 'string' },
              delayed: { type: 'boolean' }
            },
            required: ['flight_number', 'departure_gate', 'delayed']
          }
        }
      }
    }],
    tool_choice: { tool: { name: 'save_flight' } }
  }

  response = client.converse(
    model_id: 'amazon.nova-micro-v1:0',
    messages: [{ role: 'user', content: [{ text: raw_flight_info }] }],
    tool_config: tool_config
  )

  # Extract tool inputs
  data = response.output.message.content[0].tool_use.input.to_h
  
  # Instantiating custom Struct
  flight = Flight.new(data['flight_number'], data['departure_gate'], data['delayed'])

  puts "\nParsed Flight Struct Details:"
  puts "=" * 40
  puts "Flight Number:  #{flight.flight_number}"
  puts "Departure Gate: #{flight.departure_gate}"
  puts "Is Delayed?:    #{flight.delayed}"

rescue Aws::BedrockRuntime::Errors::ServiceError => e
  puts "\nAWS Bedrock Runtime Error: #{e.message}"
rescue StandardError => e
  puts "\nError: #{e.message}"
end
