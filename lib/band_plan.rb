module BandPlan
  # IARU Region 1 + CB — uproszczony cheatsheet dla SP2MAG
  BANDS = [
    { name: '160m', range: '1.810–2.000',  modes: 'CW/SSB',     calling: '1.840 SSB  1.836 CW', notes: 'night DX' },
    { name: '80m',  range: '3.500–3.800',  modes: 'CW/SSB',     calling: '3.760 SSB  3.500 CW', notes: 'evening EU' },
    { name: '40m',  range: '7.000–7.200',  modes: 'CW/SSB',     calling: '7.090 SSB  7.000 CW', notes: 'DX night' },
    { name: '30m',  range: '10.100–10.150', modes: 'CW/DIGI',    calling: '10.106 WSPR',          notes: 'no SSB!' },
    { name: '20m',  range: '14.000–14.350', modes: 'CW/SSB',     calling: '14.225 SSB 14.000 CW', notes: 'main DX' },
    { name: '17m',  range: '18.068–18.168', modes: 'CW/SSB',     calling: '18.130 SSB',           notes: 'WARC' },
    { name: '15m',  range: '21.000–21.450', modes: 'CW/SSB',     calling: '21.285 SSB 21.000 CW',
notes: 'solar dependent' },
    { name: '12m',  range: '24.890–24.990', modes: 'CW/SSB',     calling: '24.950 SSB',           notes: 'WARC' },
    { name: '10m',  range: '28.000–29.700', modes: 'CW/SSB/FM',  calling: '28.500 SSB 29.600 FM', notes: 'Sporadic-E' },
    { name: '6m',   range: '50.000–52.000', modes: 'SSB/FM/CW',  calling: '50.150 SSB 51.510 FM', notes: 'Magic Band' },
    { name: '2m',   range: '144.000–146.000', modes: 'FM/SSB',   calling: '144.300 SSB 145.500 FM', notes: 'local' },
    { name: '70cm', range: '430.000–440.000', modes: 'FM/SSB',   calling: '432.200 SSB 433.500 FM', notes: 'local' },
    { name: 'CB',   range: '26.965–27.405', modes: 'AM/FM/SSB', calling: '27.555 SSB  ch19 27.185',
notes: '11m, 40 ch' }
  ].freeze

  def self.all
    BANDS
  end

  def self.hf
    BANDS.select { |b| b[:name].match?(/\d+m$/) && b[:name].to_i >= 10 && b[:name] != 'CB' }
  end
end
