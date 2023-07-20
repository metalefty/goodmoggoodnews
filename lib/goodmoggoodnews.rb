# frozen_string_literal: true

require_relative "goodmoggoodnews/version"
require_relative "goodmoggoodnews/runner"
require_relative "goodmoggoodnews/line_runner"

require "twitter"
require "faraday"
require "faraday_middleware"
require "nokogiri"
require "redis"
require "line-bot-api"
require "active_support"
require "active_support/core_ext"
require "active_support/time"

class Goodmoggoodnews
  BLOG_URL_PREFIX = "https://fan.pia.jp/the-pillows/news/detail/"
  PHOTOS_URL_PREFIX = "https://fan.pia.jp/the-pillows/photo/detail/"
  TICKET_URL_PREFIX = "https://fan.pia.jp/the-pillows/ticket/detail/"
  USER_AGENT = "GoodMogGoodNews/#{Goodmoggoodnews::VERSION}; https://twitter.com/GoodMogGoodNews"
  # USER_AGENT = "DanceWithBot/#{Goodmoggoodnews::VERSION}; https://twitter.com/DanceWithBot"
  class Error < StandardError; end

  # Redis 関連の操作
  class Redis
    def initialize
      @client = ::Redis.new(url: ENV['REDIS_URL'] || "redis://localhost")
    end

    def last_news_id
      @client.get(:n).to_i
    end

    def last_news_id=(id)
      @client.set(:n, id)
    end

    def last_photo_id
      @client.get(:p).to_i
    end

    def last_photo_id=(id)
      @client.set(:p, id)
    end

    def last_ticket_id
      @client.get(:t).to_i
    end

    def last_ticket_id=(id)
      @client.set(:t, id)
    end
  end

  # Line関連の操作
  class Line
    attr_reader :client

    def initialize
      @client = ::Line::Bot::Client.new{|config|
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
      }
    end
  end

  # Twitter関連の操作
  class Twitter
    attr_reader :client, :location

    def initialize
      @client = ::Twitter::REST::Client.new(
        consumer_key: ENV["CONSUMER_KEY"],
        consumer_secret: ENV["CONSUMER_SECRET"],
        access_token: ENV["ACCESS_TOKEN"],
        access_token_secret: ENV["ACCESS_TOKEN_SECRET"]
      )

      # TwitterプロフィールのLocationを最新記事の番号の保存場所として使う
      @location = {}
      begin
        json = @client&.user&.location
        @location = JSON.parse(json, symbolize_names: true)
      rescue JSON::ParserError
        @location = { n: 0, p: 0, t: 0 }
      end
    end

    def last_news_id
      @location[:n] || 0
    end

    def last_news_id=(id)
      @location.merge!(n: id)
      @client.update_profile(location: @location.to_json)
    end

    def last_photo_id
      @location[:p] || 0
    end

    def last_photo_id=(id)
      @location.merge!(p: id)
      @client.update_profile(location: @location.to_json)
    end

    def last_ticket_id
      @location[:t] || 0
    end

    def last_ticket_id=(id)
      @location.merge!(t: id)
      @client.update_profile(location: @location.to_json)
    end
  end

  # HTML解析モジュール
  module Scraper
    def self.scrape(string)
      html = Nokogiri::HTML.parse(string)

      title = html.xpath('/html/head/meta[@property="og:title"]/@content').text
      title = "タイトル取得失敗" if title.blank?
      date = html.css("article.newsArticle").css("p.date").text
      date = "日付取得失敗" if date.blank?

      "#{date} #{title}"
    end

    def self.scrape_photo_page(string)
      html = Nokogiri::HTML.parse(string)

      title = html.xpath('/html/head/meta[@property="og:title"]/@content').text
      title = "タイトル取得失敗" if title.blank?

      "【PHOTO】#{title}"
    end

    def self.scrape_ticket_page(string)
      html = Nokogiri::HTML.parse(string)

      title = html.xpath('/html/head/meta[@property="og:title"]/@content').text
      title = "タイトル取得失敗" if title.blank?

      "【チケット情報】#{title}"
    end
  end

  # 最新記事をチェックするためのモジュール
  module Crawler
    def self.crawl(id: 0, type: nil)
      prefix = ""

      case type
      when :news
        prefix = BLOG_URL_PREFIX
      when :photo
        prefix = PHOTOS_URL_PREFIX
      when :ticket
        prefix = TICKET_URL_PREFIX
      else
        raise ArgumentError
      end

      retval = []

      (id + 1..).each do |i|
        u = URI.parse(prefix.to_s)

        conn = Faraday::Connection.new(u,
                                       headers:
                                       {
                                         "User-Agent": USER_AGENT
                                       }) do |builder|
          builder.use Faraday::Response::Logger
          # メンテナンス中はリダイレクトがかかっているので追わない
          # builder.use FaradayMiddleware::FollowRedirects
        end

        response = conn.head do |request|
          request.url "#{i}/"
        end

        Goodmoggoodnews.sleep_random

        break unless response.success?

        retval << { id: i, response: response }
      end

      retval
    end

    # 指定されたURIの記事を取得
    def self.get(uri)
      conn = Faraday::Connection.new(URI(uri),
                                     headers:
                                     {
                                       "User-Agent": USER_AGENT
                                     }) do |builder|
        builder.use Faraday::Response::Logger
        # メンテナンス中はリダイレクトがかかっているので追わない
        # builder.use FaradayMiddleware::FollowRedirects
      end

      response = conn.get

      response
    end

    # 指定されたURIの記事を取得(HEAD)
    def self.head(uri)
      conn = Faraday::Connection.new(URI(uri),
                                     headers:
                                     {
                                       "User-Agent": USER_AGENT
                                     }) do |builder|
        builder.use Faraday::Response::Logger
        # メンテナンス中はリダイレクトがかかっているので追わない
        # builder.use FaradayMiddleware::FollowRedirects
      end

      response = conn.head

      response
    end
  end

  def self.sleep_random(wait = 2)
    sleep SecureRandom.random_number(wait)
  end
end
