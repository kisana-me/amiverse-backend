module Paginatable
  extend ActiveSupport::Concern

  included do
    scope :paginate, lambda { |page: 1, per_page: 10|
      page = [ page.to_i, 1 ].max
      offset((page - 1) * per_page).limit(per_page)
    }
  end
end
