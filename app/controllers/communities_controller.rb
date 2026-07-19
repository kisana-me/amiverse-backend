class CommunitiesController < ApplicationController
  before_action :require_admin
  before_action :set_community, only: %i[ show update ]

  def index
    communities = Community.all.order(id: :desc).includes(:icon)
    @communities = set_pagination_for(communities)
  end

  def show
  end

  def new
    @community = Community.new
  end

  def create
    @community = Community.new(community_params)
    if @community.save
      redirect_to community_path(@community.aid), notice: "作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @community.update(community_params)
      redirect_to community_path(@community.aid), notice: "更新しました"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_community
    @community = Community.find_by(aid: params.expect(:aid))
  end

  def community_params
    params.expect(
      community: [
        :name,
        :description,
        :status,
        :visibility,
        :founder_aid,
        :icon_file,
        :banner_file
      ]
    )
  end
end
