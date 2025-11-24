json.posts @posts, partial: 'v1/posts/post', as: :post, quote_to: true, reactions: true
json.feed @posts do |post|
  json.type 'post'
  json.post_aid post.aid
end
