json.csrf_token form_authenticity_token

json.is_signed_in @current_account.present?
if @current_account
  json.account do
    json.aid @current_account.aid
    json.name @current_account.name
    json.name_id @current_account.name_id
    json.icon_url @current_account.icon_url
    json.description @current_account.description
    json.followers_count 1
    json.following_count 2
    json.statuses_count 3
  end
end
