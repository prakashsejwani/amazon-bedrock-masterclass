require 'aws-sdk-bedrock'

begin
  client = Aws::Bedrock::Client.new(region: 'us-east-1')

  puts "Querying running or completed Model Evaluation jobs..."
  response = client.list_evaluation_jobs(max_results: 10)

  if response.job_summaries.empty?
    puts "No model evaluation jobs found in us-east-1."
  else
    puts "\n%-30s | %-15s | %-30s" % ["JOB NAME", "STATUS", "CREATION TIME"]
    puts "-" * 80
    response.job_summaries.each do |job|
      puts "%-30s | %-15s | %-30s" % [job.job_name, job.status, job.creation_time.to_s]
    end
  end

rescue Aws::Bedrock::Errors::ServiceError => e
  puts "AWS Bedrock Error: #{e.message}"
rescue StandardError => e
  puts "Error: #{e.message}"
end
