require 'time'

module Fetchers
  module KpForecast
    URL = 'https://services.swpc.noaa.gov/products/noaa-planetary-k-index-forecast.json'.freeze

    def self.fetch_data
      raw = Fetchers::Base.fetch_json(URL)
      return empty_forecast unless raw.is_a?(Array) && raw.size > 1

      # Skip header row, parse entries
      entries = raw.drop(1).filter_map do |row|
        next unless row.is_a?(Array) && row.size >= 2

        time_str = row[0]
        kp_str   = row[1]
        kp       = kp_str.to_f
        time     = Time.parse("#{time_str} UTC") rescue nil # rubocop:disable Style/RescueModifier
        next unless time

        { time: time, kp: kp }
      end

      now = Time.now.utc
      next_24h = entries.select { |e| e[:time].between?(now, now + 86_400) }

      max_24h = next_24h.map { |e| e[:kp] }.max
      alert   = next_24h.find { |e| e[:kp] >= 4 }

      next_72h = entries.select { |e| e[:time] >= now }

      {
        max_kp_24h: max_24h&.round(1),
        alert_time: alert ? alert[:time].localtime.strftime('%H:%M') : nil,
        alert_kp:   alert&.dig(:kp)&.round(1),
        entries:    next_72h.first(8)
      }
    rescue StandardError => e
      warn "kp_forecast error: #{e.class}: #{e.message}"
      empty_forecast
    end

    def self.empty_forecast
      { max_kp_24h: nil, alert_time: nil, alert_kp: nil, entries: [] }
    end
  end
end
