# coding: utf-8

class DocHandler
  def initialize(url, doc)
    @url = url
    @doc = doc
  end

  def filter(url)
    return false unless url.match?(/^https:\/\/calorie.slism.jp/)
    true
  end

  def handle #output
    row = ""
    row += itemid
    row += "\t"
    row += title
    row += "\t"
    row += url
    row += "\t"
    row += desc
    puts row
  end

  private

  def itemid
    @url
  end

  def title
    @doc.css('title').text.strip
  end

  def url
    @url
  end

  def desc
    @doc.css('meta[@name="description"]>@content').to_s.gsub(/(\n|\r\n|\t)/, '')
  end
end
