class HelloJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.info "Hello from Solid Queue! Args: #{args.inspect}"
    puts "Hello from Solid Queue! Args: #{args.inspect}"
  end
end
