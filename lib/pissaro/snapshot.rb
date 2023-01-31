require 'digest'
require 'pissaro/persistence'

class Snapshot
  attr_reader :persistence, :snap_id

  def initialize(persistence)
    @persistence = persistence
  end

  def create(path)
    raise "Path does not exist" unless File.exists?(path)

    @snap_id = persistence.create_snapshot

    if File.file?(path)
      process_file(path)
    elsif File.directory?(path)
      Dir.glob(File.join(path, "**", "*")) do |sub_path|
        next unless File.file?(sub_path)
        process_file(sub_path)
      end
    end

    return snap_id
  end

  def process_file(path)
    persistence.insert_media(file_name: path, md5: md5(path), snapshot_id: snap_id)
  end

  def md5(path)
    Digest::MD5.hexdigest(File.read(path))
  end

  private

  attr_writer :snap_id
end
