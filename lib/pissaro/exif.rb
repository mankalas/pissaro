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
  value_list = h.values.map { |x| "'#{x}"}.join(',')

  "INSERT photos (#{column_list}) VALUES (#{value_list})"
end

def exifToSQLite()
  data = flat_hash(Exif::Data.new(File.open('spec/samples/IMG_5934.jpg')).to_h)
  db = SQLite3::Database.new "test.db"

  # Create a table
  #   db.execute <<-SQL
  #   CREATE TABLE photos (
  #     id INTEGER PRIMARY KEY
  #   );
  # SQL

  db_columns = db.execute("PRAGMA table_info(photos)").map do |record|
    record[1]
  end
  exif_columns = data.keys

  columns_to_add = exif_columns - db_columns

  puts columns_to_add

  if columns_to_add.map { |col|
       db.execute("ALTER TABLE photos ADD #{col} TEXT" )
     }
  end

  begin
    puts hash_to_insert(data)
    db.execute(hash_to_insert(data))
  rescue SQLite3::SQLException
    puts "ERORR"
  end


  db.execute("SELECT * FROM photos WHERE id = 3")

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
