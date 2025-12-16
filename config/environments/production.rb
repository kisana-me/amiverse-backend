require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  config.assets.compile = false
  config.public_file_server.headers = { 'cache-control' => "public, max-age=#{10.days.to_i}" }
  config.active_storage.service = :minio
  config.assume_ssl = true
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  config.log_tags = [:request_id]
  config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'info')
  config.logger = Logger.new('log/production.log', 'daily')
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [:id]
  config.silence_healthcheck_path = '/up'
  config.cache_store = :memory_store # solid_cache_store

  # # Replace the default in-process and non-durable queuing backend for Active Job.
  # config.active_job.queue_adapter = :solid_queue
  # config.solid_queue.connects_to = { database: { writing: :queue } }

  # config.action_mailer.raise_delivery_errors = false
  # config.action_mailer.default_url_options = { host: 'example.com' }
  # config.action_mailer.smtp_settings = {
  #   user_name: Rails.application.credentials.dig(:smtp, :user_name),
  #   password: Rails.application.credentials.dig(:smtp, :password),
  #   address: "smtp.example.com",
  #   port: 587,
  #   authentication: :plain
  # }

  # Enable DNS rebinding protection and other `Host` header attacks.
  env_hosts = [ENV['BACK_URL'], ENV['FRONT_URL']].compact.map do |u|
    begin
      uri = URI.parse(u)
      uri.host || u
    rescue URI::InvalidURIError
      u
    end
  end
  config.hosts += env_hosts

  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  # Cloudflare IP Ranges(https://www.cloudflare.com/ips/)
  config.action_dispatch.trusted_proxies = [
    # IPv6
    IPAddr.new("2400:cb00::/32"),
    IPAddr.new("2606:4700::/32"),
    IPAddr.new("2803:f800::/32"),
    IPAddr.new("2405:b500::/32"),
    IPAddr.new("2405:8100::/32"),
    IPAddr.new("2a06:98c0::/29"),
    IPAddr.new("2c0f:f248::/32"),
    # IPv4
    IPAddr.new("103.21.244.0/22"),
    IPAddr.new("103.22.200.0/22"),
    IPAddr.new("103.31.4.0/22"),
    IPAddr.new("104.16.0.0/13"),
    IPAddr.new("104.24.0.0/14"),
    IPAddr.new("108.162.192.0/18"),
    IPAddr.new("131.0.72.0/22"),
    IPAddr.new("141.101.64.0/18"),
    IPAddr.new("162.158.0.0/15"),
    IPAddr.new("172.64.0.0/13"),
    IPAddr.new("173.245.48.0/20"),
    IPAddr.new("188.114.96.0/20"),
    IPAddr.new("190.93.240.0/20"),
    IPAddr.new("197.234.240.0/22"),
    IPAddr.new("198.41.128.0/17")
  ]
end
