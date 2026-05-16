require_relative 'fetchers/base'
require_relative 'fetchers/space_weather'
require_relative 'fetchers/air_quality'
require_relative 'fetchers/ruby_news'

module Fetchers
  HAMQSL_XML = SpaceWeather::HAMQSL_XML
  WEJHEROWO  = { lat: 54.6076, lon: 18.2350 }.freeze

  def self.fetch(url, **) = Base.fetch(url, **)
  def self.fetch_json(url) = Base.fetch_json(url)
  def self.ruby_news(**) = RubyNews.fetch_items(**)
  def self.space_weather = SpaceWeather.fetch_data
  def self.air_quality = AirQuality.fetch_data
  def self.air_quality_debug = AirQuality.fetch_debug
end
