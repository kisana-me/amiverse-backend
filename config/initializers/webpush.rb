# frozen_string_literal: true

# VAPID keys for Web Push
# Generated with WebPush.generate_key
# vapid_key = WebPush.generate_key; puts vapid_key.public_key; puts vapid_key.private_key;

Rails.application.configure do
  config.x.vapid_public_key = Rails.application.credentials.dig(:webpush, :public_key)
  config.x.vapid_private_key = Rails.application.credentials.dig(:webpush, :private_key)
end
