require 'rexml/document'

module Fetchers
  module RubyNews
    RUBY_WEEKLY_RSS    = 'https://rubyweekly.com/rss'.freeze
    RUBY_WEEKLY_ISSUES = 'https://rubyweekly.com/issues'.freeze

    def self.fetch_items(limit: 10)
      items = from_rss(limit)
      items += from_issues(limit - items.size, skip: items.map { |i| i[:link] }) if items.size < limit
      items
    rescue => e
      warn "ruby_news error: #{e.class}: #{e.message}"
      []
    end

    def self.from_rss(limit)
      body = Fetchers::Base.fetch(RUBY_WEEKLY_RSS)
      return [] unless body

      doc   = REXML::Document.new(body)
      items = []
      doc.elements.each('rss/channel/item') do |item|
        title = item.elements['title']&.text&.strip
        link  = item.elements['link']&.text&.strip
        pub   = item.elements['pubDate']&.text&.strip
        items << { title: title, link: link, date: pub, snippet: nil }
        break if items.size >= limit
      end
      items
    rescue => e
      warn "rss error: #{e.class}: #{e.message}"
      []
    end

    def self.from_issues(limit, skip: [])
      body = Fetchers::Base.fetch(RUBY_WEEKLY_ISSUES)
      return [] unless body

      items = []
      body.scan(%r{href="(/issues/(\d+))"[^>]*>([^<]+)<}i) do |path, num, title|
        clean = title.strip.gsub(/\s+/, ' ')
        next if clean.length < 10 || clean =~ /\A[\d\s#]+\z/

        link = "https://rubyweekly.com#{path}"
        next if skip.include?(link)

        items << { title: clean, link: link, date: "##{num}", snippet: nil }
        break if items.size >= limit
      end
      items
    rescue => e
      warn "issues scrape error: #{e.class}: #{e.message}"
      []
    end
  end
end
