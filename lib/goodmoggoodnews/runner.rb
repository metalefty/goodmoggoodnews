# frozen_string_literal: true

class Goodmoggoodnews
  class Runner
    # ぴあがメンテナンス中かどうか確認するためのURI
    MONITOR_URI = URI("https://fan.pia.jp/the-pillows/")
    # MONITOR_URI = URI("https://ssl.vmeta.jp/dummy/")
    # MONITOR_URI = URI("https://ssl.vmeta.jp/")

    LOG_TAG = "GoodMogGoodNews"

    def self.go
      logger = Logger.new(STDOUT)
      twitter = Goodmoggoodnews::Twitter.new

      logger.info(LOG_TAG) { "もぐもぐアラート起動！" }

      # ぴあのメンテナンス: 毎週火曜・水曜日の午前2時30分～午前5時30分
      # メンテナンス中の場合は何もせず終了する
      response = Goodmoggoodnews::Crawler.head(MONITOR_URI)
      unless response.success?
        msg = "更新検出失敗: ぴあがメンテナンス中かも"
        logger.error(LOG_TAG) { msg }
        exit false
      end

      # どこまで読んだ
      last_news_id = twitter.last_news_id
      last_photo_id = twitter.last_photo_id
      last_ticket_id = twitter.last_ticket_id

      ################
      #     BLOG     #
      ################

      # BLOG: 新着記事を調べる
      logger.info(LOG_TAG) { "NEWSの新着記事を調べています。" }
      found_news = Goodmoggoodnews::Crawler.crawl(id: last_news_id, type: :news)
      new_news = found_news.map { |e| e[:response] }
      new_news_ids = found_news.map { |e| e[:id] }

      if found_news.empty?
        msg = "新着記事(NEWS)はありませんでした。"
        logger.info(LOG_TAG) { msg }
      else
        msg = "#{found_news.count}件の新着NEWSを発見しました。"
        logger.info(LOG_TAG) { msg }
        # 記事番号を更新
        if last_news_id < new_news_ids.max
          logger.info(LOG_TAG) { "Updating bookmark: last_news_id=#{last_news_id}, new_news_id=#{new_news_ids.max}" }
          twitter.last_news_id = new_news_ids.max
        end

        # 新着記事をツイート
        new_news.each do |e|
          response = Goodmoggoodnews::Crawler.get(e.env.url)
          tweet_body = Goodmoggoodnews::Scraper.scrape(response.body) + "\n" + e.env.url.to_s
          twitter.client.update tweet_body
          logger.info("Tweet") { tweet_body }
          Goodmoggoodnews.sleep_random(10)
        end
      end

      ################
      #    PHOTO     #
      ################

      # PHOTO: 新着記事を調べる
      logger.info(LOG_TAG) { "PHOTOの新着記事を調べています。" }
      found_photos = Goodmoggoodnews::Crawler.crawl(id: last_photo_id, type: :photo)

      new_photos = found_photos.map { |e| e[:response] }
      new_photo_ids = found_photos.map { |e| e[:id] }

      if found_photos.empty?
        msg = "新着記事(PHOTO)はありませんでした。"
        logger.info(LOG_TAG) { msg }
      else
        msg = "#{found_photos.count}件の新着PHOTOを発見しました。"
        logger.info(LOG_TAG) { msg }
        # 記事番号を更新
        if last_photo_id < new_photo_ids.max
          logger.info(LOG_TAG) { "Updating bookmark: last_photo_id=#{last_photo_id}, new_photo_id=#{new_photo_ids.max}" }
          twitter.last_photo_id = new_photo_ids.max
        end

        # 新着記事をツイート
        new_photos.each do |e|
          response = Goodmoggoodnews::Crawler.get(e.env.url)
          tweet_body = Goodmoggoodnews::Scraper.scrape_photo_page(response.body) + "\n" + e.env.url.to_s
          twitter.client.update tweet_body
          logger.info("Tweet") { tweet_body }
          Goodmoggoodnews.sleep_random(10)
        end
      end

      ################
      #    TICKET    #
      ################

      # TICKET: 新着記事を調べる
      logger.info(LOG_TAG) { "TICKETの新着記事を調べています。" }
      found_tickets = Goodmoggoodnews::Crawler.crawl(id: last_ticket_id, type: :ticket)

      new_tickets = found_tickets.map{ |e| e[:response] }
      new_ticket_ids = found_tickets.map{ |e| e[:id] }

      if found_tickets.empty?
        msg = "新着記事(TICKET)はありませんでした。"
        logger.info(LOG_TAG) { msg }
      else
        msg = "#{found_tickets.count}件のチケット情報を発見しました。"
        logger.info(LOG_TAG) { msg }
        # 記事番号を更新
        if last_ticket_id < new_ticket_ids.max
          logger.info(LOG_TAG) { "Updating bookmark: last_ticket_id=#{last_ticket_id}, new_ticket_id=#{new_ticket_ids.max}" }
          twitter.last_ticket_id = new_ticket_ids.max
        end

        # 新着記事をツイート
        new_tickets.each do |e|
          response = Goodmoggoodnews::Crawler.get(e.env.url)
          tweet_body = Goodmoggoodnews::Scraper.scrape_ticket_page(response.body) + "\n" + e.env.url.to_s
          twitter.client.update tweet_body
          logger.info("Tweet") { tweet_body }
          Goodmoggoodnews.sleep_random(10)
        end
      end

      logger.info(LOG_TAG) { "もぐもぐアラート終了！" }
    end
  end
end
