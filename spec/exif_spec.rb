require "pissaro/exif"

RSpec.describe Exif do
  describe "flat_hash" do
    it "concatenates nested hashes with '_'" do
      expect(flat_hash({a: 2, b: {c: {d: 3}}})).to eq({"a" => 2, "b_c_d" => 3})
    end
  end

  describe "hash_to_insert" do
    it "turns a hash into an INSERT instruction" do
      expect(hash_to_insert({a: 3, r_t: 5, f_g: "123"}))
        .to eq("INSERT INTO photos (a,r_t,f_g) VALUES ('3','5','123')")
    end
  end
end
