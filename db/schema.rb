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

ActiveRecord::Schema[8.0].define(version: 2025_09_12_110144) do
  create_table "pages", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "cover_color"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_pages_on_user_id"
  end

  create_table "todos", force: :cascade do |t|
    t.string "title"
    t.text "notes"
    t.boolean "completed"
    t.integer "page_id", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "due_date"
    t.index ["page_id"], name: "index_todos_on_page_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.boolean "premium", default: false, null: false
  end

  add_foreign_key "pages", "users"
  add_foreign_key "todos", "pages"
end
