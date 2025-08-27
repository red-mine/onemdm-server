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

ActiveRecord::Schema[7.0].define(version: 2025_08_26_053757) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_id", null: false
    t.string "resource_type", null: false
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "app_batch_installations", force: :cascade do |t|
    t.bigint "app_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["app_id"], name: "index_app_batch_installations_on_app_id"
  end

  create_table "app_installations", force: :cascade do |t|
    t.bigint "device_id"
    t.bigint "app_batch_installation_id"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["app_batch_installation_id"], name: "index_app_installations_on_app_batch_installation_id"
    t.index ["device_id"], name: "index_app_installations_on_device_id"
  end

  create_table "app_usages", force: :cascade do |t|
    t.string "package_name", null: false
    t.integer "usage_duration_in_seconds", null: false
    t.date "used_on", null: false
    t.bigint "device_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_app_usages_on_device_id"
  end

  create_table "apps", force: :cascade do |t|
    t.string "name"
    t.string "package_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "devices", force: :cascade do |t|
    t.string "model"
    t.string "unique_id"
    t.string "imei_number"
    t.string "access_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "heartbeats_count", default: 0
    t.datetime "last_heartbeat_recd_time"
    t.string "gcm_token"
    t.string "client_version"
    t.string "os_version"
    t.integer "group_id"
    t.string "serial_no"
    t.string "finger_print"
    t.index ["group_id"], name: "index_devices_on_group_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "heartbeats", force: :cascade do |t|
    t.bigint "device_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_heartbeats_on_device_id"
  end

  create_table "pkg_batch_installations", force: :cascade do |t|
    t.bigint "pkg_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pkg_id"], name: "index_pkg_batch_installations_on_pkg_id"
  end

  create_table "pkg_installations", force: :cascade do |t|
    t.bigint "device_id"
    t.bigint "pkg_batch_installation_id"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_pkg_installations_on_device_id"
    t.index ["pkg_batch_installation_id"], name: "index_pkg_installations_on_pkg_batch_installation_id"
  end

  create_table "pkg_usages", force: :cascade do |t|
    t.string "finger_print", null: false
    t.integer "usage_duration_in_seconds", null: false
    t.date "used_on", null: false
    t.bigint "device_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_pkg_usages_on_device_id"
  end

  create_table "pkgs", force: :cascade do |t|
    t.string "name"
    t.string "finger_print"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "app_batch_installations", "apps"
  add_foreign_key "app_installations", "app_batch_installations"
  add_foreign_key "app_installations", "devices"
  add_foreign_key "app_usages", "devices"
  add_foreign_key "devices", "groups"
  add_foreign_key "heartbeats", "devices"
  add_foreign_key "pkg_batch_installations", "pkgs"
  add_foreign_key "pkg_installations", "devices"
  add_foreign_key "pkg_installations", "pkg_batch_installations"
  add_foreign_key "pkg_usages", "devices"
end
