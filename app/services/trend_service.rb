class TrendService
  require 'natto'

  CACHE_KEY = 'current_trends'
  CACHE_TIME_KEY = 'current_trends_updated_at'
  CACHE_EXPIRY = 1.hour

  # Defaults if config is missing
  TREND_SEARCH_WORDS_LIMIT = 50
  TREND_DISPLAY_LIMIT = 30
  TREND_INTERVAL_MINUTES = 60
  TREND_SAMPLING_LIMIT = 1000

  def self.current_trends
    Rails.cache.read(CACHE_KEY)
  end

  def self.last_updated_at
    Rails.cache.read(CACHE_TIME_KEY)
  end

  def self.update_trends
    new.update_trends
  end

  def update_trends
    Rails.logger.info 'Starting trend update...'

    items = get_newer_items
    trends = frequent_words(items: items)

    Rails.cache.write(CACHE_KEY, trends, expires_in: CACHE_EXPIRY)
    Rails.cache.write(CACHE_TIME_KEY, Time.current, expires_in: CACHE_EXPIRY)

    Rails.logger.info "Trends updated: #{trends.keys.join(', ')}"
    trends
  end

  private

  def get_newer_items
    # Use config if available, else defaults
    interval = Rails.application.config.try(:x).try(:server_property).try(:trend_interval) || TREND_INTERVAL_MINUTES
    base_limit = Rails.application.config.try(:x).try(:server_property).try(:trend_samplings) || TREND_SAMPLING_LIMIT

    base_time = Time.current - interval.minutes

    # Assuming Post model is what we want (user code used Item, but context shows Post)
    recent_items = Post.isnt_deleted.where('created_at > ?', base_time).order(created_at: :desc)

    if recent_items.count < base_limit
      return Post.isnt_deleted.order(created_at: :desc).limit(base_limit)
    end

    recent_items
  end

  def frequent_words(items:)
    natto = Natto::MeCab.new
    word_count = Hash.new(0)

    items.each do |item|
      next if item.content.blank?

      natto.parse(item.content) do |n|
        surface = n.surface
        feature = n.feature.split(',')

        if surface.length <= 3 ||
           surface.match?(/[!?！？　「」\s.,\/#@&"'$%()=\-~^\\|_{}\[\]。、*+;:`]/) ||
           (surface.match?(/\A[a-zA-Z]+\z/) && !(feature[0] == '名詞' && feature[1] == '固有名詞'))
          next
        end

        word_count[surface] += 1
      end
    end

    limit = Rails.application.config.try(:x).try(:server_property).try(:trend_search_words) || TREND_SEARCH_WORDS_LIMIT
    sorted_words = word_count.sort_by { |_, count| -count }.first(limit)

    word_usage_count = {}
    sorted_words.to_a.each do |word, count|
      begin
        # Search count using MeiliSearch (Post.search)
        # Using double quotes for exact phrase match
        search_count = Post.search("\"#{word}\"", limit: 500).count
        word_usage_count[word] = [search_count, count]
      rescue => e
        Rails.logger.error "Search failed for #{word}: #{e.message}"
        word_usage_count[word] = [count, count] # Fallback
      end
    end

    # Sort by search count (index 0)
    word_usage_count.sort_by { |_, counts| -counts[0] }.first(TREND_DISPLAY_LIMIT).to_h
  end
end
