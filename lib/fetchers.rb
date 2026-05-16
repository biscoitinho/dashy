require_relative 'fetchers/base'
require_relative 'fetchers/space_weather'
require_relative 'fetchers/air_quality'
require_relative 'fetchers/ruby_news'
require_relative 'fetchers/sun_times'
require_relative 'fetchers/dx_cluster'
require_relative 'fetchers/kp_forecast'
require_relative 'fetchers/sota_pota'

module Fetchers
  HAMQSL_XML = SpaceWeather::HAMQSL_XML
  WEJHEROWO  = { lat: 54.6076, lon: 18.2350 }.freeze

  def self.fetch(url, **) = Base.fetch(url, **)
  def self.fetch_json(url) = Base.fetch_json(url)
  def self.ruby_news(**) = RubyNews.fetch_items(**)
  def self.space_weather = SpaceWeather.fetch_data
  def self.air_quality = AirQuality.fetch_data
  def self.air_quality_debug = AirQuality.fetch_debug
  def self.sun_times = SunTimes.for_today
  def self.dx_spots = DxCluster.fetch_spots
  def self.kp_forecast = KpForecast.fetch_data
  def self.sota_pota = SotaPota.fetch_all
end
