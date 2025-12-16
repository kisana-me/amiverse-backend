require 'net/http'

module ActivityPub
  class DeliveryService
    def initialize(source_account, target_inbox_url, activity_json)
      @source_account = source_account
      @target_inbox_url = target_inbox_url
      @activity_json = activity_json
    end

    def perform
      unless @source_account.activity_pub_profile
        return raise "Delivery failed: Can't find ActivityPub profile."
      end

      uri = URI.parse(@target_inbox_url)
      base_headers = {
        'Content-Type' => 'application/activity+json',
        'Host' => uri.host
      }
      signer = ActivityPub::Signature.new(key_id, private_key)
      path = uri.path.empty? ? '/' : uri.path
      signed_headers = signer.sign('POST', path, base_headers, @activity_json)
      request_headers = base_headers.merge(signed_headers || {})
      response = HttpService.post_request(@target_inbox_url, request_headers, @activity_json)

      unless response.is_a?(Net::HTTPSuccess)
        raise "Delivery failed: #{response.code} #{response.body}"
      end

      response
    end

    private

    def key_id
      "#{@source_account.activity_pub_profile&.uri}#main-key"
    end

    def private_key
      @source_account.activity_pub_profile&.private_key
    end
  end
end
