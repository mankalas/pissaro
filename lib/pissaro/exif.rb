require 'exif'
require 'sqlite3'
require 'pp'

module Exif
  def Exif.flat_hash(h, f=nil, g={})
    return g.update({ f => h }) unless h.is_a? Hash
    h.each { |k, r| flat_hash(r, [f,k].compact.join('_'), g) }
    g
  end

  def Exif.exif_to_hash(path)
    Exif.flat_hash(Exif::Data.new(File.open(path)).to_h)
  rescue Exif::NotReadable => e
    { error: e.to_s }
  end
end
