# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160111105316) do

  create_table "activity_logs", force: true do |t|
    t.integer  "user_id"
    t.string   "browser"
    t.string   "ip_address"
    t.string   "controller"
    t.string   "action"
    t.string   "params"
    t.string   "note"
    t.integer  "job_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "assets", force: true do |t|
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "billing_addresses", force: true do |t|
    t.string   "house_no"
    t.string   "street_address"
    t.string   "city"
    t.string   "state"
    t.string   "zip_code"
    t.integer  "user_id"
    t.boolean  "is_active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "payment_method_id"
  end

  create_table "billings", force: true do |t|
    t.string   "document_file_name"
    t.string   "document_content_type"
    t.integer  "document_file_size"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.date     "billing_month"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "blogs", force: true do |t|
    t.string   "title"
    t.text     "description"
    t.boolean  "is_archived", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ca_zip_codes", force: true do |t|
    t.string   "code"
    t.string   "area_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ckeditor_assets", force: true do |t|
    t.string   "data_file_name",               null: false
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.integer  "assetable_id"
    t.string   "assetable_type",    limit: 30
    t.string   "type",              limit: 30
    t.integer  "width"
    t.integer  "height"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ckeditor_assets", ["assetable_type", "assetable_id"], name: "idx_ckeditor_assetable", using: :btree
  add_index "ckeditor_assets", ["assetable_type", "type", "assetable_id"], name: "idx_ckeditor_assetable_type", using: :btree

  create_table "coupon_code_users", force: true do |t|
    t.integer  "user_id"
    t.integer  "coupon_code_id"
    t.integer  "job_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "coupon_codes", force: true do |t|
    t.string   "code"
    t.string   "coupon_type"
    t.float    "coupon_value"
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.integer  "user_id"
    t.string   "send_to_users"
    t.integer  "per_user",                 default: 0
    t.integer  "per_coupon",               default: 0
    t.string   "status",                   default: "Open"
    t.integer  "promotion_code_user_id"
    t.string   "promotion_code_user_type"
    t.string   "coupon_group"
    t.boolean  "is_send",                  default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "customer_settings", force: true do |t|
    t.integer  "user_id"
    t.boolean  "is_push_notification",  default: true
    t.boolean  "is_email_notification", default: true
    t.boolean  "is_text_notification",  default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "driver_settings", force: true do |t|
    t.integer  "user_id"
    t.boolean  "is_job_push"
    t.boolean  "is_rating_push"
    t.boolean  "is_message_push"
    t.boolean  "is_job_email"
    t.boolean  "is_rating_email"
    t.boolean  "is_message_email"
    t.float    "distance_push"
    t.float    "distance_email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "distance",         default: 99.0
  end

  create_table "file_claims", force: true do |t|
    t.integer  "job_id"
    t.string   "description"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "subject"
    t.string   "status"
  end

  create_table "jobs", force: true do |t|
    t.integer  "customer_id"
    t.string   "customer_type"
    t.integer  "driver_id"
    t.string   "driver_type"
    t.integer  "sender_location_id"
    t.string   "sender_location_type"
    t.integer  "receiver_location_id"
    t.string   "receiver_location_type"
    t.integer  "package_id"
    t.string   "status",                 default: "unavailable"
    t.datetime "pick_up_time"
    t.datetime "delivery_time"
    t.boolean  "is_active"
    t.float    "amount"
    t.string   "distance_text"
    t.string   "time_text"
    t.integer  "distance_value"
    t.integer  "time_value"
    t.string   "job_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "pick_up_address"
    t.string   "pick_up_phone"
    t.text     "pick_up_comment"
    t.text     "destination_address"
    t.string   "recipient_name"
    t.string   "recipient_phone"
    t.text     "recipient_comment"
    t.float    "latitude"
    t.float    "longitude"
    t.float    "dest_latitude"
    t.float    "dest_longitude"
    t.datetime "delivered_date"
    t.float    "job_tax",                default: 0.0
    t.boolean  "is_driver_payment_sent", default: false
    t.boolean  "is_read",                default: false
    t.integer  "payment_method_id"
    t.integer  "billing_address_id"
    t.float    "discount"
    t.boolean  "is_time_out",            default: false
    t.string   "recipient_email"
    t.string   "pick_up_email"
    t.string   "sender_suit_number"
    t.string   "recipient_suit_number"
    t.datetime "accepted_time"
    t.boolean  "is_web",                 default: false
  end

  create_table "locations", force: true do |t|
    t.integer  "user_id"
    t.text     "address"
    t.string   "contact_person"
    t.string   "contact_phone"
    t.string   "nick_name"
    t.text     "comments"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.integer  "zip_code"
    t.float    "latitude"
    t.float    "longitude"
    t.boolean  "is_active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "contact_method_type"
    t.string   "house_no"
    t.string   "contact_email"
  end

  create_table "messages", force: true do |t|
    t.integer  "sender_id"
    t.string   "sender_type"
    t.integer  "receiver_id"
    t.string   "receiver_type"
    t.string   "subject"
    t.text     "description"
    t.string   "status"
    t.string   "message_type"
    t.integer  "job_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "sender_deleted",   default: false
    t.boolean  "receiver_deleted", default: false
    t.integer  "parent_id"
    t.string   "parent_type"
  end

  create_table "packages", force: true do |t|
    t.string   "name"
    t.float    "weight"
    t.string   "description"
    t.float    "amount"
    t.integer  "user_id"
    t.float    "basic_fee"
    t.float    "cost_per_mile"
    t.float    "min_fare"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payment_methods", force: true do |t|
    t.string   "holder_name"
    t.integer  "month"
    t.integer  "year"
    t.integer  "cvv"
    t.string   "card_number"
    t.integer  "user_id"
    t.string   "nick_name"
    t.string   "token"
    t.boolean  "is_active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "card_type"
    t.boolean  "is_deleted",  default: false
  end

  create_table "phone_types", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "preferences", force: true do |t|
    t.float    "package_tax_percentage"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "profiles", force: true do |t|
    t.integer  "user_id"
    t.string   "phone_number"
    t.integer  "phone_type_id"
    t.integer  "vehicle_type_id"
    t.string   "address"
    t.string   "city"
    t.string   "state"
    t.string   "zip_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "redactor_assets", force: true do |t|
    t.string   "asset_file_name"
    t.string   "asset_content_type"
    t.integer  "asset_file_size"
    t.datetime "asset_updated_at"
  end

  create_table "reviews", force: true do |t|
    t.integer  "customer_id"
    t.string   "customer_type"
    t.integer  "driver_id"
    t.string   "driver_type"
    t.integer  "job_id"
    t.string   "subject"
    t.string   "description"
    t.float    "rating"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status"
  end

  create_table "roles", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles_users", force: true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "subjects", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transaction_histories", force: true do |t|
    t.string   "transaction_id"
    t.string   "status"
    t.string   "transaction_type"
    t.float    "amount"
    t.integer  "user_id"
    t.integer  "payment_method_id"
    t.integer  "job_id"
    t.integer  "billing_address_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "driver_amount"
    t.float    "ziply_revenue"
    t.float    "brain_tree_fee"
    t.float    "ziply_gross_revenue"
  end

  create_table "travelling_times", force: true do |t|
    t.integer  "user_id"
    t.datetime "clock_in"
    t.datetime "clock_out"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "latitude"
    t.float    "longitude"
    t.float    "total_miles", default: 0.0
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "",   null: false
    t.string   "encrypted_password",     default: "",   null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,    null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "facebook_uid"
    t.string   "customer_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "status"
    t.boolean  "send_email"
    t.datetime "email_sent_at"
    t.boolean  "is_disabled",            default: true
    t.string   "driver_id"
    t.string   "authentication_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "device_token"
    t.string   "device_type"
    t.string   "facebook_id"
    t.datetime "date_of_birth"
    t.string   "driver_code"
    t.string   "company_name"
    t.string   "time_zone"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
  add_index "users", ["driver_id"], name: "index_users_on_driver_id", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "vehicle_types", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
