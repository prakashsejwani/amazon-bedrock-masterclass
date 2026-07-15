require 'aws-sdk-bedrockruntime'
require 'json'

begin
  # Initialize Bedrock client using the user's personal profile
  client = Aws::BedrockRuntime::Client.new(
    region: 'us-east-1',
    credentials: Aws::SharedCredentials.new(profile_name: 'personal')
  )

  guardrail_id = ENV['BEDROCK_GUARDRAIL_ID']
  guardrail_version = ENV['BEDROCK_GUARDRAIL_VERSION'] || "1"

  if guardrail_id.nil? || guardrail_id.empty?
    puts "Warning: BEDROCK_GUARDRAIL_ID environment variable is not configured."
    puts "To run this script with a real Bedrock Guardrail, run:"
    puts "export BEDROCK_GUARDRAIL_ID='your-guardrail-id'\n\n"
    guardrail_id = "MOCK-GUARDRAIL-ID-12345"
  end

  prompt = ARGV[0] || "Give me investment advice on buying stocks like AAPL."
  puts "Invoking Model with Guardrail: '#{guardrail_id}' (Profile: personal)..."
  puts "Prompt: '#{prompt}'"
  puts "=" * 80

  response = client.converse(
    model_id: 'amazon.nova-micro-v1:0',
    messages: [{ role: 'user', content: [{ text: prompt }] }],
    guardrail_config: {
      guardrail_identifier: guardrail_id,
      guardrail_version: guardrail_version
    }
  )

  if response.stop_reason == 'guardrail_intervened'
    puts "\n[ALERT] Safety Policy Intervened! Output Blocked."
    puts "Model Return Text: #{response.output.message.content[0].text.strip}"
    puts "-" * 80

    # Parse trace metrics
    trace = response.trace&.guardrail
    if trace
      puts "Guardrail Assessments Trace:"
      trace.input_assessments.each do |asm|
        if asm.topic_policy
          asm.topic_policy.topics.each do |t|
            puts " -> [Topic Filter]: '#{t.name}' (Action: #{t.action}, Type: #{t.type})"
          end
        end
        if asm.content_policy
          asm.content_policy.filters.each do |f|
            puts " -> [Content Filter]: Category #{f.type} triggered."
          end
        end
        if asm.pii_policy
          asm.pii_policy.pii_entities.each do |e|
            puts " -> [PII Filter]: Redacted entity #{e.type} (Action: #{e.action})"
          end
        end
      end
    else
      puts "No trace logs returned. Ensure enable_trace or equivalent tracing is active."
    end
  else
    puts "\nModel executed safely:"
    puts response.output.message.content[0].text.strip
  end
  puts "=" * 80

rescue Aws::BedrockRuntime::Errors::ServiceError => e
  if guardrail_id == "MOCK-GUARDRAIL-ID-12345"
    puts "\nMock API Call: AWS returned expected error for placeholder guardrail configuration: #{e.message}"
  else
    puts "\nAWS Bedrock Runtime Error: #{e.message}"
  end
rescue StandardError => e
  puts "\nError: #{e.message}"
end
