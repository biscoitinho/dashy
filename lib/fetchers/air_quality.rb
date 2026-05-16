module Fetchers
  module AirQuality
    WAQI_TOKEN  = ENV.fetch('WAQI_TOKEN') { raise 'Set WAQI_TOKEN env var — see .env.example' }.freeze
    WAQI_BASE   = 'https://api.waqi.info/feed'.freeze
    WAQI_CITIES = ['geo:54.5726;18.3965'].freeze # Rumia/Szemud nie ma stacji w WAQI

    def self.fetch_data
      data = nil
      city_used = nil

      WAQI_CITIES.each do |city|
        url  = "#{WAQI_BASE}/#{city}/?token=#{WAQI_TOKEN}"
        resp = Fetchers::Base.fetch_json(url)
        next unless resp.is_a?(Hash) && resp['status'] == 'ok' && resp['data'].is_a?(Hash)
        next unless resp['data']['aqi'].to_i.positive?

        data      = resp['data']
        city_used = 'Rumia / Trójmiasto'
        break
      end

      return nil unless data

      iaqi = data['iaqi'] || {}
      pm25 = iaqi.dig('pm25', 'v')&.round(1)
      pm10 = iaqi.dig('pm10', 'v')&.round(1)
      aqi  = data['aqi'].to_i

      {
        station:  city_used,
        aqi:      aqi,
        pm25:     pm25,
        pm10:     pm10,
        no2:      iaqi.dig('no2', 'v')&.round(1),
        o3:       iaqi.dig('o3',  'v')&.round(1),
        aqi_lvl:  eu_aqi_level(aqi),
        aqi_pm25: pm25 ? aqi_label(pm25, :pm25) : nil,
        updated:  Time.now.strftime('%H:%M')
      }
    rescue => e
      warn "air_quality error: #{e.class}: #{e.message}"
      nil
    end

    def self.fetch_debug
      out = []
      WAQI_CITIES.each do |city|
        url  = "#{WAQI_BASE}/#{city}/?token=#{WAQI_TOKEN}"
        resp = Fetchers::Base.fetch_json(url)
        if resp.is_a?(Hash)
          d   = resp['data']
          aqi = d.is_a?(Hash) ? d['aqi'] : d.inspect
          out << "#{city}: #{resp['status']} aqi=#{aqi}"
        else
          out << "#{city}: FAILED"
        end
      end
      out.join("\n")
    rescue => e
      "ERROR: #{e.class}: #{e.message}"
    end

    def self.eu_aqi_level(aqi)
      if    aqi <= 50  then { label: 'Dobry',        level: 0 }
      elsif aqi <= 100 then { label: 'Umiarkowany',  level: 1 }
      elsif aqi <= 150 then { label: 'Niezdrowy*',   level: 2 }
      elsif aqi <= 200 then { label: 'Niezdrowy',    level: 3 }
      elsif aqi <= 300 then { label: 'Bardzo zly',   level: 4 }
      else                  { label: 'Ekstremalny',  level: 5 }
      end
    end

    def self.aqi_label(val, type)
      limits = type == :pm25 ? [12, 35, 55, 150, 250] : [20, 40, 50, 100, 150]
      levels = ['Dobry', 'Umiarkowany', 'Niezdrowy*', 'Niezdrowy', 'Bardzo zly', 'Ekstremalny']
      idx    = limits.each_with_index.find { |l, _| val <= l }&.last || 5
      { label: levels[idx], level: idx, value: val }
    end
  end
end
