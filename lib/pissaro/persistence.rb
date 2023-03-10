require "sqlite3"
require "date"

require "pissaro/medium"

class Persistence
  DB_NAME = "pissaro.db"
  MEDIA_TABLE_NAME = "media"
  MEDIA_BASE_COLUMNS_NAMES = %W{file_name snapshot_id md5}
  SNAPSHOT_TABLE_NAME = "snapshots"

  attr_reader :db_name

  def initialize(db_name = DB_NAME)
    @db_name = db_name
  end

  def delete
    puts "Deleting database '#{db_name}'..."
    db.close
    File.delete(db_name)
    puts "Done."
  end

  def columns(table)
    db.execute("PRAGMA table_info(#{table})").map { |r| r[1] }
  end

  def record_count(table)
    db.execute("SELECT COUNT(*) FROM #{table}").first.first
  rescue SQLite3::SQLException => e
    return nil if e.message.start_with?("no such table")
    raise e
  end

  def media_count
    record_count(MEDIA_TABLE_NAME)
  end

  def snapshot_count
    record_count(SNAPSHOT_TABLE_NAME)
  end

  def set
    puts "Prepping database #{db_name}..."
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
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        #{MEDIA_BASE_COLUMNS_NAMES[0]} TEXT,
        #{MEDIA_BASE_COLUMNS_NAMES[1]} INTEGER NOT NULL,
        #{MEDIA_BASE_COLUMNS_NAMES[2]} TEXT,
        FOREIGN KEY(#{MEDIA_BASE_COLUMNS_NAMES[1]}) REFERENCES Snapshot(id)
      );
    """
    puts "Done."
  end

  def insert_media(media_data)
    data_columns = media_data_columns(media_data)
    raise "Data is missing base columns" if (MEDIA_BASE_COLUMNS_NAMES - data_columns).any?

    update_media_schema(media_data)

    columns = data_columns.join(',')
    values = ('?' * media_data.values.count).chars.join(',')
    query = "INSERT INTO #{MEDIA_TABLE_NAME} (#{columns}) VALUES (#{values})"
    db.execute(query, media_data.values.map(&:to_s))
  rescue Encoding::UndefinedConversionError
    puts "Encoding error inserting file #{media_data[:file_name]}"
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

  def get_or_create_snapshot
    records = db.execute("SELECT * FROM #{SNAPSHOT_TABLE_NAME} WHERE finished_at IS NULL")
    records.empty? ? create_snapshot : records.first[0]
  end

  def finish_snapshot(id)
    db.execute("UPDATE #{SNAPSHOT_TABLE_NAME} SET finished_at = ?", [DateTime.now.to_s])
  end

  def media_by_snapshot(snapshot_id)
    media_query("SELECT * FROM #{MEDIA_TABLE_NAME} WHERE snapshot_id = ?", snapshot_id)
  end

  def media_all
    media_query("SELECT * FROM #{MEDIA_TABLE_NAME}")
  end

  def get_snapshot(id)
    puts id
    result = db.execute("SELECT * FROM #{SNAPSHOT_TABLE_NAME} WHERE id = ?", id)
    return nil if result.empty?
    raise "More than one snapshot with id #{id}" unless result.one?

    record = result.first
    Snapshot.new(self, {id: record[0], created_at: record[1], finished_at: record[2]})
  end

  def query(query, args = [])
    db.execute(query, args)
  end

  def duplicates
    db.execute("""
        SELECT file_name, snapshot_id, md5 from #{MEDIA_TABLE_NAME} WHERE md5 in (
          SELECT md5 from #{MEDIA_TABLE_NAME} GROUP BY md5 HAVING count(*) > 1
        )
    """).map { |r| record_to_medium(r) }
  end

  private

  def media_query(query, *args)
    db
      .execute(query, args)
      .map { |r| record_to_medium(r, 1) }
  end

  def record_to_medium(record, i = 0)
    Medium.new(file_name: record[i], snapshot_id: record[i + 1], md5: record[i + 2])
  end

  def update_media_schema(media_data)
    media_columns_to_add(media_data).each do |column|
      query = "ALTER TABLE #{MEDIA_TABLE_NAME} ADD COLUMN #{column} TEXT"
      db.execute(query)
    end
  end

  def media_columns
    columns(MEDIA_TABLE_NAME)
  end

  def media_columns_to_add(media_data)
    media_data_columns(media_data) - media_columns
  end

  def media_data_columns(data)
    data.keys.map(&:to_s)
  end

  def db
    @db ||= SQLite3::Database.new db_name
  end
end
