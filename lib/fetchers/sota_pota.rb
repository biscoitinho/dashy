require 'time'

module Fetchers
  module SotaPota
    SOTA_URL = 'https://api2.sota.org.uk/api/spots/10/all'.freeze
    POTA_URL = 'https://api.pota.app/spot/activator'.freeze

    def self.fetch_all
      sota = fetch_sota
      pota = fetch_pota
      { sota: sota, pota: pota }
    end

    def self.fetch_sota
      data = Fetchers::Base.fetch_json(SOTA_URL)
      return [] unless data.is_a?(Array)

      spots = data.first(5).map do |s|
        {
          call: s['activatorCallsign'].to_s.strip,
          ref:  "#{s['associationCode']}/#{s['summitCode']}",
          freq: s['frequency'].to_s,
          mode: s['mode'].to_s.upcase,
          time: parse_time(s['timeStamp']),
          name: s['summitName'].to_s.slice(0, 20)
        }
      end
      spots.reject { |s| s[:call].empty? }
    rescue StandardError => e
      warn "sota error: #{e.class}: #{e.message}"
      []
    end

    def self.fetch_pota
      data = Fetchers::Base.fetch_json(POTA_URL)
      return [] unless data.is_a?(Array)

      spots = data.first(5).map do |s|
        {
          call: s['activator'].to_s.strip,
          ref:  s['reference'].to_s,
          freq: s['frequency'].to_s,
          mode: s['mode'].to_s.upcase,
          time: parse_time(s['spotTime']),
          name: s['name'].to_s.slice(0, 20)
        }
      end
      spots.reject { |s| s[:call].empty? }
    rescue StandardError => e
      warn "pota error: #{e.class}: #{e.message}"
      []
    end

    def self.parse_time(str)
      return '--:--' if str.nil? || str.empty?

      Time.parse(str).localtime.strftime('%H:%M')
    rescue StandardError
      '--:--'
    end
  end
end
