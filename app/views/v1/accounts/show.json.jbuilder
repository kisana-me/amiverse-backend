json.extract! @account,
  :aid,
  :name,
  :name_id,
  :description,
  :birthdate,
  :visibility,
  :created_at

json.followers_count @account.followers.count
json.following_count @account.following.count
json.posts_count @account.posts.count

json.icon_url @account.icon_url
