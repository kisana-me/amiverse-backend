json.extract! post, :aid, :content, :visibility, :created_at
json.account do
  json.partial! "v1/accounts/account", account: post.account
end
