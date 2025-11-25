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

ActiveRecord::Schema[8.1].define(version: 15) do
  create_table "accounts", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "aid", limit: 14, null: false
    t.bigint "banner_id"
    t.datetime "birthdate"
    t.datetime "created_at", null: false
    t.text "description", default: "", null: false
    t.string "email"
    t.boolean "email_verified", default: false, null: false
    t.bigint "icon_id"
    t.text "meta", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.string "name", null: false
    t.string "name_id", null: false
    t.string "password_digest"
    t.integer "status", limit: 1, default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "visibility", limit: 1, default: 0, null: false
    t.index ["aid"], name: "index_accounts_on_aid", unique: true
    t.index ["banner_id"], name: "index_accounts_on_banner_id"
    t.index ["email"], name: "index_accounts_on_email", unique: true
    t.index ["icon_id"], name: "index_accounts_on_icon_id"
    t.index ["name_id"], name: "index_accounts_on_name_id", unique: true
    t.check_constraint "json_valid(`meta`)", name: "meta"
  end

  create_table "diffuses", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_diffuses_on_account_id"
    t.index ["post_id"], name: "index_diffuses_on_post_id"
  end

  create_table "emojis", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "aid", null: false
    t.datetime "created_at", null: false
    t.text "description", default: "", null: false
    t.string "group", default: "", null: false
    t.bigint "image_id"
    t.text "meta", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.string "name", default: "", null: false
    t.string "name_id", null: false
    t.integer "status", limit: 1, default: 0, null: false
    t.string "subgroup", default: "", null: false
    t.datetime "updated_at", null: false
    t.index ["aid"], name: "index_emojis_on_aid", unique: true
    t.index ["group"], name: "index_emojis_on_group"
    t.index ["image_id"], name: "index_emojis_on_image_id"
    t.index ["name_id"], name: "index_emojis_on_name_id", unique: true
    t.index ["subgroup"], name: "index_emojis_on_subgroup"
    t.check_constraint "json_valid(`meta`)", name: "meta"
  end

  create_table "follows", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.boolean "accepted", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "followed_id", null: false
    t.bigint "follower_id", null: false
    t.datetime "updated_at", null: false
    t.index ["followed_id", "follower_id"], name: "index_follows_on_followed_id_and_follower_id", unique: true
    t.index ["followed_id"], name: "index_follows_on_followed_id"
    t.index ["follower_id"], name: "index_follows_on_follower_id"
  end

  create_table "images", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "account_id"
    t.string "aid", limit: 14, null: false
    t.datetime "created_at", null: false
    t.text "description", default: "", null: false
    t.text "meta", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.string "name", default: "", null: false
    t.string "original_ext", null: false
    t.integer "status", limit: 1, default: 0, null: false
    t.datetime "updated_at", null: false
    t.text "variants", size: :long, default: "[]", null: false, collation: "utf8mb4_bin"
    t.integer "visibility", limit: 1, default: 0, null: false
    t.index ["account_id"], name: "index_images_on_account_id"
    t.index ["aid"], name: "index_images_on_aid", unique: true
    t.check_constraint "json_valid(`meta`)", name: "meta"
    t.check_constraint "json_valid(`variants`)", name: "variants"
  end

  create_table "oauth_accounts", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.text "access_token", null: false
    t.bigint "account_id", null: false
    t.string "aid", limit: 14, null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "fetched_at", null: false
    t.text "meta", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.integer "provider", limit: 1, null: false
    t.text "refresh_token", null: false
    t.integer "status", limit: 1, default: 0, null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_oauth_accounts_on_account_id"
    t.index ["aid"], name: "index_oauth_accounts_on_aid", unique: true
    t.index ["provider", "uid"], name: "index_oauth_accounts_on_provider_and_uid", unique: true
    t.check_constraint "json_valid(`meta`)", name: "meta"
  end

  create_table "post_images", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "image_id", null: false
    t.bigint "post_id", null: false
    t.datetime "updated_at", null: false
    t.index ["image_id"], name: "index_post_images_on_image_id"
    t.index ["post_id"], name: "index_post_images_on_post_id"
  end

  create_table "post_tags", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_post_tags_on_post_id"
    t.index ["tag_id"], name: "index_post_tags_on_tag_id"
  end

  create_table "post_videos", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "video_id", null: false
    t.index ["post_id"], name: "index_post_videos_on_post_id"
    t.index ["video_id"], name: "index_post_videos_on_video_id"
  end

  create_table "posts", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "aid", limit: 14, null: false
    t.text "content", default: "", null: false
    t.datetime "created_at", null: false
    t.text "meta", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.bigint "quote_id"
    t.bigint "reply_id"
    t.integer "status", limit: 1, default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "visibility", limit: 1, default: 0, null: false
    t.index ["account_id"], name: "index_posts_on_account_id"
    t.index ["aid"], name: "index_posts_on_aid", unique: true
    t.index ["quote_id"], name: "index_posts_on_quote_id"
    t.index ["reply_id"], name: "index_posts_on_reply_id"
    t.check_constraint "json_valid(`meta`)", name: "meta"
  end

  create_table "reactions", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.bigint "emoji_id", null: false
    t.bigint "post_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_reactions_on_account_id"
    t.index ["emoji_id"], name: "index_reactions_on_emoji_id"
    t.index ["post_id"], name: "index_reactions_on_post_id"
  end

  create_table "sessions", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "aid", limit: 14, null: false
    t.datetime "created_at", null: false
    t.text "meta", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.string "name", default: "", null: false
    t.integer "status", limit: 1, default: 0, null: false
    t.string "token_digest", null: false
    t.datetime "token_expires_at", null: false
    t.datetime "token_generated_at", null: false
    t.string "token_lookup", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_sessions_on_account_id"
    t.index ["aid"], name: "index_sessions_on_aid", unique: true
    t.index ["token_lookup"], name: "index_sessions_on_token_lookup", unique: true
    t.check_constraint "json_valid(`meta`)", name: "meta"
  end

  create_table "tags", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "videos", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "account_id"
    t.string "aid", limit: 14, null: false
    t.datetime "created_at", null: false
    t.text "description", default: "", null: false
    t.text "meta", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.string "name", default: "", null: false
    t.string "original_ext", null: false
    t.integer "status", limit: 1, default: 0, null: false
    t.datetime "updated_at", null: false
    t.text "variants", size: :long, default: "[]", null: false, collation: "utf8mb4_bin"
    t.integer "visibility", limit: 1, default: 0, null: false
    t.index ["account_id"], name: "index_videos_on_account_id"
    t.index ["aid"], name: "index_videos_on_aid", unique: true
    t.check_constraint "json_valid(`meta`)", name: "meta"
    t.check_constraint "json_valid(`variants`)", name: "variants"
  end

  add_foreign_key "accounts", "images", column: "banner_id"
  add_foreign_key "accounts", "images", column: "icon_id"
  add_foreign_key "diffuses", "accounts"
  add_foreign_key "diffuses", "posts"
  add_foreign_key "emojis", "images"
  add_foreign_key "follows", "accounts", column: "followed_id"
  add_foreign_key "follows", "accounts", column: "follower_id"
  add_foreign_key "images", "accounts"
  add_foreign_key "oauth_accounts", "accounts"
  add_foreign_key "post_images", "images"
  add_foreign_key "post_images", "posts"
  add_foreign_key "post_tags", "posts"
  add_foreign_key "post_tags", "tags"
  add_foreign_key "post_videos", "posts"
  add_foreign_key "post_videos", "videos"
  add_foreign_key "posts", "accounts"
  add_foreign_key "posts", "posts", column: "quote_id"
  add_foreign_key "posts", "posts", column: "reply_id"
  add_foreign_key "reactions", "accounts"
  add_foreign_key "reactions", "emojis"
  add_foreign_key "reactions", "posts"
  add_foreign_key "sessions", "accounts"
  add_foreign_key "videos", "accounts"
end
