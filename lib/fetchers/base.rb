require 'net/http'
require 'json'

module Fetchers
  module Base
    HEADERS = {
      'User-Agent' => 'dashy/1.0 SP2MAG (local ham radio dashboard)',
      'Accept' => 'text/xml, application/xml, application/rss+xml, */*'
    }.freeze

    def self.fetch(url, timeout: 12, redirects: 5)
      raise 'Too many redirects' if redirects.zero?

      uri  = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl      = (uri.scheme == 'https')
      http.open_timeout = timeout
      http.read_timeout = timeout
      resp = http.get(uri.request_uri, HEADERS)
      case resp
      when Net::HTTPSuccess
        resp.body
      when Net::HTTPRedirection
        loc = resp['location']
        loc = URI.join(url, loc).to_s unless loc.start_with?('http')
        warn "redirect -> #{loc}"
        fetch(loc, timeout: timeout, redirects: redirects - 1)
      else
        warn "HTTP #{resp.code} from #{url}"
        nil
      end
    rescue => e
      warn "fetch error [#{url}]: #{e.class}: #{e.message}"
      nil
    end

    def self.fetch_json(url)
      body = fetch(url)
      return nil unless body

      if body.lstrip.start_with?('<')
        warn "fetch_json: got HTML/XML from #{url}"
        return nil
      end
      JSON.parse(body)
    rescue JSON::ParserError => e
      warn "json parse error [#{url}]: #{e.message[0, 80]}"
      nil
    end
  end
end
