require "sqlite3"

class Persistence
  DB_NAME = "test.db"
  MEDIA_TABLE_NAME = "photos"

  def delete
    db.close
    File.delete(DB_NAME)
  end

  def media_columns
    db.execute("PRAGMA table_info(#{MEDIA_TABLE_NAME})").map { |r| r[1] }
  end

  def record_count
    db.execute("SELECT COUNT(*) FROM #{MEDIA_TABLE_NAME}")
  end

  private

  def db
    SQLite3::Database.new DB_NAME
  end
end
