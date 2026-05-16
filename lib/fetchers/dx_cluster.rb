require 'time'

module Fetchers
  module DxCluster
    SPOTS_URL = 'https://www.dxsummit.fi/api/v1/spots?de_continent=EU&limit=10'.freeze

    def self.fetch_spots
      data = Fetchers::Base.fetch_json(SPOTS_URL)
      return [] unless data.is_a?(Array)

      spots = data.first(10).map do |s|
        freq_khz = s['frequency'].to_f
        {
          de:   s['de_call'].to_s.strip,
          dx:   s['dx_call'].to_s.strip,
          freq: freq_khz,
          band: khz_to_band(freq_khz),
          info: s['info'].to_s.strip.slice(0, 30),
          time: parse_time(s['time'])
        }
      end
      spots.reject { |s| s[:dx].empty? }
    rescue StandardError => e
      warn "dx_cluster error: #{e.class}: #{e.message}"
      []
    end

    def self.khz_to_band(khz)
      case khz
      when 1800..2000   then '160m'
      when 3500..3800   then '80m'
      when 7000..7200   then '40m'
      when 10_100..10_150 then '30m'
      when 14_000..14_350 then '20m'
      when 18_068..18_168 then '17m'
      when 21_000..21_450 then '15m'
      when 24_890..24_990 then '12m'
      when 28_000..29_700 then '10m'
      when 50_000..52_000 then '6m'
      else "#{(khz / 1000.0).round(3)} MHz"
      end
    end

    def self.parse_time(str)
      return '--:--' if str.nil?

      t = Time.parse(str)
      t.localtime.strftime('%H:%M')
    rescue StandardError
      '--:--'
    end
  end
end
