# Wczytaj .env automatycznie jesli istnieje
require 'English'
env_file = File.join(__dir__, '.env')
if File.exist?(env_file)
  File.readlines(env_file).each do |line|
    line = line.strip.sub(/^export\s+/, '')
    next if line.empty? || line.start_with?('#')

    key, val = line.split('=', 2)
    ENV[key] = val if key && val
  end
end

require 'sinatra'
require 'json'
require 'date'
require_relative 'lib/fetchers'
require_relative 'lib/terminal_helpers'
require_relative 'lib/band_plan'
require_relative 'lib/ruby_tips'

set :port,  ENV.fetch('PORT', 4567).to_i
set :bind,  '0.0.0.0'
set :views, File.join(__dir__, 'views')

helpers TerminalHelpers

CACHE       = {} # rubocop:disable Style/MutableConstant
CACHE_MUTEX = Mutex.new
CACHE_TTL   = 600

REFRESH_COOLDOWN = 30
LAST_REFRESH     = { at: Time.now - REFRESH_COOLDOWN } # rubocop:disable Style/MutableConstant

def cached(key, ttl = CACHE_TTL)
  CACHE_MUTEX.synchronize do
    entry = CACHE[key]
    return entry[:data] if entry && (Time.now - entry[:at]) < ttl

    data = yield
    CACHE[key] = { data: data, at: Time.now }
    data
  end
end

Thread.new do
  loop do
    sleep CACHE_TTL - 30 # refresh 30s before expiry
    begin
      cached(:ruby_news)          { Fetchers.ruby_news }
      cached(:space_wx)           { Fetchers.space_weather }
      cached(:air, 3600)          { Fetchers.air_quality }
      cached(:dx_spots, 300)      { Fetchers.dx_spots }
      cached(:kp_forecast, 3600)  { Fetchers.kp_forecast }
      cached(:sota_pota, 300)     { Fetchers.sota_pota }
    rescue StandardError => e
      warn "background prefetch error: #{e.class}: #{e.message}"
    end
  end
end

def dashboard_data
  {
    ruby_news:   cached(:ruby_news)         { Fetchers.ruby_news },
    space_wx:    cached(:space_wx)          { Fetchers.space_weather },
    air:         cached(:air, 3600)         { Fetchers.air_quality },
    dx_spots:    cached(:dx_spots, 300)     { Fetchers.dx_spots },
    kp_forecast: cached(:kp_forecast, 3600) { Fetchers.kp_forecast },
    sota_pota:   cached(:sota_pota, 300)    { Fetchers.sota_pota },
    band_plan:   BandPlan.all,
    ruby_tip:    RubyTips.today,
    sun:         Fetchers.sun_times,
    cal:         `cal`.chomp,
    time:        Time.now.strftime('%H:%M:%S %Z'),
    utc:         Time.now.utc.strftime('%H:%M UTC'),
    date:        Time.now.strftime('%A, %d %B %Y'),
    fetched:     Time.now.strftime('%H:%M')
  }
end

get '/' do
  @d        = dashboard_data
  curl_like = request.user_agent&.match?(/curl|wget|httpie/i)
  plain     = curl_like || params[:format] == 'text'

  if plain
    content_type 'text/plain; charset=utf-8'
    setup_terminal(params[:plain] != '1', (params[:width] || '76').to_i.clamp(50, 220))
    erb :index_text, layout: false
  else
    erb :index, layout: :layout
  end
end

get '/data.json' do
  cache_control :no_cache
  content_type :json
  dashboard_data.to_json
end

get '/refresh' do
  last = CACHE_MUTEX.synchronize { LAST_REFRESH[:at] }
  halt 429, 'Too fast — wait 30s between refreshes' if Time.now - last < REFRESH_COOLDOWN

  CACHE_MUTEX.synchronize do
    CACHE.clear
    LAST_REFRESH[:at] = Time.now
  end
  redirect '/'
end

get '/debug/air' do
  content_type 'text/plain; charset=utf-8'
  Fetchers.air_quality_debug
end

get '/debug/noaa' do
  content_type 'text/plain; charset=utf-8'
  body = begin
    Fetchers.fetch(Fetchers::HAMQSL_XML)
  rescue
    "ERROR: #{$ERROR_INFO}"
  end
  "URL: #{Fetchers::HAMQSL_XML}\n#{body ? "OK #{body.bytesize}b\n#{body.slice(0, 400)}" : 'FAILED'}"
end
