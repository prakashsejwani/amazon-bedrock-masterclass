require 'aws-sdk-sts'
require 'aws-sdk-bedrock'

begin
  puts "Querying AWS Security Token Service (STS) caller identity..."
  sts = Aws::STS::Client.new(region: 'us-east-1')
  identity = sts.get_caller_identity

  puts "\nSTS Credentials Summary:"
  puts "=" * 50
  puts "Account:     #{identity.account}"
  puts "Arn:         #{identity.arn}"
  puts "UserId:      #{identity.user_id}"

  puts "\nPinging AWS Bedrock control-plane client..."
  bedrock = Aws::Bedrock::Client.new(region: 'us-east-1')
  models = bedrock.list_foundation_models(max_results: 1)

  puts "Bedrock connectivity: SUCCESS"
  puts "First available model retrieved: #{models.model_summaries.first&.model_id}"

rescue Aws::STS::Errors::ServiceError => e
  puts "STS Service Error: #{e.message}"
rescue Aws::Bedrock::Errors::AccessDeniedException
  puts "Security Error: Your active IAM Role/User is blocked from listing Bedrock models."
rescue Aws::Bedrock::Errors::ServiceError => e
  puts "Bedrock Service Error: #{e.message}"
rescue StandardError => e
  puts "Error: #{e.message}"
end
