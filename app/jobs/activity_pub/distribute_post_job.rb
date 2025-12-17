module ActivityPub
  class DistributePostJob < ApplicationJob
    queue_as :default

    def perform(post_id)
      post = ::Post.find_by(id: post_id)
      return unless post

      account = post.account
      return unless account.activity_pub_profile

      payload = ActivityPub::Serializer::Create.new(post).to_json

      inbox_urls = []

      account.followers.includes(:activity_pub_profile).find_each do |follower|
        # リモートアカウントのみ対象
        next if follower.activity_pub_instance_id.nil?
        
        profile = follower.activity_pub_profile
        next unless profile

        # Shared Inboxがあれば優先して使用、なければ個別のInbox
        inbox_urls << (profile.shared_inbox_url.presence || profile.inbox_url)
      end

      # 重複を排除して配送
      inbox_urls.compact.uniq.each do |inbox_url|
        ActivityPub::DeliveryJob.perform_later(account.id, inbox_url, payload)
      end
    end
  end
end
