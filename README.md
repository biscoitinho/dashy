# dashy

Terminal-style personal dashboard — ham radio space weather, air quality, HF band plan, Ruby tips and Ruby Weekly news. Available both in the browser and via `curl`.

## Requirements

- Ruby 3.0+
- Bundler
- WAQI API token (free) — https://aqicn.org/data-platform/token/

## Setup

```bash
git clone https://github.com/biscoitinho/dashy.git
cd dashy
bundle install
cp .env.example .env
# Edit .env and add your WAQI_TOKEN
```

## Configuration

Copy `.env.example` to `.env` and fill in your token:

```
WAQI_TOKEN=your_token_here
```

Ruby loads `.env` automatically on startup — no need to `source` anything.

## Tests

```bash
bundle exec ruby -Itest test/test_logic.rb
bundle exec ruby -Itest test/test_cache.rb
```

## Running

```bash
ruby app.rb
```

Override the port if needed:

```bash
PORT=8080 ruby app.rb
```

### Background (macOS)

```bash
nohup ruby app.rb > dashy.log 2>&1 &
```

## Usage

```bash
# Browser
open http://localhost:4567

# Terminal — with ANSI colors
curl http://localhost:4567

# Plain text (no colors — good for pipes and logs)
curl 'http://localhost:4567/?plain=1'

# Match your terminal width
curl "http://localhost:4567/?width=$(tput cols)"

# Handy alias — add to ~/.zshrc
alias dashy='curl "http://localhost:4567/?width=$(tput cols)"'

# Force cache refresh
curl http://localhost:4567/refresh

# Raw JSON
curl http://localhost:4567/data.json | jq

# Diagnostics
curl http://localhost:4567/debug/air
curl http://localhost:4567/debug/noaa
```

## Tests

```bash
bundle exec ruby -Itest test/test_logic.rb
bundle exec ruby -Itest test/test_cache.rb
```

## Data sources

| Section | Source | Cache |
|---------|--------|-------|
| Space weather | N0NBH / hamqsl.com | 10 min |
| Kp forecast (3-day) | NOAA services.swpc.noaa.gov | 1 hour |
| Air quality | WAQI — geo near Rumia/Trójmiasto | 1 hour |
| ISS pass prediction | Celestrak TLE + local orbital calc | 1 hour |
| DX Cluster | dxsummit.fi — EU spots | 5 min |
| SOTA / POTA | api2.sota.org.uk + api.pota.app | 5 min |
| Ruby Weekly | rubyweekly.com RSS + /issues scrape | 10 min |
| Ruby tip of the day | Built-in pool of 71 tips, rotates daily | static |
| HF band plan | IARU Region 1 + CB, hardcoded | static |
| Sunrise / sunset | NOAA astronomical algorithm (no API) | per request |
| Calendar | System `cal` command | per request |

## Environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `WAQI_TOKEN` | Yes | WAQI API token from aqicn.org |
| `PORT` | No | HTTP port (default: 4567) |

## Project structure

```
dashy/
├── app.rb                        # Sinatra app, routing, thread-safe cache, .env loader
├── Gemfile
├── .env.example                  # Environment variable template
├── .rubocop.yml
├── lib/
│   ├── fetchers.rb               # Thin facade — delegates to sub-modules
│   ├── fetchers/
│   │   ├── base.rb               # HTTP client (fetch, fetch_json)
│   │   ├── space_weather.rb      # HAMQSL / N0NBH solar data
│   │   ├── air_quality.rb        # WAQI air quality
│   │   ├── ruby_news.rb          # Ruby Weekly RSS + scraper
│   │   ├── sun_times.rb          # Sunrise/sunset (pure astronomy, no API)
│   │   ├── dx_cluster.rb         # DX Cluster spots — dxsummit.fi
│   │   ├── kp_forecast.rb        # NOAA Kp 3-day forecast
│   │   ├── sota_pota.rb          # SOTA + POTA active stations
│   │   └── iss_tracker.rb        # ISS pass prediction (Celestrak TLE + orbital calc)
│   ├── band_plan.rb              # Static IARU R1 + CB band plan
│   ├── ruby_tips.rb              # 71 rotating Ruby tips
│   └── terminal_helpers.rb       # ANSI colors, box drawing, section renderers
├── views/
│   ├── layout.erb                # HTML shell, CSS, JS clock
│   ├── index.erb                 # Browser view
│   └── index_text.erb            # curl / plain-text view
└── test/
    ├── test_logic.rb             # Unit tests — fetcher logic, boundary values
    └── test_cache.rb             # Unit tests — cache hit/miss/TTL
```

## Adding a new section

1. Create `lib/fetchers/my_source.rb` with a module `Fetchers::MySource`
2. Add `require_relative` and a facade method to `lib/fetchers.rb`
3. Add to `dashboard_data` in `app.rb` (with `cached()`)
4. Add a `t_my_block` helper to `lib/terminal_helpers.rb`
5. Render in `views/index.erb` and `views/index_text.erb`
