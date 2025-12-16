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
      return render_unauthorized unless signature_header

      key_id = signature_header['keyId']
      actor = fetch_actor(key_id)
      return render_unauthorized unless actor

      public_key = OpenSSL::PKey::RSA.new(actor['publicKey']['publicKeyPem'])
      
      comparison_string = build_comparison_string(signature_header, request)
      signature = Base64.decode64(signature_header['signature'])

      unless public_key.verify(OpenSSL::Digest::SHA256.new, signature, comparison_string)
        render_unauthorized
      end
    rescue => e
      Rails.logger.error "Signature verification failed: #{e.message}"
      render_unauthorized
    end

    def parse_signature_header(header)
      header.split(',').map { |part| part.split('=', 2) }.to_h.transform_values { |v| v.delete('"') }
    end

    def fetch_actor(key_id)
      # In a real implementation, we should cache this.
      # Also, we need to handle the case where key_id is the actor URL or a key URL.
      # Usually key_id is like https://example.com/users/alice#main-key
      
      # For simplicity, we'll just fetch the key_id URL.
      # If it returns a Key object, use owner. If it returns Person, use publicKey.
      
      uri = URI(key_id)
      response = Net::HTTP.get_response(uri)
      return nil unless response.is_a?(Net::HTTPSuccess)

      json = JSON.parse(response.body)
      
      if json['type'] == 'Person' || json['type'] == 'Service' || json['type'] == 'Application'
        json
      elsif json['owner']
        # It's a Key object, fetch the owner
        fetch_actor(json['owner'])
      else
        nil
      end
    rescue
      nil
    end

    def build_comparison_string(signature_header, request)
      headers = signature_header['headers'].split(' ')
      headers.map do |header|
        if header == '(request-target)'
          "(request-target): #{request.method.downcase} #{request.path}"
        else
          "#{header}: #{request.headers[header]}"
        end
      end.join("\n")
    end

    def render_unauthorized
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end
