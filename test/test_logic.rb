require 'minitest/autorun'
require 'date'

# Stub WAQI_TOKEN before loading fetchers
ENV['WAQI_TOKEN'] ||= 'test_token'

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require_relative '../lib/fetchers/base'
require_relative '../lib/fetchers/space_weather'
require_relative '../lib/fetchers/air_quality'
require_relative '../lib/fetchers/sun_times'
require_relative '../lib/fetchers/dx_cluster'
require_relative '../lib/band_plan'
require_relative '../lib/ruby_tips'

class TestSpaceWeatherKpToStorm < Minitest::Test
  def test_nil_returns_na
    assert_equal 'N/A', Fetchers::SpaceWeather.kp_to_storm(nil)
  end

  def test_zero_returns_very_quiet
    assert_equal 'Very Quiet', Fetchers::SpaceWeather.kp_to_storm(0)
  end

  def test_one_returns_quiet
    assert_equal 'Quiet', Fetchers::SpaceWeather.kp_to_storm(1)
  end

  def test_three_returns_unsettled
    assert_equal 'Unsettled', Fetchers::SpaceWeather.kp_to_storm(3)
  end

  def test_four_returns_minor_g1
    assert_equal 'Minor (G1)', Fetchers::SpaceWeather.kp_to_storm(4)
  end

  def test_five_returns_moderate_g2
    assert_equal 'Moderate (G2)', Fetchers::SpaceWeather.kp_to_storm(5)
  end

  def test_six_returns_strong_g3
    assert_equal 'Strong (G3)', Fetchers::SpaceWeather.kp_to_storm(6)
  end

  def test_seven_returns_severe_g4
    assert_equal 'Severe (G4)', Fetchers::SpaceWeather.kp_to_storm(7)
  end

  def test_eight_returns_extreme_g5
    assert_equal 'Extreme (G5)', Fetchers::SpaceWeather.kp_to_storm(8)
  end

  def test_nine_returns_extreme_g5
    assert_equal 'Extreme (G5)', Fetchers::SpaceWeather.kp_to_storm(9)
  end
end

class TestSpaceWeatherPropagationAssessment < Minitest::Test
  def test_both_nil_returns_na
    result = Fetchers::SpaceWeather.propagation_assessment(nil, nil)
    assert_equal 'N/A', result[:label]
    assert_equal 0, result[:level]
  end

  def test_high_kp_returns_zaklocona
    result = Fetchers::SpaceWeather.propagation_assessment(100, 5)
    assert_equal 'ZAKLOCONA (burza)', result[:label]
    assert_equal(-2, result[:level])
  end

  def test_kp4_returns_niestabilna
    result = Fetchers::SpaceWeather.propagation_assessment(100, 4)
    assert_equal 'NIESTABILNA', result[:label]
    assert_equal(-1, result[:level])
  end

  def test_kp3_returns_zmienna
    result = Fetchers::SpaceWeather.propagation_assessment(100, 3)
    assert_equal 'ZMIENNA', result[:label]
    assert_equal 0, result[:level]
  end

  def test_high_flux_returns_doskonala
    result = Fetchers::SpaceWeather.propagation_assessment(150, 0)
    assert_equal 'DOSKONALA', result[:label]
    assert_equal 3, result[:level]
  end

  def test_flux_120_returns_bardzo_dobra
    result = Fetchers::SpaceWeather.propagation_assessment(120, 0)
    assert_equal 'BARDZO DOBRA', result[:label]
    assert_equal 2, result[:level]
  end

  def test_low_flux_returns_slaba
    result = Fetchers::SpaceWeather.propagation_assessment(50, 0)
    assert_equal 'SLABA', result[:label]
    assert_equal(-1, result[:level])
  end

  def test_nil_kp_with_high_flux
    result = Fetchers::SpaceWeather.propagation_assessment(160, nil)
    assert_equal 'DOSKONALA', result[:label]
  end
end

class TestAirQualityEuAqiLevel < Minitest::Test
  def test_aqi_50_is_good
    result = Fetchers::AirQuality.eu_aqi_level(50)
    assert_equal 'Dobry', result[:label]
    assert_equal 0, result[:level]
  end

  def test_aqi_51_is_moderate
    result = Fetchers::AirQuality.eu_aqi_level(51)
    assert_equal 'Umiarkowany', result[:label]
    assert_equal 1, result[:level]
  end

  def test_aqi_100_is_moderate
    result = Fetchers::AirQuality.eu_aqi_level(100)
    assert_equal 'Umiarkowany', result[:label]
    assert_equal 1, result[:level]
  end

  def test_aqi_101_is_unhealthy_sensitive
    result = Fetchers::AirQuality.eu_aqi_level(101)
    assert_equal 'Niezdrowy*', result[:label]
    assert_equal 2, result[:level]
  end

  def test_aqi_150_is_unhealthy_sensitive
    result = Fetchers::AirQuality.eu_aqi_level(150)
    assert_equal 'Niezdrowy*', result[:label]
    assert_equal 2, result[:level]
  end

  def test_aqi_200_is_unhealthy
    result = Fetchers::AirQuality.eu_aqi_level(200)
    assert_equal 'Niezdrowy', result[:label]
    assert_equal 3, result[:level]
  end

  def test_aqi_300_is_very_bad
    result = Fetchers::AirQuality.eu_aqi_level(300)
    assert_equal 'Bardzo zly', result[:label]
    assert_equal 4, result[:level]
  end

  def test_aqi_301_is_extreme
    result = Fetchers::AirQuality.eu_aqi_level(301)
    assert_equal 'Ekstremalny', result[:label]
    assert_equal 5, result[:level]
  end
end

class TestAirQualityAqiLabel < Minitest::Test
  def test_pm25_at_12_is_good
    result = Fetchers::AirQuality.aqi_label(12, :pm25)
    assert_equal 'Dobry', result[:label]
    assert_equal 0, result[:level]
    assert_equal 12, result[:value]
  end

  def test_pm25_at_13_is_moderate
    result = Fetchers::AirQuality.aqi_label(13, :pm25)
    assert_equal 'Umiarkowany', result[:label]
    assert_equal 1, result[:level]
  end

  def test_pm25_at_35_is_moderate
    result = Fetchers::AirQuality.aqi_label(35, :pm25)
    assert_equal 'Umiarkowany', result[:label]
    assert_equal 1, result[:level]
  end

  def test_pm10_at_20_is_good
    result = Fetchers::AirQuality.aqi_label(20, :pm10)
    assert_equal 'Dobry', result[:label]
    assert_equal 0, result[:level]
  end

  def test_pm10_at_21_is_moderate
    result = Fetchers::AirQuality.aqi_label(21, :pm10)
    assert_equal 'Umiarkowany', result[:label]
    assert_equal 1, result[:level]
  end

  def test_pm10_at_150_is_very_bad
    result = Fetchers::AirQuality.aqi_label(150, :pm10)
    assert_equal 'Bardzo zly', result[:label]
    assert_equal 4, result[:level]
  end

  def test_pm25_above_250_is_extreme
    result = Fetchers::AirQuality.aqi_label(300, :pm25)
    assert_equal 'Ekstremalny', result[:label]
    assert_equal 5, result[:level]
  end
end

class TestRubyTipsToday < Minitest::Test
  def test_returns_hash
    tip = RubyTips.today
    assert_instance_of Hash, tip
  end

  def test_has_title_key
    tip = RubyTips.today
    assert tip.key?(:title), 'tip should have :title key'
  end

  def test_has_code_key
    tip = RubyTips.today
    assert tip.key?(:code), 'tip should have :code key'
  end

  def test_title_is_string
    assert_instance_of String, RubyTips.today[:title]
  end

  def test_code_is_string
    assert_instance_of String, RubyTips.today[:code]
  end

  def test_does_not_crash
    RubyTips.today
    pass
  end
end

class TestSunTimesFormatDuration < Minitest::Test
  def test_zero_seconds
    assert_equal '0h 0m', Fetchers::SunTimes.format_duration(0)
  end

  def test_one_hour
    assert_equal '1h 0m', Fetchers::SunTimes.format_duration(3600)
  end

  def test_one_hour_thirty_min
    assert_equal '1h 30m', Fetchers::SunTimes.format_duration(5400)
  end

  def test_long_day
    assert_equal '17h 3m', Fetchers::SunTimes.format_duration(61_380)
  end
end

class TestSunTimesDecimalToTime < Minitest::Test
  def test_basic_conversion
    date = Date.new(2025, 6, 21)
    t = Fetchers::SunTimes.decimal_to_time(date, 6.5)
    assert_equal 6, t.hour
    assert_equal 30, t.min
  end

  def test_minute_rollover
    date = Date.new(2025, 6, 21)
    t = Fetchers::SunTimes.decimal_to_time(date, 5.9999)
    assert_equal 6, t.hour
    assert_equal 0, t.min
  end

  def test_midnight_wraps
    date = Date.new(2025, 6, 21)
    t = Fetchers::SunTimes.decimal_to_time(date, 24.0)
    assert_equal 0, t.hour
  end
end

class TestSunTimesCalculate < Minitest::Test
  def test_returns_two_element_array
    result = Fetchers::SunTimes.calculate(54.6076, 18.2350, Date.new(2025, 6, 21))
    assert_equal 2, result.size
  end

  def test_returns_times_for_wejherowo_summer
    rise, set = Fetchers::SunTimes.calculate(54.6076, 18.2350, Date.new(2025, 6, 21))
    refute_nil rise
    refute_nil set
    assert rise.is_a?(Time)
    assert set.is_a?(Time)
    assert set > rise, 'sunset should be after sunrise'
  end

  def test_for_today_returns_expected_keys
    result = Fetchers::SunTimes.for_today
    assert result.key?(:sunrise)
    assert result.key?(:sunset)
    assert result.key?(:day_length)
  end

  def test_for_today_sunrise_format
    result = Fetchers::SunTimes.for_today
    assert_match(/\A\d{2}:\d{2}\z/, result[:sunrise]) if result[:sunrise]
  end

  def test_for_today_day_length_format
    result = Fetchers::SunTimes.for_today
    assert_match(/\A\d+h \d+m\z/, result[:day_length]) if result[:day_length]
  end
end

class TestDxClusterKhzToBand < Minitest::Test
  def test_160m
    assert_equal '160m', Fetchers::DxCluster.khz_to_band(1850)
  end

  def test_80m
    assert_equal '80m', Fetchers::DxCluster.khz_to_band(3600)
  end

  def test_40m
    assert_equal '40m', Fetchers::DxCluster.khz_to_band(7100)
  end

  def test_30m
    assert_equal '30m', Fetchers::DxCluster.khz_to_band(10_125)
  end

  def test_20m
    assert_equal '20m', Fetchers::DxCluster.khz_to_band(14_200)
  end

  def test_17m
    assert_equal '17m', Fetchers::DxCluster.khz_to_band(18_100)
  end

  def test_15m
    assert_equal '15m', Fetchers::DxCluster.khz_to_band(21_200)
  end

  def test_12m
    assert_equal '12m', Fetchers::DxCluster.khz_to_band(24_940)
  end

  def test_10m
    assert_equal '10m', Fetchers::DxCluster.khz_to_band(28_500)
  end

  def test_6m
    assert_equal '6m', Fetchers::DxCluster.khz_to_band(51_000)
  end

  def test_unknown_returns_mhz
    result = Fetchers::DxCluster.khz_to_band(145_000)
    assert_match(/MHz/, result)
  end

  def test_boundary_160m_lower
    assert_equal '160m', Fetchers::DxCluster.khz_to_band(1800)
  end

  def test_boundary_20m_upper
    assert_equal '20m', Fetchers::DxCluster.khz_to_band(14_350)
  end
end

class TestDxClusterParseTime < Minitest::Test
  def test_nil_returns_placeholder
    assert_equal '--:--', Fetchers::DxCluster.parse_time(nil)
  end

  def test_invalid_string_returns_placeholder
    assert_equal '--:--', Fetchers::DxCluster.parse_time('not a time')
  end

  def test_valid_iso_returns_formatted_time
    result = Fetchers::DxCluster.parse_time('2025-06-21T12:30:00Z')
    assert_match(/\A\d{2}:\d{2}\z/, result)
  end
end

class TestBandPlan < Minitest::Test
  def test_all_returns_array
    assert_instance_of Array, BandPlan.all
  end

  def test_all_returns_hashes_with_required_keys
    BandPlan.all.each do |band|
      assert band.key?(:name),   'band missing :name key'
      assert band.key?(:range),  'band missing :range key'
      assert band.key?(:modes),  'band missing :modes key'
    end
  end

  def test_hf_excludes_cb
    names = BandPlan.hf.map { |b| b[:name] }
    refute_includes names, 'CB'
  end

  def test_hf_excludes_6m
    names = BandPlan.hf.map { |b| b[:name] }
    refute_includes names, '6m'
  end

  def test_hf_excludes_2m
    names = BandPlan.hf.map { |b| b[:name] }
    refute_includes names, '2m'
  end

  def test_hf_excludes_70cm
    names = BandPlan.hf.map { |b| b[:name] }
    refute_includes names, '70cm'
  end

  def test_hf_includes_20m
    names = BandPlan.hf.map { |b| b[:name] }
    assert_includes names, '20m'
  end

  def test_hf_includes_40m
    names = BandPlan.hf.map { |b| b[:name] }
    assert_includes names, '40m'
  end
end
