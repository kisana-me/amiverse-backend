class ReportsController < ApplicationController
  before_action :require_admin
  before_action :set_report, except: %i[index]

  def index
    reports = Report.all.order(id: :desc)
    @reports = set_pagination_for(reports, 30)
  end

  def show; end

  def update
    if @report.update(report_params)
      redirect_to report_path(@report.aid), notice: "更新しました"
    else
      flash.now[:alert] = "更新できませんでした"
      render :show, status: :unprocessable_entity
    end
  end

  private

  def report_params
    params.expect(
      report: [
        :category,
        :description,
        :announcement,
        :status
      ]
    )
  end

  def set_report
    @report = Report.find_by(aid: params[:aid])
  end
end
