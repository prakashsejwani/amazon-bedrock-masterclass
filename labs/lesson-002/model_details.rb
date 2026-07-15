require 'aws-sdk-bedrock'

begin
  client = Aws::Bedrock::Client.new(region: 'us-east-1')

  model_id = ARGV[0] || 'anthropic.claude-3-5-sonnet-20241022-v2:0'
  puts "Fetching details for model: #{model_id}..."

  response = client.get_foundation_model(model_identifier: model_id)
  details = response.model_details

  puts "\nModel Details Summary:"
  puts "=" * 50
  puts "Name:         #{details.model_name}"
  puts "ID:           #{details.model_id}"
  puts "Provider:     #{details.provider_name}"
  puts "Input Types:  #{details.input_modalities.join(', ')}"
  puts "Output Types: #{details.output_modalities.join(', ')}"
  puts "Customizable: #{details.customizations_supported.join(', ')}"
  puts "Streaming:    #{details.response_streaming_supported ? 'Yes' : 'No'}"

rescue Aws::Bedrock::Errors::ValidationException
  puts "Error: Model ID '#{model_id}' is not recognized or not available in us-east-1."
rescue Aws::Bedrock::Errors::ServiceError => e
  puts "AWS Bedrock Error: #{e.message}"
rescue StandardError => e
  puts "Error: #{e.message}"
end
