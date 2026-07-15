require 'aws-sdk-bedrockagentruntime'

begin
  # Initialize Bedrock Agent Runtime client using the user's personal profile
  client = Aws::BedrockAgentRuntime::Client.new(
    region: 'us-east-1',
    credentials: Aws::SharedCredentials.new(profile_name: 'personal')
  )

  # Fetch Knowledge Base ID from environment or fallback placeholder
  kb_id = ENV['BEDROCK_KB_ID']
  
  if kb_id.nil? || kb_id.empty?
    puts "Warning: BEDROCK_KB_ID environment variable is not set."
    puts "To run this script with a real Knowledge Base, set the env var:"
    puts "export BEDROCK_KB_ID='your-knowledge-base-id'\n\n"
    kb_id = "MOCK-KB-ID-12345"
  end

  query = ARGV[0] || "What is our travel reimbursement policy?"
  puts "Querying Knowledge Base: '#{kb_id}' (Profile: personal)..."
  puts "Query Text: '#{query}'\n"

  # Perform retrieve query
  response = client.retrieve(
    knowledge_base_id: kb_id,
    retrieval_query: {
      text: query
    },
    retrieval_configuration: {
      vector_search_configuration: {
        number_of_results: 3
      }
    }
  )

  puts "Found #{response.retrieval_results.length} matching document chunks:"
  puts "=" * 80

  response.retrieval_results.each_with_index do |res, idx|
    puts "\nResult ##{idx + 1} (Score: #{res.score.round(4)}):"
    puts "-" * 40
    puts "Content:  #{res.content.text.strip}"
    puts "Location: #{res.location.s3_location.uri}"
  end

rescue Aws::BedrockAgentRuntime::Errors::ServiceError => e
  # If the KB ID is mock, we expect a validation/access error
  if kb_id == "MOCK-KB-ID-12345"
    puts "\nMock API Call: AWS returned expected error for placeholder ID: #{e.message}"
  else
    puts "\nAWS Bedrock Agent Runtime Error: #{e.message}"
  end
rescue StandardError => e
  puts "\nError: #{e.message}"
end
