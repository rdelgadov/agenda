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

ActiveRecord::Schema.define(version: 2019_12_28_203656) do

  create_table "medics", force: :cascade do |t|
    t.string "name"
    t.string "rut"
    t.string "phone"
    t.string "type"
    t.string "color"
    t.string "attention"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "people", force: :cascade do |t|
    t.string "name"
    t.string "rut"
    t.string "phone"
    t.bigint "bp"
    t.string "first_name"
    t.string "second_name"
    t.boolean "rest"
    t.boolean "transportation"
    t.string "latitude"
    t.string "longitude"
    t.integer "vehicle_type"
    t.string "town"
    t.string "address"
    t.boolean "accompanied"
    t.string "address_number"
    t.integer "number_of_days"
    t.integer "travels_type"
    t.date "dates"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "person_dates", force: :cascade do |t|
    t.date "date"
    t.string "time"
    t.integer "person_id"
    t.integer "medic_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["medic_id"], name: "index_person_dates_on_medic_id"
    t.index ["person_id"], name: "index_person_dates_on_person_id"
  end

end
