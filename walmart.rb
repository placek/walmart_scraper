require "mechanize"

module Walmart

  class IDExtractor
    def initialize(url)
      @url = url
    end

    def extract
      @url.match(/http:\/\/www.walmart.com\/ip\/(?<id>\d+)/)[:id].to_i
    end
  end

  module Scraper

    class Page

      PAGE_LIMIT = 20

      def initialize(id, page_number)
        @id = id
        @page_number = page_number
        @mechanize = Mechanize.new
      end

      def fetch_comments
        fetch_page.search(".customer-review-body .customer-review-text").map(&:text).map(&:strip)
      end

      def fetch_dates
        fetch_page.search(".customer-review-body span.customer-review-date.hide-content").map(&:text)
      end

      def fetch_ratings
        fetch_page.search(".customer-review-body .customer-stars span.visuallyhidden").map(&:text)
      end

      def fetch_all
        feched_reviews.map do |review|
          {
            date: review[0],
            rating: review[1],
            comment: review[2]
          }
        end
      end

      private

      def feched_reviews
        fetch_dates.zip(fetch_ratings).zip(fetch_comments).map(&:flatten)
      end

      def fetch_page
        @page ||= @mechanize.get(reviews_url)
      end

      def reviews_url
        "https://www.walmart.com/reviews/product/%d?limit=%d&page=%d&sort=submission-asc" % [@id, PAGE_LIMIT, @page_number]
      end
    end

    class Product

      def initialize(id)
        @id = id
        @last_page = 1
      end

      def fetch
        @reviews = []
        fetch_all_pages
        {
          last_page: @last_page,
          reviews: @reviews
        }
      end

      def append(data)
        @reviews = data[:reviews][0..(data[:last_page] * Walmart::Scraper::Page::PAGE_LIMIT) + 1]
        fetch_all_pages(data[:last_page])
        {
          last_page: @last_page,
          reviews: @reviews
        }
      end

      private

      def fetch_all_pages(from_page = 1)
        current_page = from_page
        until((packet = fetch_page(current_page)).empty?) do
          @reviews << packet
          current_page +=1
        end
        @last_page = current_page - 1
        @reviews.flatten!
      end

      def fetch_page(current_page)
        Walmart::Scraper::Page.new(@id, current_page).fetch_all
      end
    end
  end
end

# TESTSIUTE

if __FILE__ == $0

  require "minitest/autorun"
  require "vcr"

  VCR.configure do |config|
    config.cassette_library_dir = "fixtures/vcr_cassettes"
    config.hook_into :webmock
  end

  class TestWalmartScraperPage < Minitest::Test
    def setup
      @scraper = Walmart::Scraper::Page.new 20925212, 2
    end

    def test_fetching_comments
      VCR.use_cassette("synopsis") do
        assert_equal 20, @scraper.fetch_comments.count
        assert_equal false, @scraper.fetch_comments.any?(&:nil?)
      end
    end

    def test_fetching_dates
      VCR.use_cassette("synopsis") do
        assert_equal 20, @scraper.fetch_dates.count
        assert_equal false, @scraper.fetch_dates.any?(&:nil?)
      end
    end

    def test_fetching_ratings
      VCR.use_cassette("synopsis") do
        assert_equal 20, @scraper.fetch_ratings.count
        assert_equal false, @scraper.fetch_ratings.any?(&:nil?)
      end
    end

    def test_fetching_all_reviews
      VCR.use_cassette("synopsis") do
        assert_equal 20, @scraper.fetch_all.count
      end
    end
  end

  class TestWalmartScraperProduct < Minitest::Test
    def setup
      @scraper = Walmart::Scraper::Product.new 20925212
    end

    def test_fetching_reviews
      VCR.use_cassette("synopsis") do
        assert_equal 66, @scraper.fetch[:reviews].count
        assert_equal 4, @scraper.fetch[:last_page]
      end
    end

    def test_fetching_reviews_from_specified_page
      VCR.use_cassette("synopsis") do
        assert_equal 46, @scraper.fetch(2)[:reviews].count
        assert_equal 4, @scraper.fetch(2)[:last_page]
      end
    end
  end

  class TestWalmartIDExtractor < Minitest::Test
    def setup
      @id_extractor = Walmart::IDExtractor.new "http://www.walmart.com/ip/20925212?findingMethod=wpa&cmp=-1&pt=hp&adgrp=-1&plmt=1145x345_B-C-OG_TI_8-20_HL_MID_HP&bkt=&pgid=0&adUid=413332f8-f444-4878-8b00-3d13fa38aff2&adpgm=hl"
    end

    def test_that_it_get_proper_id
      assert_equal 20925212, @id_extractor.extract
    end
  end
end
