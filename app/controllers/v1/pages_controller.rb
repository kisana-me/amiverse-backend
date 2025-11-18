class V1::PagesController < V1::ApplicationController
  def index
    render json: { status: 'success', message: 'Welcome to API v1' }
  end
end
