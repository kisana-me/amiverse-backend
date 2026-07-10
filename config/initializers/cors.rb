Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*[ "http://localhost:3000", ENV["FRONT_URL"] ].compact)

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      expose: [ "X-Next-Cursor" ],
      credentials: true
  end
end
