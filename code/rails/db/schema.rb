# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_15_000000) do
  create_table "llm_invocation_metrics", force: :cascade do |t|
    t.integer "completion_tokens", null: false
    t.datetime "created_at", null: false
    t.integer "latency_ms", null: false
    t.string "model_id", null: false
    t.integer "prompt_tokens", null: false
    t.datetime "updated_at", null: false
  end

  create_table "security_audit_logs", force: :cascade do |t|
    t.string "action_taken", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "user_prompt", null: false
    t.text "violations_trace", null: false
  end
end
