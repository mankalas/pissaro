require 'exif'
require 'sqlite3'
require 'pp'

def flat_hash(h, f=nil, g={})
  return g.update({ f => h }) unless h.is_a? Hash
  h.each { |k, r| flat_hash(r, [f,k].compact.join('_'), g) }
  g
end

def hash_to_insert(h)
  column_list = h.keys.join(',')

  "INSERT INTO photos (file_name, #{column_list}) VALUES (?, #{'?,' * (h.values.count - 1)}?)"
rescue Encoding::UndefinedConversionError
  nil
end

def exifToSQLite(path)
  raise "Not a path '#{path}'" if not File.exists?(path)

  db = SQLite3::Database.new "test.db"
  # Create a table
  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS photos (
      file_name TEXT
    );
  SQL

  Dir.glob(File.join(path, "**", "*")) do |file_name|
    puts file_name
    data = flat_hash(Exif::Data.new(File.open(file_name)).to_h)
    db_columns = db.execute("PRAGMA table_info(photos)").map do |record|
      record[1]
    end
    exif_columns = data.keys

    columns_to_add = exif_columns - db_columns

    db.execute("BEGIN TRANSACTION")
    columns_to_add.each{ |col| db.execute("ALTER TABLE photos ADD #{col} TEXT" ) }
    db.execute("COMMIT")

    db.execute(hash_to_insert(data), [file_name, data.values.map(&:to_s)].flatten)

    puts db.execute("SELECT * FROM photos")

    #   # Execute a few inserts
    #   {
    #     "one" => 1,
    #     "two" => 2,
    #   }.each do |pair|
    #     db.execute "insert into numbers values ( ?, ? )", pair
    #   end

    #   # Find a few rows
    #   db.execute( "select * from numbers" ) do |row|
    #     p row
    #   end
    #   # => ["one", 1]
    #   #    ["two", 2]

    #   # Create another table with multiple columns
    #   db.execute <<-SQL
    #   create table students (
    #     name varchar(50),
    #     email varchar(50),
    #     grade varchar(5),
    #     blog varchar(50)
    #   );
    # SQL

    #   # Execute inserts with parameter markers
    #   db.execute("INSERT INTO students (name, email, grade, blog)
    #             VALUES (?, ?, ?, ?)", ["Jane", "me@janedoe.com", "A", "http://blog.janedoe.com"])

    #   db.execute( "select * from students" ) do |row|
    #     p row
    #   end
  end
end
