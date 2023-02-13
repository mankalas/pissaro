require "pissaro/exif"

RSpec.describe Exif do
  describe "flat_hash" do
    it "concatenates nested hashes with '_'" do
      expect(Exif.flat_hash({a: 2, b: {c: {d: 3}}})).to eq({"a" => 2, "b_c_d" => 3})
    end
  end
end
