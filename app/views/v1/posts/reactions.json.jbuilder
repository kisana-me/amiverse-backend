json.reactions @reactions do |reaction|
  json.account do
    json.partial! 'v1/accounts/account', account: reaction.account
  end
  json.emoji do
    json.extract! reaction.emoji, :aid, :name
    json.image_url reaction.emoji.image ? reaction.emoji.emoji_url : nil
  end
end

json.emojis @emojis do |emoji|
  json.extract! emoji, :aid, :name
  json.image_url emoji.image ? emoji.emoji_url : nil
end
