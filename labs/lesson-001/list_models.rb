require 'aws-sdk-bedrock'

begin
  puts "Initializing Amazon Bedrock control-plane client..."
  # Initializes using default AWS credential provider chain
  client = Aws::Bedrock::Client.new(region: 'us-east-1')

  puts "Fetching available foundation models..."
  response = client.list_foundation_models

  puts "\n%-40s | %-30s | %-15s" % ["MODEL NAME", "MODEL ID", "PROVIDER"]
  puts "-" * 90

  response.model_summaries.take(15).each do |model|
    puts "%-40s | %-30s | %-15s" % [model.model_name, model.model_id, model.provider_name]
  end

rescue LoadError
  puts "Error: The 'aws-sdk-bedrock' gem is not installed."
  puts "Please run: gem install aws-sdk-bedrock"
rescue Aws::Bedrock::Errors::ServiceError => e
  puts "AWS Service Error: #{e.message}"
rescue StandardError => e
  puts "An unexpected error occurred: #{e.message}"
end
