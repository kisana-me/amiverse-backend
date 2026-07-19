class V1::CommunitiesController < V1::ApplicationController
  def index
    @communities = Community
      .listable
      .includes(:icon, :banner)
      .order(id: :desc)
    render template: "v1/communities/index", formats: [ :json ]
  end

  def show
    @community = Community.listable.includes(:icon, :banner, founder: :icon).find_by(aid: params[:aid])
    if @community
      render template: "v1/communities/show", formats: [ :json ]
    else
      render json: {
        status: "error",
        message: "コミュニティが見つかりませんでした"
      }, status: :not_found
    end
  end
end
