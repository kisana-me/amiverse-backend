json.status 'success'
json.data do
  json.array! @notifications do |notification|
    json.extract! notification, :aid, :action, :content, :checked, :created_at

    if notification.actor
      json.actor do
        json.partial! 'v1/accounts/account', account: notification.actor
      end
    else
      json.actor nil
    end

    if notification.notifiable_type == 'Post' && notification.notifiable
      json.post do
        json.partial! 'v1/posts/post', post: notification.notifiable, light: true
      end
    else
      json.post nil
    end
  end
end
