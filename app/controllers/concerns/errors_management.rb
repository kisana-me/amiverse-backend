module ErrorsManagement
  # Errors Management ver 1.0.1
  # controllers/application_controller.rbで
  # include ErrorsManagement
  # def routing_error
  #   raise ActionController::RoutingError, params[:path]
  # end
  # config/routes.rbで
  # match "*path", to: "application#routing_error", via: :all

  extend ActiveSupport::Concern

  included do
    unless Rails.env.development?
      rescue_from StandardError,                  with: :render_500
      rescue_from ActiveRecord::RecordNotFound,   with: :render_404
      rescue_from ActionController::RoutingError, with: :render_404
    end
  end

  private

  def render_404(exception = nil)
    # log_error(exception)
    respond_to do |format|
      format.html { render("errors/404", status: :not_found) rescue head :not_found }
      format.json { render json: { error: "Not Found", request_id: request.request_id }, status: :not_found }
      format.any  { head :not_found }
    end
  end

  def render_500(exception = nil)
    log_error(exception)
    respond_to do |format|
      format.html { render("errors/500", status: :internal_server_error) rescue head :internal_server_error }
      format.json { render json: { error: "Internal Server Error", request_id: request.request_id }, status: :internal_server_error }
      format.any  { head :internal_server_error }
    end
  end

  def log_error(exception)
    return unless exception
    logger.error "=== Error Occurred ==="
    logger.error "Request ID: #{request.request_id}"
    logger.error "URL: #{request.original_url}"
    logger.error "Params: #{params.to_unsafe_h.except(:controller, :action).inspect}"
    logger.error "IP: #{request.remote_ip}"
    logger.error "User Agent: #{request.user_agent}"
    logger.error "Time: #{Time.current}"
    logger.error "Current Account Aid: #{@current_account&.aid || 'Guest'}"
    logger.error "#{exception.class}: #{exception.message}"
    if exception.backtrace
      app_trace = exception.backtrace.select { |line| line.include?("/app/") }
      app_trace = app_trace.first(10)
      logger.error "Application Trace:"
      logger.error app_trace.join("\n")
    end
    logger.error "======================="
  end
end
