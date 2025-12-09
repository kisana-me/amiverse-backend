module SignatureVerification
  extend ActiveSupport::Concern

  included do
    before_action :verify_signature
  end

  private

  def verify_signature
    # 署名ヘッダーがない場合はエラー
    unless request.headers['Signature'].present?
      render json: { error: 'Signature header is missing' }, status: :unauthorized
      return
    end

    # 署名ヘッダーのパース
    signature_header = request.headers['Signature']
    params = signature_header.split(',').map { |part| part.split('=', 2) }.to_h
    params.transform_values! { |v| v.gsub(/^"(.*)"$/, '\1') }

    key_id = params['keyId']
    signature = Base64.decode64(params['signature'])
    headers = params['headers'] || '(request-target) date' # デフォルトは (request-target) date

    # 公開鍵の取得 (ActorのURIから)
    # ここでは簡易的に実装していますが、実際にはDBキャッシュを確認し、なければHTTPリクエストで取得する処理が必要です
    actor = fetch_actor(key_id)
    unless actor
      render json: { error: 'Actor not found' }, status: :unauthorized
      return
    end

    public_key = OpenSSL::PKey::RSA.new(actor[:public_key])

    # 署名対象文字列の構築
    comparison_string = headers.split(' ').map do |header|
      if header == '(request-target)'
        "(request-target): #{request.method.downcase} #{request.path}"
      elsif header == 'host'
        "host: #{request.host}"
      else
        "#{header}: #{request.headers[header.split('-').map(&:capitalize).join('-')]}"
      end
    end.join("\n")

    # 署名の検証
    unless public_key.verify(OpenSSL::Digest::SHA256.new, signature, comparison_string)
      render json: { error: 'Invalid signature' }, status: :unauthorized
    end
  rescue => e
    Rails.logger.error "Signature verification failed: #{e.message}"
    render json: { error: 'Signature verification failed' }, status: :unauthorized
  end

  def fetch_actor(key_id)
    uri = key_id.split('#').first

    # ResolveActorService を使用して取得・保存
    profile = ActivityPub::ResolveActorService.call(uri)

    return { public_key: profile.public_key } if profile

    nil
  end
end
