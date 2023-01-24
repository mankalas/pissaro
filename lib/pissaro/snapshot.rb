require 'digest'
require 'pissaro/persistence'

class Snapshot
  def md5(path)
    raise "Not a directory" unless File.directory?(path)

    id = Persistence.new.create_snapshot

    puts "MD5 snapshot of #{path}"
    Dir.glob(File.join(path, "**", "*")) do |file_name|
      if File.directory?(file_name)
        puts "- #{file_name}"
        next
      else
        md5 = Digest::MD5.hexdigest(File.read(file_name))
        Persistence.new.upsert_md5(file_name, md5, id)
      end
    end
    puts "Done"
  end
end
