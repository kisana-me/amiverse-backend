json.partial! 'v1/posts/post', post: @post, reply_to: true, quote_to: true, reactions: true
json.replies @post.replies, partial: 'v1/posts/post', as: :post, quote_to: true, reactions: true
