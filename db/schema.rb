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

ActiveRecord::Schema[7.2].define(version: 2025_10_16_130241) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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
    t.string "billing_addressee"
    t.decimal "billing_rate"
    t.index ["user_id", "name"], name: "index_facilities_on_user_id_and_name"
    t.index ["user_id"], name: "index_facilities_on_user_id"
  end

  create_table "invoice_items", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.bigint "medical_record_id", null: false
    t.string "description", null: false
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id", "medical_record_id"], name: "index_invoice_items_on_invoice_and_medical_record", unique: true
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
    t.index ["medical_record_id"], name: "index_invoice_items_on_medical_record_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "facility_id", null: false
    t.string "invoice_number", null: false
    t.datetime "issued_at", null: false
    t.date "billing_period_start", null: false
    t.date "billing_period_end", null: false
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "status", default: 0, null: false
    t.datetime "sent_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "tax_display", default: false, null: false
    t.index ["facility_id", "billing_period_start"], name: "index_invoices_on_facility_id_and_billing_period_start"
    t.index ["facility_id"], name: "index_invoices_on_facility_id"
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number", unique: true
    t.index ["status"], name: "index_invoices_on_status"
    t.index ["user_id"], name: "index_invoices_on_user_id"
  end

  create_table "medical_record_tags", force: :cascade do |t|
    t.bigint "medical_record_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["medical_record_id", "tag_id"], name: "index_medical_record_tags_on_medical_record_id_and_tag_id", unique: true
    t.index ["medical_record_id"], name: "index_medical_record_tags_on_medical_record_id"
    t.index ["tag_id"], name: "index_medical_record_tags_on_tag_id"
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
    t.index ["name"], name: "index_patients_on_name"
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

  create_table "tags", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "category"
    t.string "color", default: "#3B82F6"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_tags_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_tags_on_user_id"
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
    t.string "company_name"
    t.string "company_postal"
    t.text "company_address"
    t.string "company_phone"
    t.string "company_email"
    t.text "bank_info"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cost_items", "cost_sheets"
  add_foreign_key "cost_items", "medical_records"
  add_foreign_key "cost_sheets", "users"
  add_foreign_key "facilities", "users"
  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoice_items", "medical_records"
  add_foreign_key "invoices", "facilities"
  add_foreign_key "invoices", "users"
  add_foreign_key "medical_record_tags", "medical_records"
  add_foreign_key "medical_record_tags", "tags"
  add_foreign_key "medical_records", "facilities"
  add_foreign_key "medical_records", "patients"
  add_foreign_key "medical_records", "users"
  add_foreign_key "patients", "users"
  add_foreign_key "questionnaires", "patients"
  add_foreign_key "tags", "users"
end
