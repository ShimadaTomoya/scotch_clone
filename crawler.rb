# coding: utf-8

=begin
@author Shimada Tomoya
=end

require "addressable/uri"
require 'nokogiri'
require 'open-uri'
require 'uri'
require 'logger'
require './crawl_urls'
require './doc_handler'

class Crawler
  DEFAULT_URI_OPTIONS = {
    'User-Agent' => 'Mozilla/5.0 (compatible; Shimada-Crawler)',
  }
  attr_reader :interval, :max_hop

  def initialize(max_hop: , interval: , dbfile: ,uri_options: DEFAULT_URI_OPTIONS, logger:)
    @max_hop = max_hop
    @interval = interval
    @uri_options = uri_options
    @logger = logger
    @table = CrawlUrls.new(dbfile)
  end


  def crawl(seeds)
    seeds.each do |url|
      @table.add(url, @max_hop)
    end

    row = @table.get_new_url
    while(row)
      sleep(@interval)
      url, depth = row
      @logger.info("url=#{url}, depth=#{depth}")
      doc = doc(url)
      unless (doc)
        row = @table.get_new_url
        next
      end
      doc_handler = DocHandler.new(url, doc)
      if (depth > 0)
        links = links(url, doc).flatten.uniq.compact.select { |_url| doc_handler.filter(_url) }
        links.each do |u|
          @table.add(u, depth-1)
        end
        doc_handler.handle
        @table.update_status(url, CrawlUrls::COMPLETED)
      end
      row = @table.get_new_url
    end
  end

  def doc(url)
    begin
      doc = Nokogiri::HTML(URI.open(url, @uri_options))
    rescue OpenURI::HTTPError => e
      @logger.warn("次のURLでHTTPエラーが発生しました: #{url}")
      @logger.warn(e.inspect)
      return nil
    rescue => e
      @logger.warn("次のURLで不明なエラーが発生しました: #{url}")
      @logger.warn(e.inspect)
      return nil
    end
    return doc
  end

  def links(url, doc)
    return [] unless (doc)

    doc.css('a').map do |a|
      next unless a[:href]
      href = a[:href].to_s.strip
      Addressable::URI.join(url, href).to_s.strip
    end
  end
end
