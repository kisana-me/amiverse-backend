class EmojiImportService
  # 使い方: EmojiImportService.call('storage/emoji-test.txt')
  # https://www.unicode.org/Public/17.0.0/emoji/emoji-test.txt を想定

  def self.call(file_path)
    new(file_path).perform
  end

  def initialize(file_path)
    @file_path = file_path
    @created_count = 0
    @skipped_count = 0
  end

  def perform
    unless File.exist?(@file_path)
      puts "Error: File not found at #{@file_path}"
      return
    end

    puts "Starting import from #{@file_path}..."

    current_group = 'Unknown'
    current_subgroup = 'Unknown'

    File.foreach(@file_path) do |line|
      line = line.strip

      # 1. グループ/サブグループの更新
      if line.start_with?('# group:')
        current_group = line.sub('# group:', '').strip
        next
      elsif line.start_with?('# subgroup:')
        current_subgroup = line.sub('# subgroup:', '').strip
        next
      end

      # 2. データ行の解析（空行やコメント行はスキップ）
      next if line.empty? || line.start_with?('#')

      # 行のパース
      # 例: 1F600 ; fully-qualified # 😀 E1.0 grinning face
      code_part, rest = line.split(';', 2)
      status_part, comment_part = rest.split('#', 2)

      status_text = status_part.strip

      # 要件: fully-qualified のみ取り込む
      next unless status_text == 'fully-qualified'

      # 生データの抽出
      hex_sequence = code_part.strip # "1F600" や "1F468 200D 2695"

      # バージョンと英語名の抽出
      # comment_part 例: " 😀 E1.0 grinning face"
      # 最初の絵文字とバージョン(E1.0など)を除去して名前を取得
      raw_comment = comment_part.strip

      # 正規表現で分解: (絵文字) (Eバージョン) (名前)
      # 例: matches[1] = "E1.0", matches[2] = "grinning face"
      match_data = raw_comment.match(/[^\s]+\s+(E\d+\.\d+)\s+(.+)/)

      unless match_data
        puts "Warning: Could not parse comment format: #{raw_comment}"
        next
      end

      version_str = match_data[1] # "E1.0"
      english_name = match_data[2] # "grinning face"

      # データの加工

      # name: 実際の絵文字
      emoji_char = hex_sequence.split.map { |c| c.hex }.pack('U*')

      # name_id: 英数字以外をアンダーバーに置換（連続は1つにまとめる）
      # 例: "boy: medium skin tone" -> "boy_medium_skin_tone"
      name_id_value = english_name.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_|_$/, '')

      # description: "1F600\nE1.0" の形式
      description_value = "#{hex_sequence}\n#{version_str}"

      # DBへの保存処理
      create_or_skip_emoji(
        name: emoji_char,
        name_id: name_id_value,
        description: description_value,
        group: current_group,
        subgroup: current_subgroup
      )
    end

    puts "Import finished. Created: #{@created_count}, Skipped(Exists): #{@skipped_count}"
  end

  private

  def create_or_skip_emoji(attrs)
    if Emoji.exists?(name_id: attrs[:name_id])
      @skipped_count += 1
      return
    end

    begin
      Emoji.create!(
        name: attrs[:name],
        name_id: attrs[:name_id],
        description: attrs[:description],
        group: attrs[:group],
        subgroup: attrs[:subgroup],
      )
      @created_count += 1
    rescue ActiveRecord::RecordNotUnique => e
      puts "Skipping duplicate key error for #{attrs[:name_id]}: #{e.message}"
      @skipped_count += 1
    end
  end
end
