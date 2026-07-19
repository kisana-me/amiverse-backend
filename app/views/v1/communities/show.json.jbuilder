json.extract! @community, :aid, :name, :description, :created_at
json.icon_url @community.icon_url
json.banner_url @community.banner_url
json.posts_count @community.posts.is_normal.count

if @community.founder.present?
  json.founder do
    json.partial! "v1/accounts/account", account: @community.founder
  end
else
  json.founder nil
end
