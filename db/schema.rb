# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_07_10_110534) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "access_tokens", force: :cascade do |t|
    t.string "name"
    t.string "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_access_tokens_on_key", unique: true
    t.index ["name"], name: "index_access_tokens_on_name", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.string "line1", null: false
    t.string "line2"
    t.string "city", null: false
    t.string "state", null: false
    t.string "zip", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "course_content_histories", force: :cascade do |t|
    t.bigint "course_content_id", null: false
    t.string "title"
    t.text "body"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id"
    t.index ["course_content_id"], name: "index_course_content_histories_on_course_content_id"
    t.index ["user_id"], name: "index_course_content_histories_on_user_id"
  end

  create_table "course_contents", force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.datetime "published_at"
    t.string "content_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "course_id"
    t.string "secondary_id"
    t.string "course_name"
  end

  create_table "emails", force: :cascade do |t|
    t.string "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["value"], name: "index_emails_on_value"
  end

  create_table "grade_categories", force: :cascade do |t|
    t.bigint "program_id", null: false
    t.string "name", null: false
    t.float "percent_of_grade"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["program_id"], name: "index_grade_categories_on_program_id"
  end

  create_table "industries", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_industries_on_name"
  end

  create_table "interests", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_interests_on_name"
  end

  create_table "keypairs", force: :cascade do |t|
    t.string "jwk_kid", null: false
    t.string "encrypted__keypair", null: false
    t.string "encrypted__keypair_iv", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_keypairs_on_created_at"
    t.index ["jwk_kid"], name: "index_keypairs_on_jwk_kid"
  end

  create_table "lesson_submissions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "lesson_id", null: false
    t.float "points_received"
    t.datetime "submitted_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["lesson_id"], name: "index_lesson_submissions_on_lesson_id"
    t.index ["user_id"], name: "index_lesson_submissions_on_user_id"
  end

  create_table "lessons", force: :cascade do |t|
    t.bigint "grade_category_id", null: false
    t.string "name", null: false
    t.integer "points_possible", null: false
    t.float "percent_of_grade_category", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["grade_category_id"], name: "index_lessons_on_grade_category_id"
  end

  create_table "location_relationships", id: false, force: :cascade do |t|
    t.integer "parent_id"
    t.integer "child_id"
    t.index ["child_id"], name: "index_location_relationships_on_child_id"
    t.index ["parent_id", "child_id"], name: "index_location_relationships_on_parent_id_and_child_id"
    t.index ["parent_id"], name: "index_location_relationships_on_parent_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_locations_on_code", unique: true
    t.index ["name"], name: "index_locations_on_name", unique: true
  end

  create_table "login_tickets", force: :cascade do |t|
    t.string "ticket", null: false
    t.datetime "created_on", null: false
    t.datetime "created_at", null: false
    t.datetime "consumed"
    t.string "client_hostname", null: false
  end

  create_table "logistics", force: :cascade do |t|
    t.string "day_of_week", null: false
    t.string "time_of_day", null: false
    t.integer "program_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["day_of_week", "time_of_day", "program_id"], name: "index_logistics_on_day_of_week_and_time_of_day_and_program_id", unique: true
  end

  create_table "lti_launches", force: :cascade do |t|
    t.string "client_id", null: false
    t.string "login_hint", null: false
    t.text "lti_message_hint"
    t.string "target_link_uri", null: false
    t.string "nonce"
    t.string "state", null: false
    t.text "id_token_payload"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["state"], name: "index_lti_launches_on_state", unique: true
  end

  create_table "majors", force: :cascade do |t|
    t.string "name"
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_majors_on_name"
    t.index ["parent_id"], name: "index_majors_on_parent_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name"], name: "index_organizations_on_name", unique: true
  end

  create_table "phones", force: :cascade do |t|
    t.string "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["value"], name: "index_phones_on_value", unique: true
  end

  create_table "postal_codes", force: :cascade do |t|
    t.string "code"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "msa_code"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "city"
    t.index ["code"], name: "index_postal_codes_on_code", unique: true
    t.index ["state"], name: "index_postal_codes_on_state"
  end

  create_table "program_memberships", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "program_id", null: false
    t.integer "role_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["program_id"], name: "index_program_memberships_on_program_id"
    t.index ["role_id"], name: "index_program_memberships_on_role_id"
    t.index ["user_id", "program_id", "role_id"], name: "program_memberships_index"
    t.index ["user_id"], name: "index_program_memberships_on_user_id"
  end

  create_table "programs", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "term", null: false
    t.integer "organization_id", null: false
    t.string "type"
    t.index ["name", "term", "organization_id"], name: "index_programs_on_name_and_term_and_organization_id", unique: true
    t.index ["name"], name: "index_programs_on_name", unique: true
  end

  create_table "project_submissions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "project_id", null: false
    t.float "points_received"
    t.datetime "submitted_at"
    t.datetime "graded_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["project_id"], name: "index_project_submissions_on_project_id"
    t.index ["user_id"], name: "index_project_submissions_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.bigint "grade_category_id", null: false
    t.string "name", null: false
    t.integer "points_possible", null: false
    t.float "percent_of_grade_category", null: false
    t.boolean "grades_muted", default: false, null: false
    t.datetime "grades_published_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["grade_category_id"], name: "index_projects_on_grade_category_id"
  end

  create_table "proxy_granting_tickets", force: :cascade do |t|
    t.string "ticket", null: false
    t.datetime "created_on", null: false
    t.datetime "created_at", null: false
    t.string "client_hostname", null: false
    t.string "iou", null: false
    t.bigint "service_ticket_id"
    t.index ["service_ticket_id"], name: "index_proxy_granting_tickets_on_service_ticket_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "rubric_grades", force: :cascade do |t|
    t.bigint "project_submission_id", null: false
    t.bigint "rubric_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["project_submission_id"], name: "index_rubric_grades_on_project_submission_id", unique: true
    t.index ["rubric_id"], name: "index_rubric_grades_on_rubric_id"
  end

  create_table "rubric_row_categories", force: :cascade do |t|
    t.bigint "rubric_id", null: false
    t.string "name", null: false
    t.integer "position", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["rubric_id"], name: "index_rubric_row_categories_on_rubric_id"
  end

  create_table "rubric_row_grades", force: :cascade do |t|
    t.bigint "rubric_grade_id", null: false
    t.bigint "rubric_row_id", null: false
    t.integer "points_given"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["rubric_grade_id"], name: "index_rubric_row_grades_on_rubric_grade_id"
    t.index ["rubric_row_id"], name: "index_rubric_row_grades_on_rubric_row_id"
  end

  create_table "rubric_row_ratings", force: :cascade do |t|
    t.bigint "rubric_row_id", null: false
    t.string "description", null: false
    t.integer "points_value", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["rubric_row_id"], name: "index_rubric_row_ratings_on_rubric_row_id"
  end

  create_table "rubric_rows", force: :cascade do |t|
    t.bigint "rubric_row_category_id", null: false
    t.string "criterion", null: false
    t.integer "points_possible", null: false
    t.integer "position", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["rubric_row_category_id"], name: "index_rubric_rows_on_rubric_row_category_id"
  end

  create_table "rubrics", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "name"
    t.integer "points_possible", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["project_id"], name: "index_rubrics_on_project_id", unique: true
  end

  create_table "sections", force: :cascade do |t|
    t.string "name", null: false
    t.integer "logistic_id", null: false
    t.integer "program_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name", "program_id"], name: "index_sections_on_name_and_program_id", unique: true
  end

  create_table "service_tickets", force: :cascade do |t|
    t.string "ticket", null: false
    t.string "service", null: false
    t.datetime "created_on", null: false
    t.datetime "created_at", null: false
    t.datetime "consumed"
    t.string "client_hostname", null: false
    t.string "username", null: false
    t.integer "proxy_granting_ticket_id"
    t.integer "ticket_granting_ticket_id"
  end

  create_table "ticket_granting_tickets", force: :cascade do |t|
    t.string "ticket", null: false
    t.datetime "created_on", null: false
    t.datetime "created_at", null: false
    t.string "client_hostname", null: false
    t.string "username", null: false
    t.string "remember_me", null: false
    t.string "extra_attributes", null: false
  end

  create_table "user_sections", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "section_id", null: false
    t.string "type", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["section_id"], name: "index_user_sections_on_section_id"
    t.index ["user_id", "section_id"], name: "index_user_sections_on_user_id_and_section_id", unique: true
    t.index ["user_id"], name: "index_user_sections_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.boolean "admin", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.string "first_name", default: "", null: false
    t.string "middle_name"
    t.string "last_name", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "salesforce_id"
    t.integer "canvas_id"
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["canvas_id"], name: "index_users_on_canvas_id", unique: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "course_content_histories", "course_contents"
  add_foreign_key "course_content_histories", "users"
  add_foreign_key "grade_categories", "programs"
  add_foreign_key "lesson_submissions", "lessons"
  add_foreign_key "lesson_submissions", "users"
  add_foreign_key "lessons", "grade_categories"
  add_foreign_key "logistics", "programs"
  add_foreign_key "programs", "organizations"
  add_foreign_key "project_submissions", "projects"
  add_foreign_key "project_submissions", "users"
  add_foreign_key "projects", "grade_categories"
  add_foreign_key "rubric_grades", "project_submissions"
  add_foreign_key "rubric_grades", "rubrics"
  add_foreign_key "rubric_row_categories", "rubrics"
  add_foreign_key "rubric_row_grades", "rubric_grades"
  add_foreign_key "rubric_row_grades", "rubric_rows"
  add_foreign_key "rubric_row_ratings", "rubric_rows"
  add_foreign_key "rubric_rows", "rubric_row_categories"
  add_foreign_key "rubrics", "projects"
  add_foreign_key "sections", "logistics"
  add_foreign_key "sections", "programs"
  add_foreign_key "user_sections", "sections"
  add_foreign_key "user_sections", "users"
end
