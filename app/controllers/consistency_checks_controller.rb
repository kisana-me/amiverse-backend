class ConsistencyChecksController < ApplicationController
  before_action :require_admin

  def show; end

  def create
    @result = S3ConsistencyCheck.new.run
    render :show
  end
end
