class NormalizeNameIdService
  def self.call(name_id)
    new(name_id).call
  end

  def initialize(name_id)
    @name_id = name_id
  end

  def call
    # 先頭の @ を削除
    normalized = @name_id.gsub(/^@/, '')

    if normalized.include?('@')
      username, domain = normalized.split('@', 2)
      
      # ドメインが FRONT_URL のホストと同じならローカル扱い
      if domain == front_host
        [username, nil]
      else
        [username, domain]
      end
    else
      # @ が含まれていない場合はローカル扱い
      [normalized, nil]
    end
  end

  private

  def front_host
    @front_host ||= URI(ENV.fetch('FRONT_URL')).host
  end
end
