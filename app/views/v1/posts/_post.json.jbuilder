json.extract! post, :aid, :content, :visibility, :created_at
json.reply_presence post.reply_id.present?
json.quote_presence post.quote_id.present?

unless defined? light # typeでは必須
  json.replies_count post.replies.size
  json.quotes_count post.quotes.size
  json.views_count 0 # のちのち実装する

  json.diffuses_count post.diffuses.size
  json.is_diffused @current_account ? post.diffuses.any? { |d| d.account_id == @current_account.id } : false

  my_reacted_emoji_ids = @current_account ? post.reactions.select { |r| r.account_id == @current_account.id }.map(&:emoji_id) : []
  emoji_counts = post.reactions.group_by(&:emoji).transform_values(&:size)
  json.reactions_count post.reactions.size
  json.is_reacted my_reacted_emoji_ids.any?
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
    json.array! emoji_counts.keys do |emoji|
      json.partial! 'v1/emojis/emoji', emoji: emoji
      json.reactions_count emoji_counts[emoji]
      json.reacted my_reacted_emoji_ids.include?(emoji.id)
    end
  end
end

json.media do
  media_items = []
  post.images.each do |image|
    media_items << {
      type: "image",
      aid: image.aid,
      name: image.name,
      description: image.description,
      url: image.image_url
    }
  end
  post.videos.each do |video|
    media_items << {
      type: "video",
      aid: video.aid,
      name: video.name,
      description: video.description,
      url: video.video_url
    }
  end

  json.array! media_items do |item|
    json.type item[:type]
    json.aid item[:aid]
    json.name item[:name]
    json.description item[:description]
    json.url item[:url]
  end
end

json.videos []

json.account do
  json.partial! 'v1/accounts/account', account: post.account
end
