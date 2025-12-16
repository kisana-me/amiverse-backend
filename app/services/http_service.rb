class HttpService
  require 'net/http'

  def self.get_request(url, headers = {})
    uri = URI.parse(url)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.get(uri.request_uri, headers)
    end
    response
  end

  def self.post_request(url, headers = {}, data = nil)
    uri = URI.parse(url)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.post(uri.request_uri, data, headers)
    end
    response
  end
end
