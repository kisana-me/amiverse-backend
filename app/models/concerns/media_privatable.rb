# status が deleted になったら S3 のファイルを private/ 配下へ移動し、
# deleted から復帰したら元の場所へ戻す。
# include するモデルは media_file_keys (正規化済みキーの配列) を実装すること。
module MediaPrivatable
  extend ActiveSupport::Concern

  PRIVATE_PREFIX = "private/".freeze

  included do
    before_save :move_files_on_status_change, if: :will_save_change_to_status?
  end

  def private_key_for(key)
    key = self.class.normalize_key(key)
    key.start_with?(PRIVATE_PREFIX) ? key : "#{PRIVATE_PREFIX}#{key}"
  end

  def public_key_for(key)
    self.class.normalize_key(key).delete_prefix(PRIVATE_PREFIX)
  end

  private

  def move_files_on_status_change
    return if new_record?

    was_deleted = status_in_database == "deleted"
    if deleted? && !was_deleted
      media_file_keys.each { |key| s3_move(from: key, to: private_key_for(key)) }
    elsif !deleted? && was_deleted
      media_file_keys.each { |key| s3_move(from: private_key_for(key), to: key) }
    end
  end
end
