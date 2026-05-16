# Wczytaj .env automatycznie jesli istnieje
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

CACHE     = {}
CACHE_TTL = 600

def cached(key, ttl = CACHE_TTL)
  entry = CACHE[key]
  return entry[:data] if entry && (Time.now - entry[:at]) < ttl
  data = yield
  CACHE[key] = { data: data, at: Time.now }
  data
end

def dashboard_data
  {
    ruby_news:  cached(:ruby_news)  { Fetchers.ruby_news },
    space_wx:   cached(:space_wx)   { Fetchers.space_weather },
    air:        cached(:air, 3600)  { Fetchers.air_quality },
    band_plan:  BandPlan.all,
    ruby_tip:   RubyTips.today,
    cal:        `cal`.chomp,
    time:       Time.now.strftime('%H:%M:%S %Z'),
    date:       Time.now.strftime('%A, %d %B %Y'),
    fetched:    Time.now.strftime('%H:%M')
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
  CACHE.clear
  redirect '/'
end

get '/debug/air' do
  content_type 'text/plain; charset=utf-8'
  Fetchers.air_quality_debug
end

get '/debug/noaa' do
  content_type 'text/plain; charset=utf-8'
  body = Fetchers.fetch(Fetchers::HAMQSL_XML) rescue "ERROR: #{$!}"
  "URL: #{Fetchers::HAMQSL_XML}\n#{body ? "OK #{body.bytesize}b\n#{body.slice(0,400)}" : 'FAILED'}"
end
