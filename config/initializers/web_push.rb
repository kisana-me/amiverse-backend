# frozen_string_literal: true

# VAPID keys for Web Push
# Generated with WebPush.generate_key
# Public:  BJxDjmXijZoQMGfNhUVO14-VqE-UcOVCWFYydHbG3v4ogG7Q9IM0j9gckT30B3hD_XLJGsII7-gbhSkeC7VhXG8=
# Private: ah2k8cUqxExW_RCMgcp8woLLMxhyCoZLM5l_77PTGEA=

Rails.application.configure do
  config.x.vapid_public_key = ENV.fetch('VAPID_PUBLIC_KEY', 'BJxDjmXijZoQMGfNhUVO14-VqE-UcOVCWFYydHbG3v4ogG7Q9IM0j9gckT30B3hD_XLJGsII7-gbhSkeC7VhXG8=')
  config.x.vapid_private_key = ENV.fetch('VAPID_PRIVATE_KEY', 'ah2k8cUqxExW_RCMgcp8woLLMxhyCoZLM5l_77PTGEA=')
end
