json.extract! post, :aid, :content, :visibility, :created_at
json.reply_presence post.reply_id.present?
json.quote_presence post.quote_id.present?

unless defined? light
  json.replies_count post.replies.size
  json.quotes_count post.quotes.size
end

if defined? reply_to
  json.reply do
    if post.reply
      json.partial! "v1/posts/post", post: post.reply, quote_to: true
    else
      json.null!
    end
  end
end

if defined? quote_to
  json.quote do
    if post.quote
      json.partial! "v1/posts/post", post: post.quote
    else
      json.null!
    end
  end
end

json.account do
  json.partial! "v1/accounts/account", account: post.account
end
