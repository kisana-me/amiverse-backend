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

json.is_following @current_account.present? ? @current_account.following.exists?(@account.id) : false
json.is_followed @current_account.present? ? @account.following.exists?(@current_account.id) : false

json.icon_url @account.icon_url
json.banner_url @account.banner_url
