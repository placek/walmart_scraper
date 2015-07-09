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

  class Scraper

    def initialize(id, page_number)
      @id = id
      @page_number = page_number
      @mechanize = Mechanize.new
    end

    def get_comments
      get_page.search(".customer-review-body .customer-review-text").map(&:text).map(&:strip)
    end

    def get_dates
      get_page.search(".customer-review-body span.customer-review-date.hide-content").map(&:text)
    end

    def get_ratings
      get_page.search(".customer-review-body .customer-stars span.visuallyhidden").map(&:text)
    end

    def get_all
      get_dates.zip(get_ratings).zip(get_comments).map(&:flatten)
    end

    private

    def get_page
      @page ||= @mechanize.get(reviews_url)
    end

    def reviews_url(limit = 20)
      "https://www.walmart.com/reviews/product/%d?limit=%d&page=%d&sort=submission-asc" % [@id, limit, @page_number]
    end
  end
end

# testsiute
require "minitest/autorun"
require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock
end

class TestWalmartScraper < Minitest::Test
  def setup
    @scraper = Walmart::Scraper.new 20925212, 2
  end

  def test_getting_comments
    VCR.use_cassette("synopsis") do
      assert_equal 20, @scraper.get_comments.count
      assert_equal false, @scraper.get_comments.any?(&:nil?)
    end
  end

  def test_getting_dates
    VCR.use_cassette("synopsis") do
      assert_equal 20, @scraper.get_dates.count
      assert_equal false, @scraper.get_dates.any?(&:nil?)
    end
  end

  def test_getting_ratings
    VCR.use_cassette("synopsis") do
      assert_equal 20, @scraper.get_ratings.count
      assert_equal false, @scraper.get_ratings.any?(&:nil?)
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
