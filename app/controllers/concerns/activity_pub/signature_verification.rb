module ActivityPub
  module SignatureVerification
    extend ActiveSupport::Concern

    included do
      before_action :verify_signature
    end

    private

    def verify_signature
      return if request.headers['Signature'].blank?

      signature_header = parse_signature_header(request.headers['Signature'])
      unless signature_header
        render_unauthorized('Invalid signature header')
        return
      end

      key_id = signature_header['keyId']
      actor = fetch_actor(key_id)
      unless actor
        render_unauthorized('Actor not found')
        return
      end

      public_key = OpenSSL::PKey::RSA.new(actor.public_key)
      
      comparison_string = build_comparison_string(signature_header, request)
      signature = Base64.decode64(signature_header['signature'])

      unless public_key.verify(OpenSSL::Digest::SHA256.new, signature, comparison_string)
        render_unauthorized('Verification failed')
      end
    rescue => e
      Rails.logger.error "Signature verification failed: #{e.message}"
      render_unauthorized('Verification error')
    end

    def parse_signature_header(header)
      header.split(',').map { |part| part.split('=', 2) }.to_h.transform_values { |v| v.gsub(/^"(.*)"$/, '\1') }
    rescue
      nil
    end

    def fetch_actor(key_id)
      uri = key_id.split('#').first
      ActivityPub::Resolve::Actor.by_uri(uri)
    end

    def build_comparison_string(signature_header, request)
      headers = (signature_header['headers'] || '(request-target) date').split(' ')
      headers.map do |header|
        if header == '(request-target)'
          "(request-target): #{request.method.downcase} #{request.path}"
        elsif header == 'host'
          "host: #{request.host}"
        else
          value = request.headers[header] || request.headers[header.split('-').map(&:capitalize).join('-')]
          "#{header}: #{value}"
        end
      end.join("\n")
    end

    def render_unauthorized(message = 'Unauthorized')
      Rails.logger.warn "AP signature verification unauthorized access: #{message}"
      render json: { error: message }, status: :unauthorized
    end
  end
end
