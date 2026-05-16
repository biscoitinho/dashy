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
| Space weather | N0NBH / hamqsl.com (same as solar.w5mmw.net) | 10 min |
| HF band conditions | N0NBH XML | 10 min |
| Air quality | WAQI — geo near Rumia/Trójmiasto | 1 hour |
| Ruby Weekly | rubyweekly.com RSS + /issues scrape | 10 min |
| Ruby tip of the day | Built-in pool of 71 tips, rotates daily | static |
| HF band plan | IARU Region 1 + CB, hardcoded | static |
| Calendar | System `cal` command | per request |

## Environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `WAQI_TOKEN` | Yes | WAQI API token from aqicn.org |
| `PORT` | No | HTTP port (default: 4567) |

## Project structure

```
dashy/
├── app.rb                  # Sinatra app, routing, cache, .env loader
├── Gemfile
├── .env.example            # Environment variable template
├── .gitignore
├── lib/
│   ├── fetchers.rb         # HTTP fetchers — WAQI, hamqsl, Ruby Weekly
│   ├── band_plan.rb        # Static IARU R1 + CB band plan data
│   ├── ruby_tips.rb        # 71 rotating Ruby tips
│   └── terminal_helpers.rb # ANSI colors, box drawing, Sinatra helpers
└── views/
    ├── layout.erb          # HTML shell and CSS
    ├── index.erb           # Browser view
    └── index_text.erb      # curl / plain text view
```

## Adding a new section

1. Add a fetcher in `lib/fetchers.rb`
2. Add it to `dashboard_data` in `app.rb`
3. Add a render block in `lib/terminal_helpers.rb`
4. Call it in `views/index_text.erb` and `views/index.erb`
