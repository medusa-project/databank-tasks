# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_10_01_195751) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "comments", force: :cascade do |t|
    t.bigint "problem_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "nested_items", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.string "item_name", null: false
    t.string "item_path", null: false
    t.bigint "item_size", default: 0
    t.boolean "is_directory", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "problems", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.text "report", null: false
    t.string "status", default: "reported"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks", force: :cascade do |t|
    t.string "web_id"
    t.string "storage_root"
    t.string "storage_key"
    t.string "binary_name"
    t.string "status", default: "pending"
    t.string "peek_type"
    t.text "peek_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
