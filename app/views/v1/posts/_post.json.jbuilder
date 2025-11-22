json.extract! post, :aid, :content, :visibility, :created_at
json.reply_presence post.reply_id.present?
json.quote_presence post.quote_id.present?

unless defined? light # typeでは必須
  json.replies_count post.replies.size
  json.quotes_count post.quotes.size
  # のちのち実装する
  json.diffuses_count 0
  json.reactions_count 0
  json.views_count 0
  json.is_diffused false
  json.is_reacted false
end

if defined? reply_to
  json.reply do
    if post.reply
      json.partial! 'v1/posts/post', post: post.reply, quote_to: true
    else
      json.null!
    end
  end
end

if defined? quote_to
  json.quote do
    if post.quote
      json.partial! 'v1/posts/post', post: post.quote
    else
      json.null!
    end
  end
end

if defined? reactions
  json.reactions do
    json.array! reactions do |emoji|
      json.partial! 'v1/emojis/emoji', emoji: emoji
    end
  end
end

json.images []
json.videos []

json.account do
  json.partial! 'v1/accounts/account', account: post.account
end
