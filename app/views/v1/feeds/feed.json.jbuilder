json.posts do
  json.array! @posts do |post|
    json.partial! 'v1/posts/post', post: post, quote_to: true, reactions: true, display_media: true
  end
end

json.feed do
  json.array! @feeds do |feed|
    json.type feed[:type]
    json.post_aid feed[:post_aid]
    if feed[:type] == 'diffuse'
      json.account do
        json.aid feed[:account][:aid]
        json.name feed[:account][:name]
        json.name_id feed[:account][:name_id]
        json.icon_url feed[:account][:icon_url]
      end
      json.created_at feed[:created_at]
    end
  end
end
