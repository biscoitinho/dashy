module Fetchers
  module SunTimes
    LAT = 54.6076
    LON = 18.2350

    def self.for_today
      today = Date.today
      rise, set = calculate(LAT, LON, today)
      {
        sunrise:    rise&.strftime('%H:%M'),
        sunset:     set&.strftime('%H:%M'),
        day_length: rise && set ? format_duration(set - rise) : nil
      }
    end

    # Returns [declination_degrees, hour_angle_degrees] for given Julian day offset
    def self.solar_position(n)
      l   = (280.46 + (0.9856474 * n)) % 360
      g   = (357.528 + (0.9856003 * n)) % 360
      lam = (l + (1.915 * Math.sin(g * Math::PI / 180)) + (0.020 * Math.sin(2 * g * Math::PI / 180))) % 360
      eps = 23.439 - (0.0000004 * n)
      Math.asin(Math.sin(eps * Math::PI / 180) * Math.sin(lam * Math::PI / 180)) * 180 / Math::PI
    end

    def self.calculate(lat, lon, date)
      n   = date.jd.to_f - 2_451_545.0
      dec = solar_position(n)

      cos_h = (Math.cos(90.833 * Math::PI / 180) -
               (Math.sin(lat * Math::PI / 180) * Math.sin(dec * Math::PI / 180))) /
              (Math.cos(lat * Math::PI / 180) * Math.cos(dec * Math::PI / 180))

      return [nil, nil] if cos_h.abs > 1 # midnight sun or polar night

      h        = Math.acos(cos_h) * 180 / Math::PI
      noon_utc = 12.0 - (lon / 15.0)
      rise_utc = noon_utc - (h / 15.0)
      set_utc  = noon_utc + (h / 15.0)

      tz_offset  = Time.now.utc_offset / 3600.0
      [decimal_to_time(date, rise_utc + tz_offset),
       decimal_to_time(date, set_utc + tz_offset)]
    rescue StandardError => e
      warn "sun_times error: #{e.class}: #{e.message}"
      [nil, nil]
    end

    def self.decimal_to_time(date, hours)
      h = hours.floor % 24
      m = ((hours - hours.floor) * 60).round
      if m >= 60
        m = 0
        h = (h + 1) % 24
      end
      Time.new(date.year, date.month, date.day, h, m, 0)
    end

    def self.format_duration(seconds)
      total_minutes = (seconds / 60).round
      h = total_minutes / 60
      m = total_minutes % 60
      "#{h}h #{m}m"
    end
  end
end
