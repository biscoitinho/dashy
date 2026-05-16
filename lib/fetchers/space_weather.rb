require 'rexml/document'
require 'time'

module Fetchers
  module SpaceWeather
    HAMQSL_XML = 'https://www.hamqsl.com/solarxml.php'.freeze

    def self.fetch_data
      body = Fetchers::Base.fetch(HAMQSL_XML)
      return empty_wx unless body

      doc  = REXML::Document.new(body)
      data = doc.elements['solar/solardata']
      return empty_wx unless data

      el = ->(tag) { data.elements[tag]&.text&.strip }

      solar_flux = el.call('solarflux')&.to_f
      kp         = el.call('kindex')&.to_f

      bands = {}
      doc.elements.each('solar/solardata/calculatedconditions/band') do |b|
        name = b.attributes['name']
        time = b.attributes['time']
        bands[name] ||= {}
        bands[name][time] = b.text&.strip
      end

      {
        solar_flux:  solar_flux,
        sunspots:    el.call('sunspots')&.to_i,
        kp_index:    kp,
        a_index:     el.call('aindex')&.to_f,
        x_ray:       el.call('xray'),
        solar_wind:  el.call('solarwind')&.to_f,
        mag_field:   el.call('magneticfield')&.to_f,
        aurora:      el.call('aurora')&.to_i,
        aurora_lat:  el.call('latdegree')&.to_f,
        helium:      el.call('heliumline')&.to_f,
        geomag:      kp_to_storm(kp),
        propagation: propagation_assessment(solar_flux, kp),
        bands:       bands,
        updated:     el.call('updated') || Time.now.strftime('%d %b %Y %H%M GMT'),
        source:      'N0NBH/hamqsl.com (solar.w5mmw.net)'
      }
    rescue => e
      warn "space_weather error: #{e.class}: #{e.message}"
      empty_wx
    end

    def self.kp_to_storm(kp)
      return 'N/A' if kp.nil?

      if    kp >= 8 then 'Extreme (G5)'
      elsif kp >= 7 then 'Severe (G4)'
      elsif kp >= 6 then 'Strong (G3)'
      elsif kp >= 5 then 'Moderate (G2)'
      elsif kp >= 4 then 'Minor (G1)'
      elsif kp >= 3 then 'Unsettled'
      elsif kp >= 1 then 'Quiet'
      else               'Very Quiet'
      end
    end

    def self.propagation_assessment(flux, kp)
      return { label: 'N/A', level: 0 } if flux.nil? && kp.nil?

      kp   ||= 0.0
      flux ||= 0.0
      if    kp >= 5     then { label: 'ZAKLOCONA (burza)',  level: -2 }
      elsif kp >= 4     then { label: 'NIESTABILNA',        level: -1 }
      elsif kp >= 3     then { label: 'ZMIENNA',            level:  0 }
      elsif flux >= 150 then { label: 'DOSKONALA',          level:  3 }
      elsif flux >= 120 then { label: 'BARDZO DOBRA',       level:  2 }
      elsif flux >= 90  then { label: 'DOBRA',              level:  1 }
      elsif flux >= 70  then { label: 'PRZECIETNA',         level:  0 }
      else                   { label: 'SLABA',              level: -1 }
      end
    end

    def self.empty_wx
      { propagation: { label: 'N/A', level: 0 }, bands: {}, error: true }
    end
  end
end
