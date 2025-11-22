json.posts @posts, partial: 'v1/posts/post', as: :post, quote_to: true, reactions: true
json.feed do
  json.type 'home'

  json.objects @posts do |post|
    json.type 'post'
    json.aid post.aid
  end
end
