# テキストの簡易レーティング判定(辞書ベース)
# config/moderation/wordlist.yml の語を含むかで nsfw / r18 を判定

class TextRating
  WORDLIST_PATH = Rails.root.join("config", "moderation", "wordlist.yml")

  class << self
    def rate(content)
      return :general if content.blank?

      normalized = normalize(content)
      return :r18 if wordlist["r18"].any? { |word| normalized.include?(word) }
      return :nsfw if wordlist["nsfw"].any? { |word| normalized.include?(word) }

      :general
    end

    def reload!
      @wordlist = nil
    end

    private

    def wordlist
      @wordlist ||= begin
        raw = File.exist?(WORDLIST_PATH) ? YAML.load_file(WORDLIST_PATH) : {}
        {
          "nsfw" => Array(raw["nsfw"]).map { |w| normalize(w) },
          "r18" => Array(raw["r18"]).map { |w| normalize(w) }
        }
      end
    end

    def normalize(text)
      utf8 = text.to_s.dup.force_encoding(Encoding::UTF_8).scrub
      utf8.unicode_normalize(:nfkc).downcase
    end
  end
end
