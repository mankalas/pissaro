require 'exif'
require 'sqlite3'
require 'pp'

def flat_hash(h, f=nil, g={})
  return g.update({ f => h }) unless h.is_a? Hash
  h.each { |k, r| flat_hash(r, [f,k].compact.join('_'), g) }
  g
end

def exif_to_hash(path)
  flat_hash(Exif::Data.new(File.open(file_name)).to_h)
end
