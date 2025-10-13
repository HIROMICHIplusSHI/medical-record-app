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

ActiveRecord::Schema[7.1].define(version: 2025_10_13_021339) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "cost_items", force: :cascade do |t|
    t.bigint "medical_record_id", null: false
    t.string "item_name", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.decimal "total_price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "cost_sheet_id"
    t.index ["cost_sheet_id"], name: "index_cost_items_on_cost_sheet_id"
    t.index ["medical_record_id", "created_at"], name: "index_cost_items_on_medical_record_id_and_created_at"
    t.index ["medical_record_id"], name: "index_cost_items_on_medical_record_id"
  end

  create_table "cost_sheets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "item_name", null: false
    t.integer "standard_price", default: 0, null: false
    t.string "category"
    t.text "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_cost_sheets_on_category"
    t.index ["item_name"], name: "index_cost_sheets_on_item_name"
    t.index ["user_id"], name: "index_cost_sheets_on_user_id"
  end

  create_table "facilities", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.text "address"
    t.string "phone"
    t.string "email"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_facilities_on_user_id_and_name"
    t.index ["user_id"], name: "index_facilities_on_user_id"
  end

  create_table "medical_records", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "facility_id", null: false
    t.bigint "user_id", null: false
    t.date "visit_date"
    t.string "treatment_location"
    t.text "chief_complaint"
    t.text "diagnosis"
    t.text "treatment_content"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["facility_id"], name: "index_medical_records_on_facility_id"
    t.index ["patient_id"], name: "index_medical_records_on_patient_id"
    t.index ["user_id", "visit_date"], name: "index_medical_records_on_user_id_and_visit_date"
    t.index ["user_id"], name: "index_medical_records_on_user_id"
    t.index ["visit_date"], name: "index_medical_records_on_visit_date"
  end

  create_table "patients", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.date "date_of_birth"
    t.integer "gender", default: 0
    t.string "phone"
    t.string "email"
    t.text "address"
    t.string "emergency_contact"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_patients_on_created_at"
    t.index ["email"], name: "index_patients_on_email"
    t.index ["user_id"], name: "index_patients_on_user_id"
  end

  create_table "questionnaires", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.text "current_medications"
    t.text "allergies"
    t.text "past_surgeries"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "full_name"
    t.text "full_name_kana"
    t.text "birth_date"
    t.text "gender"
    t.text "phone"
    t.text "email"
    t.text "postal_code"
    t.text "address"
    t.text "emergency_contact"
    t.text "medical_conditions"
    t.text "pregnancy_info"
    t.text "desired_treatments"
    t.text "past_treatments"
    t.text "skin_conditions"
    t.text "other_concerns"
    t.index ["patient_id"], name: "index_questionnaires_on_patient_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "provider"
    t.string "uid"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "cost_items", "cost_sheets"
  add_foreign_key "cost_items", "medical_records"
  add_foreign_key "cost_sheets", "users"
  add_foreign_key "facilities", "users"
  add_foreign_key "medical_records", "facilities"
  add_foreign_key "medical_records", "patients"
  add_foreign_key "medical_records", "users"
  add_foreign_key "patients", "users"
  add_foreign_key "questionnaires", "patients"
end
