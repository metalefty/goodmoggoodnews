# frozen_string_literal: true

require_relative "goodmoggoodnews/version"

require 'twitter'
require 'faraday'
require 'faraday_middleware'
require 'nokogiri'
require 'active_support'

class Goodmoggoodnews
  BLOG_URL_PREFIX = 'https://fan.pia.jp/the-pillows/news/detail/'
  USER_AGENT = "GoodMorningGoodNews/#{Goodmoggoodnews::VERSION}; https://twitter.com/GoodMogGoodNews"
  class Error < StandardError; end

  # Twitter関連の操作
  class Twitter
    attr_reader :client

    def initialize(prefix: BLOG_URL_PREFIX)
      @client = ::Twitter::REST::Client.new(
        consumer_key:         ENV['CONSUMER_KEY'],
        consumer_secret:      ENV['CONSUMER_SECRET'],
        access_token:         ENV['ACCESS_TOKEN'],
        access_token_secret:  ENV['ACCESS_TOKEN_SECRET'],
      )
    end

    def last_article_id
      # TwitterプロフィールのLocationを最新記事の番号の保存場所として使う
      @client&.user&.location&.to_i
    end

    def last_article_id=(id)
      @client.update_profile(location: id)
    end
  end

  # HTML解析モジュール
  module Scraper
    def self.scrape(string)
      html = Nokogiri::HTML.parse(string)

      title = html.xpath('/html/head/meta[@property="og:title"]/@content').text
      title = "タイトル取得失敗" if title.blank?
      date = html.css('article.newsArticle').css('p.date').text
      date = "日付取得失敗" if date.blank?

      "#{date} #{title}"
    end

  end

  # 最新記事をチェックするためのモジュール
  module Crawler
    # 最新記事をチェック
    def self.crawl(id: 0)
      retval = []

      (id+1..).each do |i|
        u = URI.parse("#{BLOG_URL_PREFIX}")

        conn = Faraday::Connection.new(u,
          headers:
          {
            "User-Agent": USER_AGENT
          }) do |builder|
          builder.use Faraday::Response::Logger
          builder.use FaradayMiddleware::FollowRedirects
        end

        response = conn.head do |request|
          request.url "#{i}/"
        end

        Goodmoggoodnews.sleep_random

        break unless response.success?
        retval << { id: i, response: response}
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
        builder.use FaradayMiddleware::FollowRedirects
      end

      response = conn.get
    end
  end

  private

  def self.sleep_random(i = 10)
    sleep SecureRandom.random_number(i)
  end
end
