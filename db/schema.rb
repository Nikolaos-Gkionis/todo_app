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

ActiveRecord::Schema[8.0].define(version: 2026_06_07_120100) do
  create_table "migration_statuses", force: :cascade do |t|
    t.string "migration_type", null: false
    t.string "status", default: "pending", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.text "metadata"
    t.text "results"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["completed_at"], name: "index_migration_statuses_on_completed_at"
    t.index ["migration_type"], name: "index_migration_statuses_on_migration_type", unique: true
    t.index ["started_at"], name: "index_migration_statuses_on_started_at"
    t.index ["status"], name: "index_migration_statuses_on_status"
  end

  create_table "pages", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "cover_color"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "template", default: "minimal", null: false
    t.integer "position"
    t.index ["user_id"], name: "index_pages_on_user_id"
  end

  create_table "todos", force: :cascade do |t|
    t.string "title"
    t.text "notes"
    t.boolean "completed"
    t.integer "page_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "due_date"
    t.integer "user_id", null: false
    t.boolean "bold"
    t.string "highlight_color"
    t.string "recurrence_rule"
    t.boolean "is_visual_break", default: false, null: false
    t.index ["page_id"], name: "index_todos_on_page_id"
    t.index ["user_id"], name: "index_todos_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.boolean "premium", default: false, null: false
    t.string "name"
    t.datetime "trial_started_at"
    t.datetime "trial_expires_at"
    t.boolean "device_downloaded", default: false, null: false
    t.string "download_token", limit: 255
    t.boolean "trial_data_exported", default: false, null: false
    t.string "remember_token"
    t.datetime "remember_token_expires_at"
    t.integer "download_count", default: 0
    t.string "accent_color"
    t.string "font_family", default: "default", null: false
    t.string "app_name"
    t.string "app_title", default: "Peponi.to", null: false
    t.boolean "roll_over", default: true, null: false
    t.string "not_yet_panel_title", default: "Not Yet", null: false
    t.datetime "paid_at"
    t.string "polar_customer_id"
    t.string "polar_product_id"
    t.string "polar_order_id"
    t.string "lists_placement", default: "right", null: false
    t.index ["device_downloaded"], name: "idx_users_device_downloaded"
    t.index ["download_token"], name: "idx_users_download_token"
    t.index ["polar_customer_id"], name: "index_users_on_polar_customer_id"
    t.index ["polar_order_id"], name: "index_users_on_polar_order_id"
    t.index ["trial_expires_at"], name: "idx_users_trial_expires"
    t.check_constraint "trial_expires_at IS NULL OR trial_expires_at > trial_started_at", name: "check_trial_expires_after_start"
  end

  add_foreign_key "pages", "users"
  add_foreign_key "todos", "pages"
  add_foreign_key "todos", "users"
end
