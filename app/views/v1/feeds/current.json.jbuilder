
json.posts do
  json.array! @posts do |post|
    json.partial! 'v1/posts/post', post: post
  end
end

json.feed do
  json.array! @feeds do |feed|
    json.type feed[:type]
    json.post_aid feed[:post_aid]
    if feed[:type] == 'diffuse'
      json.account_aid feed[:account_aid]
      json.created_at feed[:created_at]
    end
  end
end
