class V1::ReportsController < V1::ApplicationController
  # POST /v1/reports
  def create
    @report = Report.new(report_params)
    @report.account = @current_account if @current_account.present?

    if @report.save
      render json: {
        status: "success",
        message: "通報しました"
      }, status: :created
    else
      render json: {
        status: "error",
        message: "通報できませんでした",
        errors: @report.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  # def create_notifications
  #   NotificationCreator.call(
  #     actor: @current_account,
  #     recipient: @current_account,
  #     action: :reported,
  #     notifiable: @report
  #   )
  # end

  def report_params
    params.expect(
      report: [
        :target_type,
        :target_aid,
        :category,
        :description
      ]
    )
  end
end
