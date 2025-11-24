module Pagination
  extend ActiveSupport::Concern

  private

  def set_pagination_for(model, per_page = 10)
    pagination = pagination_params(per_page)
    @page = pagination[:page]
    @per_page = pagination[:per_page]
    @total_pages = (model.count / @per_page.to_f).ceil
    model.paginate(**pagination)
  end

  def pagination_params(per_page = 10)
    {
      page: params.fetch(:page, 1).to_i,
      per_page: per_page.to_i
    }
  end
end
