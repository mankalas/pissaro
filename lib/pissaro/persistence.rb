require "sqlite3"
require "date"

class Persistence
  DB_NAME = "pissaro.db"
  MEDIA_TABLE_NAME = "media"
  SNAPSHOT_TABLE_NAME = "snapshots"

  def delete
    puts "Deleting database '#{DB_NAME}..."
    db.close
    File.delete(DB_NAME)
    puts "Done."
  end

  def media_columns
    db.execute("PRAGMA table_info(#{MEDIA_TABLE_NAME})").map { |r| r[1] }
  end

  def record_count
    db.execute("SELECT COUNT(*) FROM #{MEDIA_TABLE_NAME}")
  end

  def set
    puts "Prepping database #{DB_NAME}..."
    puts "|- Creating table #{SNAPSHOT_TABLE_NAME}"
    db.execute """
      CREATE TABLE #{SNAPSHOT_TABLE_NAME} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        finished_at TEXT
      );
    """

    puts "|- Creating table #{MEDIA_TABLE_NAME}"
    db.execute """
      CREATE TABLE #{MEDIA_TABLE_NAME} (
        file_name TEXT PRIMARY KEY,
        snapshot_id INTEGER NOT NULL,
        md5 TEXT,
        FOREIGN KEY(snapshot_id) REFERENCES Snapshot(id)
      );
    """
    puts "Done."
  end

  def insert(media_data)
    columns = media_data.keys.join(',')
    values = ('?' * (h.values.count - 1)).join(',')
    db.execute("INSERT INTO photos (#{columns}) VALUES (#{values})")
  end

  def upsert_md5(file_name, md5, id)
    db.execute("""
      INSERT INTO #{MEDIA_TABLE_NAME}(file_name, md5, snapshot_id)
        VALUES(?, ?, ?)
        ON CONFLICT(file_name) DO
           UPDATE SET md5 = ?
    """, [file_name, md5, id, md5])
  end

  def create_snapshot
    db.execute("INSERT INTO #{SNAPSHOT_TABLE_NAME}(created_at) VALUES (?)", [DateTime.now.to_s])
    db.last_insert_row_id
  end

  private

  def db
    SQLite3::Database.new DB_NAME
  end
end
