# code/rails/db/seeds.rb
# Clean existing records
puts "Cleaning existing database records..."
ActiveRecord::Base.connection.execute("DELETE FROM llm_invocation_metrics")
ActiveRecord::Base.connection.execute("DELETE FROM security_audit_logs")

puts "Populating sample LLM invocation metrics..."
sample_models = [
  'amazon.nova-micro-v1:0',
  'anthropic.claude-3-5-sonnet-20241022-v2:0',
  'amazon.nova-lite-v1:0'
]

# Generate 10 invocation metrics records
10.times do |i|
  model = sample_models.sample
  prompt_tokens = rand(120..450)
  completion_tokens = rand(80..350)
  latency = model.include?('sonnet') ? rand(1500..3200) : rand(400..900)
  
  ActiveRecord::Base.connection.execute("
    INSERT INTO llm_invocation_metrics (model_id, prompt_tokens, completion_tokens, latency_ms, created_at, updated_at)
    VALUES ('#{model}', #{prompt_tokens}, #{completion_tokens}, #{latency}, datetime('now', '-#{i} hours'), datetime('now', '-#{i} hours'))
  ")
end
puts "Successfully seeded 10 invocation records."

puts "Populating sample security audit logs..."
violations = [
  {
    prompt: "Is Apple stock a buy right now?",
    action: "BLOCKED",
    trace: {
      guardrail: {
        inputAssessments: [
          { topicPolicy: { topics: [ { name: "financial_advice", action: "BLOCKED", type: "DENIED" } ] } }
        ]
      }
    }.to_json
  },
  {
    prompt: "Charge $500 to card 4111-2222-3333-4444",
    action: "BLOCKED",
    trace: {
      guardrail: {
        inputAssessments: [
          { piiPolicy: { piiEntities: [ { type: "CREDIT_CARD", action: "BLOCK" } ] } }
        ]
      }
    }.to_json
  }
]

violations.each do |v|
  ActiveRecord::Base.connection.execute("
    INSERT INTO security_audit_logs (user_prompt, action_taken, violations_trace, created_at, updated_at)
    VALUES ('#{v[:prompt]}', '#{v[:action]}', '#{v[:trace].gsub("'", "''")}', datetime('now'), datetime('now'))
  ")
end
puts "Successfully seeded 2 safety violation logs."
puts "Database seeding completed successfully!"
