module S3Tools
  # ver 1.1.0

  extend ActiveSupport::Concern

  require "aws-sdk-s3"

  class_methods do
    def s3_upload(key:, file:, content_type:)
      Aws::S3::TransferManager.new(client: s3_client).upload_file(
        file,
        bucket: ENV.fetch("S3_BUCKET"),
        key: normalize_key(key),
        content_type: content_type
      )
    end

    def s3_download(key:, response_target:)
      s3_client.get_object(bucket: ENV.fetch("S3_BUCKET"), key: normalize_key(key), response_target: response_target)
    end

    def s3_delete(key:)
      s3_client.delete_object(bucket: ENV.fetch("S3_BUCKET"), key: normalize_key(key))
    end

    def s3_list(prefix:)
      keys = []
      continuation_token = nil
      loop do
        resp = s3_client.list_objects_v2(
          bucket: ENV.fetch("S3_BUCKET"),
          prefix: normalize_key(prefix),
          continuation_token: continuation_token
        )
        keys.concat(resp.contents.map(&:key))
        break unless resp.is_truncated
        continuation_token = resp.next_continuation_token
      end
      keys
    end

    def s3_move(from:, to:)
      from = normalize_key(from)
      to = normalize_key(to)
      return false if from == to

      bucket = ENV.fetch("S3_BUCKET")
      s3_client.copy_object(bucket: bucket, copy_source: "#{bucket}/#{from}", key: to)
      s3_client.delete_object(bucket: bucket, key: from)
      true
    rescue Aws::S3::Errors::NoSuchKey
      Rails.logger.warn("s3_move: source key not found: #{from}")
      false
    end

    def normalize_key(key)
      key.to_s.delete_prefix("/")
    end

    private

    def s3_client
      Aws::S3::Client.new(
        endpoint: ENV.fetch("S3_LOCAL_ENDPOINT"),
        region: ENV.fetch("S3_REGION"),
        access_key_id: ENV.fetch("S3_USERNAME"),
        secret_access_key: ENV.fetch("S3_PASSWORD"),
        force_path_style: true
      )
    end
  end

  def s3_upload(key:, file:, content_type:)
    self.class.s3_upload(key: key, file: file, content_type: content_type)
  end

  def s3_download(key:, response_target:)
    self.class.s3_download(key: key, response_target: response_target)
  end

  def s3_delete(key:)
    self.class.s3_delete(key: key)
  end

  def s3_list(prefix:)
    self.class.s3_list(prefix: prefix)
  end

  def s3_move(from:, to:)
    self.class.s3_move(from: from, to: to)
  end

  private

  def object_url(key: "")
    File.join(ENV.fetch("S3_PUBLIC_ENDPOINT"), self.class.normalize_key(key))
  end

  def signed_object_url(key: "", expires_in: 100)
    s3 = Aws::S3::Client.new(
      endpoint: ENV["S3_API_ENDPOINT"].presence || ENV.fetch("S3_PUBLIC_ENDPOINT"),
      region: ENV.fetch("S3_REGION"),
      access_key_id: ENV.fetch("S3_USERNAME"),
      secret_access_key: ENV.fetch("S3_PASSWORD"),
      force_path_style: true
    )
    signer = Aws::S3::Presigner.new(client: s3)
    signer.presigned_url(
      :get_object,
      bucket: ENV.fetch("S3_BUCKET"),
      key: self.class.normalize_key(key),
      expires_in: expires_in
    )
  rescue StandardError => e
    Rails.logger.error("Failed to generate signed URL: #{e.message}")
    nil
  end
end
