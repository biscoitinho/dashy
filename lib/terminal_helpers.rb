module TerminalHelpers

  def setup_terminal(use_color, width)
    @tc = use_color
    @tw = width
  end

  def tw; @tw || 70; end

  def tc(code, t); @tc ? "\e[#{code}m#{t}\e[0m" : t; end
  def t_dim(t);    tc('2',    t); end
  def t_bold(t);   tc('1',    t); end
  def t_green(t);  tc('92',   t); end
  def t_amber(t);  tc('93',   t); end
  def t_red(t);    tc('91',   t); end
  def t_cyan(t);   tc('96',   t); end
  def t_blue(t);   tc('94',   t); end
  def t_white(t);  tc('97',   t); end
  def t_bgreen(t); tc('1;92', t); end
  def t_bred(t);   tc('1;91', t); end

  def t_vlen(s)
    s.to_s.gsub(/\e\[[0-9;]*m/, '').length
  end

  def bc
    @tc ? { tl:'╭',tr:'╮',bl:'╰',br:'╯',h:'─',v:'│',ml:'├',mr:'┤',th:'╌' }
        : { tl:'+', tr:'+', bl:'+', br:'+', h:'-',v:'|',ml:'+', mr:'+', th:'-' }
  end

  def t_box_top(title = nil, width = nil)
    width ||= tw
    b = bc
    if title
      t      = @tc ? t_amber(title) : title
      dashes = [width - t_vlen(t) - 4, 2].max
      l = dashes / 2; r = dashes - l
      "#{t_dim(b[:tl])}#{t_dim(b[:h]*l)} #{t} #{t_dim(b[:h]*r)}#{t_dim(b[:tr])}
"
    else
      "#{t_dim(b[:tl])}#{t_dim(b[:h]*(width-2))}#{t_dim(b[:tr])}
"
    end
  end

  def t_box_bot(width = nil)
    width ||= tw
    b = bc
    "#{t_dim(b[:bl])}#{t_dim(b[:h]*(width-2))}#{t_dim(b[:br])}
"
  end

  def t_box_sep(width = nil)
    width ||= tw
    b = bc
    "#{t_dim(b[:ml])}#{t_dim(b[:th]*(width-2))}#{t_dim(b[:mr])}
"
  end

  def t_box_row(content = '', width = nil)
    width ||= tw
    b   = bc
    pad = [width - 4 - t_vlen(content.to_s), 0].max
    "#{t_dim(b[:v])}  #{content}#{' ' * pad}#{t_dim(b[:v])}
"
  end

  def t_two_col(label1, val1, label2, val2, width = nil)
    width ||= tw
    col  = (width - 4) / 2
    left = t_dim(label1) + val1.to_s
    right= t_dim(label2) + val2.to_s
    pad  = [col - t_vlen(left), 0].max
    t_box_row(left + ' ' * pad + right, width)
  end

  def t_bar(val, max, len = 10)
    return t_dim('·' * len) unless val
    filled = [[(val.to_f / max * len).round, len].min, 0].max
    t_green('█' * filled) + t_dim('░' * (len - filled))
  end

  def t_cond(cond)
    case cond&.downcase
    when 'excellent' then t_bgreen(cond)
    when 'good'      then t_green(cond)
    when 'fair'      then t_amber(cond)
    when 'poor'      then t_red(cond)
    else                  t_dim(cond || 'N/A')
    end
  end

  def t_prop(text, level)
    case level
    when 2, 3  then t_bgreen(text)
    when 0, 1  then t_amber(text)
    else            t_bred(text)
    end
  end

  # HTML helpers
  def cond_pct(cond)
    case cond&.downcase
    when 'excellent' then 100
    when 'good'      then 75
    when 'fair'      then 40
    else                  8
    end
  end

  def cond_cls(cond)
    "fill-#{cond&.downcase || 'poor'}"
  end

  def cond_text_cls(cond)
    "cond-#{cond&.downcase || 'poor'}"
  end

  # Bloki — renderują całe sekcje bez pętli w ERB
  def t_cal_block(cal_str)
    cal_str.each_line.map { |l| t_box_row(t_cyan(l.chomp)) }.join("")
  end

  def t_bands_block(bands)
    return '' if bands.empty?
    lines = []
    lines << t_box_sep
    lines << t_box_row(t_amber("PASMA HF") + t_dim("          \u2600 dzien              \u263e noc"))
    lines << t_box_sep
    bands.sort.each do |name, times|
      day_bar   = t_bar(cond_pct(times['day']),   100, 7)
      night_bar = t_bar(cond_pct(times['night']), 100, 7)
      lines << t_box_row(
        t_amber("%-10s" % name) +
        day_bar + " " + t_cond("%-9s" % times['day'].to_s) + "  " +
        night_bar + " " + t_cond(times['night'].to_s)
      )
    end
    lines.join("")
  end

  def t_news_block(news)
    return t_box_row(t_red("brak danych")) if news.empty?
    lines = []
    news.each_with_index do |item, i|
      lines << t_box_row(t_dim("%02d." % (i + 1)) + "  " + t_green(item[:title].to_s.slice(0, @tw - 8)))
      lines << t_box_row(t_dim("    -> ") + t_blue(item[:link].to_s.slice(0, @tw - 10))) if item[:link]
      lines << t_box_row('')
    end
    lines.join("")
  end

  def t_bandplan_block(bands)
    lines = []
    bands.each do |b|
      name    = t_amber("%-6s" % b[:name])
      range   = t_dim("%-18s" % b[:range])
      modes   = t_white("%-12s" % b[:modes])
      calling = t_cyan(b[:calling].slice(0, @tw - 44))
      lines << t_box_row("#{name} #{range} #{modes} #{calling}")
    end
    lines.join("")
  end

  def t_tip_block(tip)
    return t_box_row(t_dim("no tip today")) unless tip
    lines = []
    lines << t_box_row(t_amber("TIP: ") + t_white(tip[:title]))
    lines << t_box_row(t_dim("  ") + t_green(tip[:code].slice(0, @tw - 6)))
    lines << t_box_row(t_dim("  → " + tip[:note].to_s.slice(0, @tw - 8))) if tip[:note]
    lines.join("")
  end

  def t_air_block(air)
    return t_box_row(t_dim("brak danych o jakosci powietrza")) unless air
    # Uzywamy aqi_lvl (indeks WAQI) jako glownego statusu
    lbl   = air[:aqi_lvl] || air[:aqi_pm25]
    color = lbl ? case lbl[:level]
                  when 0, 1 then method(:t_green)
                  when 2, 3 then method(:t_amber)
                  else           method(:t_red)
                  end
                : method(:t_dim)
    mu = "μg/m³"
    pm25 = air[:pm25] ? t_white("#{air[:pm25]} #{mu}") : t_dim('N/A')
    pm10 = air[:pm10] ? t_white("#{air[:pm10]} #{mu}") : t_dim('N/A')
    no2  = air[:no2]  ? t_dim("#{air[:no2]} #{mu}")   : t_dim('N/A')
    o3   = air[:o3]   ? t_dim("#{air[:o3]} #{mu}")    : t_dim('N/A')
    lines = []
    lines << t_box_row(t_dim("Stacja: ") + t_white(air[:station].to_s.slice(0, @tw - 14)))
    lines << t_two_col("PM2.5  ", pm25,  "  PM10   ", pm10)
    lines << t_two_col("NO₂    ", no2,   "  O₃      ", o3)
    lines << t_two_col("AQI    ", air[:aqi] ? color.(air[:aqi].to_s) : t_dim('N/A'),
                       "  Status ", lbl ? color.(lbl[:label]) : t_dim('N/A'))
    lines.join("")
  end

end
