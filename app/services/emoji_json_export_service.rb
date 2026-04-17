require 'json'
require 'fileutils'
require 'pathname'

class EmojiJsonExportService
  # 使い方:
  # EmojiJsonExportService.call('storage/emoji-test.txt')
  # EmojiJsonExportService.call('storage/emoji-test.txt', output_dir: 'storage')

  def self.call(file_path = 'storage/emoji-test.txt', output_dir: 'storage')
    new(file_path, output_dir: output_dir).perform
  end

  def initialize(file_path, output_dir:)
    @file_path = file_path
    @output_dir = output_dir
    @grouped_emojis = Hash.new { |hash, key| hash[key] = [] }
  end

  def perform
    input_path = absolute_path(@file_path)
    output_path = absolute_path(@output_dir)

    unless File.exist?(input_path)
      puts "Error: File not found at #{input_path}"
      return
    end

    FileUtils.mkdir_p(output_path)

    puts "Starting json export from #{input_path}..."

    current_group = 'Unknown'
    current_subgroup = 'Unknown'

    File.foreach(input_path) do |raw_line|
      line = raw_line.strip

      next if line.empty?

      if (group_name = extract_group(line))
        current_group = group_name
        next
      end

      if (subgroup_name = extract_subgroup(line))
        current_subgroup = subgroup_name
        next
      end

      next if line.start_with?('#')

      attrs = parse_emoji_line(line, current_group, current_subgroup)
      next if attrs.nil?

      @grouped_emojis[current_group] << attrs
    end

    write_group_files(output_path)
  end

  private

  def extract_group(line)
    match = line.match(/\A#?\s*group:\s*(.+)\z/)
    match && match[1].strip
  end

  def extract_subgroup(line)
    match = line.match(/\A#?\s*subgroup:\s*(.+)\z/)
    match && match[1].strip
  end

  def parse_emoji_line(line, group, subgroup)
    code_part, rest = line.split(';', 2)
    return nil if code_part.nil? || rest.nil?

    status_part, comment_part = rest.split('#', 2)
    return nil if status_part.nil? || comment_part.nil?

    status_text = status_part.strip
    return nil unless status_text == 'fully-qualified'

    hex_sequence = code_part.strip
    raw_comment = comment_part.strip

    match_data = raw_comment.match(/[^\s]+\s+(E\d+\.\d+)\s+(.+)/)
    unless match_data
      puts "Warning: Could not parse comment format: #{raw_comment}"
      return nil
    end

    version_str = match_data[1]
    english_name = match_data[2]

    emoji_char = hex_sequence.split.map { |code_point| code_point.hex }.pack('U*')
    name_id_value = english_name.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_|_$/, '')
    description_value = "#{hex_sequence}\n#{version_str}"

    {
      name: emoji_char,
      name_id: name_id_value,
      description: description_value,
      group: group,
      subgroup: subgroup,
    }
  end

  def write_group_files(output_base_dir)
    total_count = 0

    @grouped_emojis.each do |group_name, emojis|
      file_group = normalized_group_name(group_name)
      file_group = 'unknown' if file_group.empty?

      file_path = File.join(output_base_dir, "emojis-#{file_group}.json")
      File.write(file_path, JSON.pretty_generate(emojis))

      puts "Wrote #{emojis.size} emojis to #{file_path}"
      total_count += emojis.size
    end

    puts "Export finished. Groups: #{@grouped_emojis.size}, Emojis: #{total_count}"
  end

  def normalized_group_name(group_name)
    group_name
      .downcase
      .gsub(/[&\s]+/, '-')
      .gsub(%r{[/\\]+}, '-')
      .gsub(/-+/, '-')
      .gsub(/\A-+|-+\z/, '')
  end

  def absolute_path(path)
    pathname = Pathname.new(path.to_s)
    return pathname.to_s if pathname.absolute?

    Rails.root.join(pathname).to_s
  end
end
