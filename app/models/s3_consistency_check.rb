# オブジェクトストレージ上のファイルと Image/Video/Drawing レコードの整合性を突合する。
# orphans: S3 に存在するが DB で管理されていないキー
# missing: DB 上は存在するはずだが S3 に実体がないキー(所属レコード付き)
class S3ConsistencyCheck
  PREFIXES = %w[images/ videos/ drawings/ private/].freeze
  MEDIA_CLASSES = [ Image, Video, Drawing ].freeze

  Result = Struct.new(:orphans, :missing, keyword_init: true)

  def run
    actual = PREFIXES.flat_map { |prefix| ApplicationRecord.s3_list(prefix: prefix) }.to_set

    expected = {}
    MEDIA_CLASSES.each do |klass|
      klass.find_each do |record|
        record.media_file_keys.each do |key|
          key = record.deleted? ? record.private_key_for(key) : key
          expected[key] = record
        end
      end
    end

    orphans = (actual - expected.keys).sort
    missing = (expected.keys.to_set - actual).sort.map { |key| [ key, expected[key] ] }

    Result.new(orphans: orphans, missing: missing)
  end
end
