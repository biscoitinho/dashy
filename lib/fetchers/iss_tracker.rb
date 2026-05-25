require 'time'

module Fetchers
  module IssTracker
    TLE_URL = 'https://celestrak.org/NORAD/elements/gp.php?CATNR=25544&FORMAT=TLE'.freeze

    LAT = 54.6076  # Wejherowo / Trójmiasto
    LON = 18.2350
    ALT = 0.050    # km n.p.m.

    MIN_EL   = 5.0   # minimalna elewacja [deg]
    STEP     = 30    # krok symulacji [s]
    HORIZON  = 86_400 # okno predykcji [s] = 24h

    # Częstotliwości ISS / ARISS (IARU Region 1)
    FREQS = {
      voice_dn: '145.800 MHz FM',
      voice_up: '145.200 MHz FM',
      aprs:     '145.825 MHz FM',
      rep_dn:   '437.800 MHz FM (repeater)',
      rep_up:   '145.990 MHz FM (repeater)'
    }.freeze

    def self.fetch_passes
      tle = fetch_tle
      return empty_result unless tle

      passes = predict_passes(tle, Time.now.utc, Time.now.utc + HORIZON)
      {
        passes:    passes.first(5),
        freqs:     FREQS,
        tle_epoch: tle[:epoch]
      }
    rescue => e
      warn "iss_tracker error: #{e.class}: #{e.message}"
      empty_result
    end

    def self.empty_result
      { passes: [], freqs: FREQS, tle_epoch: nil }
    end

    # ── TLE fetch ─────────────────────────────────────────────────────────────

    def self.fetch_tle
      body = Fetchers::Base.fetch(TLE_URL)
      return nil unless body

      lines = body.strip.lines.map(&:strip).reject(&:empty?)
      return nil unless lines.size >= 3

      { name: lines[0], line1: lines[1], line2: lines[2],
        epoch: parse_epoch(lines[1]) }
    end

    def self.parse_epoch(line1)
      raw  = line1[18..31].strip
      yy   = raw[0, 2].to_i
      year = yy < 57 ? 2000 + yy : 1900 + yy
      doy  = raw[2..].to_f
      Time.utc(year, 1, 1) + ((doy - 1) * 86_400)
    rescue
      Time.now.utc
    end

    # ── Uproszczona propagacja orbitalna (Keplerian + rotacja Ziemi) ──────────

    def self.predict_passes(tle, from_t, to_t)
      orb   = parse_tle(tle)
      obs   = observer_ecef(LAT, LON, ALT)
      passes = []
      pass = nil

      t = from_t
      while t <= to_t
        el, az = elevation_azimuth(orb, obs, t)

        if el >= MIN_EL
          if pass.nil?
            pass = { start: t, end: t, max_el: el, max_az: az }
          else
            pass[:end] = t
            pass[:max_el] = el if el > pass[:max_el]
          end
        elsif pass
          passes << pass
          pass = nil
        end

        t += STEP
      end
      passes << pass if pass

      passes.map { |p| format_pass(p) }
    end

    def self.parse_tle(tle)
      l2  = tle[:line2]
      mm  = l2[52, 11].strip.to_f
      n   = mm * 2 * Math::PI / 86_400.0
      mu  = 398_600.4418
      {
        epoch: tle[:epoch],
        inc:   l2[8,  8].strip.to_f * Math::PI / 180,
        raan:  l2[17, 8].strip.to_f * Math::PI / 180,
        ecc:   "0.#{l2[26, 7].strip}".to_f,
        aop:   l2[34, 8].strip.to_f * Math::PI / 180,
        ma:    l2[43, 8].strip.to_f * Math::PI / 180,
        n:     n,
        a:     (mu / (n**2))**(1.0 / 3)
      }
    end

    def self.observer_ecef(lat_deg, lon_deg, alt_km)
      re  = 6378.137
      lat = lat_deg * Math::PI / 180
      lon = lon_deg * Math::PI / 180
      r   = re + alt_km
      [r * Math.cos(lat) * Math.cos(lon),
       r * Math.cos(lat) * Math.sin(lon),
       r * Math.sin(lat)]
    end

    def self.elevation_azimuth(orb, obs, time)
      # Propagacja M(t)
      dt = time - orb[:epoch]
      m  = (orb[:ma] + (orb[:n] * dt)) % (2 * Math::PI)

      # Anomalia ekscentryczna (iteracja Keplera)
      ea = m
      6.times { ea = m + (orb[:ecc] * Math.sin(ea)) }

      # Anomalia prawdziwa
      ta = 2 * Math.atan2(
        Math.sqrt(1 + orb[:ecc]) * Math.sin(ea / 2),
        Math.sqrt(1 - orb[:ecc]) * Math.cos(ea / 2)
      )

      # Odległość od centrum Ziemi
      rad = orb[:a] * (1 - (orb[:ecc] * Math.cos(ea)))

      # Peryfokalne → ECI
      px = rad * Math.cos(ta)
      py = rad * Math.sin(ta)

      co = Math.cos(orb[:raan])
      so = Math.sin(orb[:raan])
      ci = Math.cos(orb[:inc])
      si = Math.sin(orb[:inc])
      cw = Math.cos(orb[:aop])
      sw = Math.sin(orb[:aop])

      xi = (((co * cw) - (so * sw * ci)) * px) + (((-co * sw) - (so * cw * ci)) * py)
      yi = (((so * cw) + (co * sw * ci)) * px) + (((-so * sw) + (co * cw * ci)) * py)
      zi = (sw * si * px) + (cw * si * py)

      # ECI → ECEF (Greenwich Sidereal Time)
      gst = greenwich_sidereal_time(time)
      x = (xi * Math.cos(gst)) + (yi * Math.sin(gst))
      y = (-xi * Math.sin(gst)) + (yi * Math.cos(gst))
      z = zi

      # Wektor obserwator → satelita
      dx = x - obs[0]
      dy = y - obs[1]
      dz = z - obs[2]
      rng = Math.sqrt((dx * dx) + (dy * dy) + (dz * dz))

      lat = LAT * Math::PI / 180
      lon = LON * Math::PI / 180
      sl = Math.sin(lat)
      cl = Math.cos(lat)
      so2 = Math.sin(lon)
      co2 = Math.cos(lon)

      south  = (-sl * co2 * dx) - (sl * so2 * dy) + (cl * dz)
      east   = (-so2 * dx) + (co2 * dy)
      zenith = (cl * co2 * dx) + (cl * so2 * dy) + (sl * dz)

      el = Math.asin(zenith / rng) * 180 / Math::PI
      az = (Math.atan2(east, south) * 180 / Math::PI) % 360
      [el, az]
    end

    def self.greenwich_sidereal_time(time)
      jd   = (time.to_f / 86_400.0) + 2_440_587.5
      t    = (jd - 2_451_545.0) / 36_525.0
      gmst = 280.46061837 + (360.98564736629 * (jd - 2_451_545.0)) + (0.000387933 * t * t)
      (gmst % 360) * Math::PI / 180
    end

    def self.format_pass(pass)
      dur = (pass[:end] - pass[:start]).to_i
      {
        start_local: pass[:start].localtime,
        end_local:   pass[:end].localtime,
        duration_s:  dur,
        max_el:      pass[:max_el].round(1),
        quality:     el_quality(pass[:max_el])
      }
    end

    def self.el_quality(el)
      if    el >= 60 then 'doskonaly'
      elsif el >= 30 then 'dobry'
      elsif el >= 10 then 'slaby'
      else                'marginalny'
      end
    end
  end
end
