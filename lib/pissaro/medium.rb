class Medium
  attr_accessor :file_name, :md5, :snapshot_id

  def initialize(hash)
    @file_name = hash[:file_name]
    @md5 = hash[:md5]
    @snapshot_id = hash[:snapshot_id]
  end
end
