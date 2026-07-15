require 'aws-sdk-bedrockagentruntime'

begin
  # Initialize Bedrock Agent Runtime client using the user's personal profile
  client = Aws::BedrockAgentRuntime::Client.new(
    region: 'us-east-1',
    credentials: Aws::SharedCredentials.new(profile_name: 'personal')
  )

  agent_id = ENV['BEDROCK_AGENT_ID']
  agent_alias_id = ENV['BEDROCK_AGENT_ALIAS_ID']

  if agent_id.nil? || agent_id.empty? || agent_alias_id.nil? || agent_alias_id.empty?
    puts "Warning: BEDROCK_AGENT_ID or BEDROCK_AGENT_ALIAS_ID is not configured in the environment."
    puts "To run this script with a real Bedrock Agent, run:"
    puts "export BEDROCK_AGENT_ID='your-agent-id'"
    puts "export BEDROCK_AGENT_ALIAS_ID='your-agent-alias-id'\n\n"
    agent_id = "MOCK-AGENT-ID-12345"
    agent_alias_id = "MOCK-ALIAS-ID-12345"
  end

  prompt = ARGV[0] || "Verify reimbursement records for Prakash."
  puts "Invoking Agent ID: '#{agent_id}' (Profile: personal)..."
  puts "Prompt: '#{prompt}'"
  puts "=" * 80

  response = client.invoke_agent(
    agent_id: agent_id,
    agent_alias_id: agent_alias_id,
    session_id: "session-rb-trace-99",
    input_text: prompt,
    enable_trace: true
  )

  puts "\nStreaming Agent Output & Trace logs:"
  puts "-" * 80

  response.completion.each do |event|
    # Print completion chunks
    if event.respond_to?(:chunk) && event.chunk
      print event.chunk.bytes
      $stdout.flush
    # Print orchestration traces
    elsif event.respond_to?(:trace) && event.trace
      trace = event.trace.trace
      if trace.orchestration_trace
        rationale = trace.orchestration_trace.rationale
        puts "\n[Thought]: #{rationale.text.strip}" if rationale
        
        inv = trace.orchestration_trace.invocation_input
        if inv && inv.action_group_invocation_input
          action_group = inv.action_group_invocation_input
          puts "[Action]: Invoking Action Group '#{action_group.action_group_name}' for verb '#{action_group.api_path}'"
        end
      end
    end
  end
  puts "\n" + "=" * 80

rescue Aws::BedrockAgentRuntime::Errors::ServiceError => e
  if agent_id == "MOCK-AGENT-ID-12345"
    puts "\nMock API Call: AWS returned expected error for placeholder agent config: #{e.message}"
  else
    puts "\nAWS Bedrock Agent Runtime Error: #{e.message}"
  end
rescue StandardError => e
  puts "\nError: #{e.message}"
end
