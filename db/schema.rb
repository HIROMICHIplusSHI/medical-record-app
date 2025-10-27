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

ActiveRecord::Schema[7.2].define(version: 2025_10_27_143220) do
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

  create_table "announcements", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.string "title", limit: 100, null: false
    t.text "body", null: false
    t.integer "status", default: 0, null: false
    t.integer "severity", default: 0, null: false
    t.datetime "published_at"
    t.datetime "expires_at"
    t.integer "display_order", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_announcements_on_author_id"
    t.index ["expires_at"], name: "index_announcements_on_expires_at"
    t.index ["published_at"], name: "index_announcements_on_published_at"
    t.index ["status", "published_at", "expires_at"], name: "index_announcements_on_active"
    t.index ["status"], name: "index_announcements_on_status"
  end

  create_table "consent_form_items", force: :cascade do |t|
    t.bigint "consent_form_template_id", null: false
    t.text "content", null: false
    t.integer "position", null: false
    t.boolean "is_required", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["consent_form_template_id", "position"], name: "idx_on_consent_form_template_id_position_0f140619d7"
    t.index ["consent_form_template_id"], name: "index_consent_form_items_on_consent_form_template_id"
  end

  create_table "consent_form_templates", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "title"], name: "index_consent_form_templates_on_user_id_and_title", unique: true
    t.index ["user_id"], name: "index_consent_form_templates_on_user_id"
  end

  create_table "consent_item_responses", force: :cascade do |t|
    t.bigint "patient_consent_id", null: false
    t.bigint "consent_form_item_id", null: false
    t.boolean "checked", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "item_content"
    t.index ["consent_form_item_id"], name: "index_consent_item_responses_on_consent_form_item_id"
    t.index ["patient_consent_id", "consent_form_item_id"], name: "index_consent_responses_uniqueness", unique: true
    t.index ["patient_consent_id"], name: "index_consent_item_responses_on_patient_consent_id"
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
    t.decimal "billing_rate", precision: 5, scale: 2
    t.index ["user_id", "name"], name: "index_facilities_on_user_id_and_name"
    t.index ["user_id"], name: "index_facilities_on_user_id"
  end

  create_table "facility_doctors", force: :cascade do |t|
    t.bigint "facility_id", null: false
    t.string "name", null: false
    t.string "medical_license_number"
    t.string "specialization"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["facility_id", "medical_license_number"], name: "index_facility_doctors_on_facility_and_license", unique: true
    t.index ["facility_id"], name: "index_facility_doctors_on_facility_id"
  end

  create_table "inquiries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "subject", limit: 100, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "category", default: 0, null: false
    t.integer "last_message_by", default: 0, null: false, comment: "最後にメッセージを送った人 (0: user, 1: admin)"
    t.datetime "admin_read_at"
    t.datetime "user_read_at"
    t.index ["admin_read_at"], name: "index_inquiries_on_admin_read_at"
    t.index ["status", "last_message_by"], name: "index_inquiries_on_status_and_last_message_by"
    t.index ["status"], name: "index_inquiries_on_status"
    t.index ["updated_at"], name: "index_inquiries_on_updated_at"
    t.index ["user_id"], name: "index_inquiries_on_user_id"
    t.index ["user_read_at"], name: "index_inquiries_on_user_read_at"
  end

  create_table "inquiry_messages", force: :cascade do |t|
    t.bigint "inquiry_id", null: false
    t.bigint "user_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_inquiry_messages_on_created_at"
    t.index ["inquiry_id"], name: "index_inquiry_messages_on_inquiry_id"
    t.index ["user_id"], name: "index_inquiry_messages_on_user_id"
  end

  create_table "invitation_codes", force: :cascade do |t|
    t.string "code", null: false
    t.integer "max_uses"
    t.integer "used_count", default: 0, null: false
    t.datetime "expires_at"
    t.bigint "created_by_id", null: false
    t.integer "status", default: 0, null: false
    t.text "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_invitation_codes_on_code", unique: true
    t.index ["created_by_id"], name: "index_invitation_codes_on_created_by_id"
    t.index ["expires_at"], name: "index_invitation_codes_on_expires_at"
    t.index ["status"], name: "index_invitation_codes_on_status"
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

  create_table "patient_consents", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "consent_form_template_id", null: false
    t.bigint "medical_record_id", null: false
    t.bigint "facility_doctor_id"
    t.bigint "user_id", null: false
    t.datetime "agreed_at", null: false
    t.text "signature_data"
    t.text "practitioner_name"
    t.text "facility_name"
    t.text "facility_address"
    t.text "facility_phone"
    t.string "signed_ip"
    t.text "signed_user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "template_title"
    t.boolean "nurse_confirmed", default: false, null: false
    t.string "pdf_hash"
    t.index ["agreed_at"], name: "index_patient_consents_on_agreed_at"
    t.index ["consent_form_template_id"], name: "index_patient_consents_on_consent_form_template_id"
    t.index ["facility_doctor_id"], name: "index_patient_consents_on_facility_doctor_id"
    t.index ["medical_record_id", "consent_form_template_id"], name: "index_consents_on_record_and_template"
    t.index ["medical_record_id"], name: "index_patient_consents_on_medical_record_id"
    t.index ["patient_id"], name: "index_patient_consents_on_patient_id"
    t.index ["user_id"], name: "index_patient_consents_on_user_id"
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
    t.boolean "nurse_confirmed", default: false, null: false
    t.datetime "nurse_confirmed_at"
    t.string "nurse_name"
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
    t.integer "role", default: 0, null: false
    t.datetime "terms_accepted_at"
    t.datetime "privacy_accepted_at"
    t.bigint "invitation_code_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_code_id"], name: "index_users_on_invitation_code_id"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "announcements", "users", column: "author_id"
  add_foreign_key "consent_form_items", "consent_form_templates"
  add_foreign_key "consent_form_templates", "users"
  add_foreign_key "consent_item_responses", "consent_form_items"
  add_foreign_key "consent_item_responses", "patient_consents"
  add_foreign_key "cost_items", "cost_sheets"
  add_foreign_key "cost_items", "medical_records"
  add_foreign_key "cost_sheets", "users"
  add_foreign_key "facilities", "users"
  add_foreign_key "facility_doctors", "facilities"
  add_foreign_key "inquiries", "users"
  add_foreign_key "inquiry_messages", "inquiries"
  add_foreign_key "inquiry_messages", "users"
  add_foreign_key "invitation_codes", "users", column: "created_by_id"
  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoice_items", "medical_records"
  add_foreign_key "invoices", "facilities"
  add_foreign_key "invoices", "users"
  add_foreign_key "medical_record_tags", "medical_records"
  add_foreign_key "medical_record_tags", "tags"
  add_foreign_key "medical_records", "facilities"
  add_foreign_key "medical_records", "patients"
  add_foreign_key "medical_records", "users"
  add_foreign_key "patient_consents", "consent_form_templates"
  add_foreign_key "patient_consents", "facility_doctors"
  add_foreign_key "patient_consents", "medical_records"
  add_foreign_key "patient_consents", "patients"
  add_foreign_key "patient_consents", "users"
  add_foreign_key "patients", "users"
  add_foreign_key "questionnaires", "patients"
  add_foreign_key "tags", "users"
  add_foreign_key "users", "invitation_codes"
end
