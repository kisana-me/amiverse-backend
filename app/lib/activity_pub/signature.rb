require 'base64'
require 'openssl'
require 'time'

module ActivityPub
  class Signature
    def initialize(key_id, private_key_pem)
      @key_id = key_id
      @private_key = OpenSSL::PKey::RSA.new(private_key_pem)
    end

    def sign(method, path, headers, body = nil)
      headers = headers.dup
      headers['Date'] = Time.now.utc.httpdate

      if body
        digest = OpenSSL::Digest::SHA256.digest(body)
        headers['Digest'] = "SHA-256=#{Base64.strict_encode64(digest)}"
      end

      signed_string = build_signed_string(method, path, headers)
      signature = @private_key.sign(OpenSSL::Digest::SHA256.new, signed_string)
      signature_base64 = Base64.strict_encode64(signature)

      headers['Signature'] = build_signature_header(headers.keys, signature_base64)
      headers
    end

    private

    def build_signed_string(method, path, headers)
      lines = []
      lines << "(request-target): #{method.downcase} #{path}"

      headers_to_sign = ['Host', 'Date']
      headers_to_sign << 'Digest' if headers['Digest']

      headers_to_sign.each do |key|
        lines << "#{key.downcase}: #{headers[key]}"
      end

      lines.join("\n")
    end

    def build_signature_header(header_keys, signature)
      headers_to_sign = ['(request-target)', 'host', 'date']
      headers_to_sign << 'digest' if header_keys.include?('Digest')

      %(keyId="#{@key_id}",algorithm="rsa-sha256",headers="#{headers_to_sign.join(' ')}",signature="#{signature}")
    end
  end
end
