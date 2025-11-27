module V1
  class TrendsController < ApplicationController
    def index
      trends = TrendService.current_trends
      last_updated = TrendService.last_updated_at

      if trends.nil?
        trends = TrendService.update_trends
        last_updated = TrendService.last_updated_at
      end

      ranking = trends.map do |word, counts|
        { word: word, count: counts[0] }
      end

      # Ensure sorting by count descending
      ranking.sort_by! { |item| -item[:count] }

      response_data = [
        {
          category: "general",
          image_url: "https://kisana.me/images/amiverse/amiverse-1.webp",
          title: "#{last_updated.strftime('%-H')}時台のトレンド",
          overview: "最新トレンド情報です。",
          last_updated_at: last_updated,
          ranking: ranking
        }
      ]

      render json: response_data
    end
  end
end
