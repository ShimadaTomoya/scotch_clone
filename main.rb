# coding: utf-8

require './crawler'
require './crawl_urls'

dbfile = "./test.db"
db = CrawlUrls.new(dbfile)
db.drop_table unless (ARGV[0] == '--continue')
db.create_table

# crawlerインスタンスの作成
# max_hop: ホップ数, interval: アクセス間隔(sec), logger: Loggerオブジェクト
log_file = "./#{Time.now.strftime("%Y%m%d%H%M%S")}.log"
logger = Logger.new(log_file)
crawler = Crawler.new(max_hop: 3, interval: 0.5, dbfile: dbfile,  logger: logger)

# クロール実行
crawler.crawl(['https://calorie.slism.jp/'])
