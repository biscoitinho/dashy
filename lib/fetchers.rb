require 'net/http'
require 'json'
require 'rexml/document'
require 'time'

module Fetchers
  RUBY_WEEKLY_RSS    = 'https://rubyweekly.com/rss'.freeze
  RUBY_WEEKLY_ISSUES = 'https://rubyweekly.com/issues'.freeze
  HAMQSL_XML         = 'https://www.hamqsl.com/solarxml.php'.freeze
  GIOS_BASE          = 'https://api.gios.gov.pl/pjp-api/rest'.freeze
  WEJHEROWO          = { lat: 54.6076, lon: 18.2350 }.freeze

  HEADERS = {
    'User-Agent' => 'dashy/1.0 SP2MAG (local ham radio dashboard)',
    'Accept'     => 'text/xml, application/xml, application/rss+xml, */*'
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

  # ── Ruby Weekly ────────────────────────────────────────────────────────────
  def self.ruby_news(limit: 10)
    items = ruby_news_from_rss(limit)
    if items.size < limit
      items += ruby_news_from_issues(limit - items.size, skip: items.map { |i| i[:link] })
    end
    items
  rescue => e
    warn "ruby_news error: #{e.class}: #{e.message}"
    []
  end

  def self.ruby_news_from_rss(limit)
    body = fetch(RUBY_WEEKLY_RSS)
    return [] unless body
    doc   = REXML::Document.new(body)
    items = []
    doc.elements.each('rss/channel/item') do |item|
      title = item.elements['title']&.text&.strip
      link  = item.elements['link']&.text&.strip
      pub   = item.elements['pubDate']&.text&.strip
      items << { title: title, link: link, date: pub, snippet: nil }
      break if items.size >= limit
    end
    items
  rescue => e
    warn "rss error: #{e.class}: #{e.message}"
    []
  end

  def self.ruby_news_from_issues(limit, skip: [])
    body = fetch(RUBY_WEEKLY_ISSUES)
    return [] unless body
    items = []
    body.scan(%r{href="(/issues/(\d+))"[^>]*>([^<]+)<}i) do |path, num, title|
      clean = title.strip.gsub(/\s+/, ' ')
      next if clean.length < 10 || clean =~ /\A[\d\s#]+\z/
      link = "https://rubyweekly.com#{path}"
      next if skip.include?(link)
      items << { title: clean, link: link, date: "##{num}", snippet: nil }
      break if items.size >= limit
    end
    items
  rescue => e
    warn "issues scrape error: #{e.class}: #{e.message}"
    []
  end

  # ── Space weather via N0NBH / hamqsl.com ──────────────────────────────────
  def self.space_weather
    body = fetch(HAMQSL_XML)
    return empty_wx unless body

    doc  = REXML::Document.new(body)
    data = doc.elements['solar/solardata']
    return empty_wx unless data

    el = ->(tag) { data.elements[tag]&.text&.strip }

    solar_flux = el.('solarflux')&.to_f
    kp         = el.('kindex')&.to_f

    bands = {}
    doc.elements.each('solar/solardata/calculatedconditions/band') do |b|
      name = b.attributes['name']
      time = b.attributes['time']
      bands[name] ||= {}
      bands[name][time] = b.text&.strip
    end

    {
      solar_flux:  solar_flux,
      sunspots:    el.('sunspots')&.to_i,
      kp_index:    kp,
      a_index:     el.('aindex')&.to_f,
      x_ray:       el.('xray'),
      solar_wind:  el.('solarwind')&.to_f,
      mag_field:   el.('magneticfield')&.to_f,
      aurora:      el.('aurora')&.to_i,
      aurora_lat:  el.('latdegree')&.to_f,
      helium:      el.('heliumline')&.to_f,
      geomag:      kp_to_storm(kp),
      propagation: propagation_assessment(solar_flux, kp),
      bands:       bands,
      updated:     el.('updated') || Time.now.strftime('%d %b %Y %H%M GMT'),
      source:      'N0NBH/hamqsl.com (solar.w5mmw.net)'
    }
  rescue => e
    warn "space_weather error: #{e.class}: #{e.message}"
    empty_wx
  end

  def self.empty_wx
    { propagation: { label: 'N/A', level: 0 }, bands: {}, error: true }
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

  # ── Air quality via WAQI ─────────────────────────────────────────────────
  # Lokalizacja: Rumia > Szemud > fallback geo
  WAQI_TOKEN = ENV.fetch('WAQI_TOKEN') { raise 'Set WAQI_TOKEN env var — see .env.example' }.freeze
  WAQI_BASE  = 'https://api.waqi.info/feed'.freeze
  WAQI_CITIES = ['geo:54.5726;18.3965'].freeze  # Rumia/Szemud nie ma stacji w WAQI

  def self.air_quality
    data = nil
    city_used = nil

    WAQI_CITIES.each do |city|
      url  = "#{WAQI_BASE}/#{city}/?token=#{WAQI_TOKEN}"
      resp = fetch_json(url)
      next unless resp.is_a?(Hash) && resp['status'] == 'ok' && resp['data'].is_a?(Hash)
      next unless resp['data']['aqi'].to_i > 0
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

  def self.air_quality_debug
    out = []
    WAQI_CITIES.each do |city|
      url  = "#{WAQI_BASE}/#{city}/?token=#{WAQI_TOKEN}"
      resp = fetch_json(url)
      if resp.is_a?(Hash)
        d = resp['data']
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
