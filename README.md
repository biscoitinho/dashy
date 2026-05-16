# dashy

Terminal-style dashboard — Ruby Weekly + Space Weather (HF propagation) + clock + cal.

## Wymagania

- Ruby 2.7+
- Bundler

## Start

```bash
bundle install
ruby app.rb
```

Domyślnie port **4567**. Zmień przez zmienną środowiskową:

```bash
PORT=8080 ruby app.rb
```

### Uruchamianie jako tło (na Mac Mini)

```bash
# nohup
nohup ruby app.rb > dashy.log 2>&1 &

# albo launchd (macOS) — dodaj plist do ~/Library/LaunchAgents/
```

## Użycie

```bash
# przeglądarka
open http://localhost:4567

# curl — plain text z ASCII box drawing
curl http://localhost:4567

# albo wprost:
curl 'http://localhost:4567/?format=text'

# raw JSON
curl http://localhost:4567/data.json | jq

# wymuś odświeżenie cache
curl http://localhost:4567/refresh
```

## Dane

| Źródło       | Endpoint                                          | Odświeżanie |
|--------------|---------------------------------------------------|-------------|
| Ruby Weekly  | `https://rubyweekly.com/rss`                      | 10 min      |
| Solar flux   | NOAA SWPC `/products/summary/10cm-flux.json`      | 10 min      |
| Kp index     | NOAA SWPC `/products/noaa-planetary-k-index.json` | 10 min      |
| Geomag       | NOAA SWPC `/products/summary/geomag-field.json`   | 10 min      |
| Solar wind   | NOAA SWPC `/products/summary/solar-wind-speed.json`| 10 min     |

## Struktura

```
dashboard/
├── Gemfile
├── app.rb              # Sinatra, routing, cache
├── lib/
│   └── fetchers.rb     # RSS + NOAA parsers
└── views/
    ├── layout.erb      # HTML shell, terminal CSS
    ├── index.erb       # główny widok HTML
    └── index_text.erb  # curl / plain text output
```

## Dodawanie nowych sekcji

1. Dopisz fetcher w `lib/fetchers.rb`
2. Dodaj do `dashboard_data` w `app.rb`
3. Dopisz panel w `views/index.erb` i blok w `views/index_text.erb`
