# coding: utf-8

require 'sqlite3'
require 'digest'

class CrawlUrls
  TABLE_NAME = 'crawl_urls'

  NEW = 0         # 未処理
  PROCESSING = 1  # 処理中
  COMPLETED = 2   # 処理完了
  ERROR = 3       # エラー終了

  def initialize(dbfile) 
    @db = SQLite3::Database.new(dbfile)
  end

  def create_table
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS #{TABLE_NAME} (
        `url_hash` TEXT PRIMARY KEY  NOT NULL,
        `url` TEXT NOT NULL,
        `depth` INTEGER NOT NULL,
        `status` INTEGER NOT NULL DEFAULT 0,
        `created_at` NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    SQL
  end

  def drop_table
    sql = "DROP TABLE IF EXISTS #{TABLE_NAME}"
    result = @db.execute(sql)
  end

  def get_new_url
    @db.transaction
    sql = "SELECT url, depth FROM #{TABLE_NAME} WHERE status = 0 LIMIT 1;"
    result = @db.execute(sql)
    if (result != [])
      row = result[0]
      url, _ = row
      update_status(url, PROCESSING)
      @db.commit
    else
      @db.commit
      return nil
    end
    row
  end

  def add(url, depth)
    sql = "INSERT OR IGNORE INTO #{TABLE_NAME} (url_hash, url, depth) VALUES (?, ?, ?);"
    @db.execute(sql,[Digest::SHA512.hexdigest(url), url, depth])
  end

  def update_status(url, status)
    sql = "UPDATE #{TABLE_NAME} SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE url_hash = ?;"
    @db.execute(sql,[status, Digest::SHA512.hexdigest(url)])
  end
end
