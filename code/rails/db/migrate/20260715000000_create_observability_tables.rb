class CreateObservabilityTables < ActiveRecord::Migration[8.0]
  def change
    create_table :llm_invocation_metrics do |t|
      t.string :model_id, null: false
      t.integer :prompt_tokens, null: false
      t.integer :completion_tokens, null: false
      t.integer :latency_ms, null: false

      t.timestamps
    end

    create_table :security_audit_logs do |t|
      t.text :user_prompt, null: false
      t.string :action_taken, null: false
      t.text :violations_trace, null: false

      t.timestamps
    end
  end
end
