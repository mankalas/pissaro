require "pissaro/snapshot"
require "pissaro/persistence"
require "sqlite3"

RSpec.describe Snapshot do
  DB_NAME = "snapshot.db"

  let(:persistence) { Persistence.new(DB_NAME) }
  let(:snap) { Snapshot.new(persistence) }

  before do
    persistence.set
  end

  describe "create" do
    subject { snap.create(path) }

    describe "when path does not exists" do
      let(:path) { "lorem" }

      it "raises an error" do
        expect { subject }.to raise_error "Path does not exist"
      end
    end

    describe "when path is a file" do
      let(:path) { "spec/samples/photo.jpg" }

      it "creates a new snapshot record" do
        expect { subject }.to change { persistence.snapshot_count }.by(1)
      end

      it "creates a new media record" do
        expect { subject }.to change { persistence.media_count }.by(1)
        media = persistence.media_by_snapshot(subject)
        expect(media.count).to eq 1
        medium = media.first
        expect(medium.file_name).to eq(path)
        expect(medium.md5).not_to be_nil
        expect(medium.snapshot_id).to eq 1
      end
    end

    describe "when path is a directory" do
      let(:path){ "spec/samples/media" }

      it "creates a new snapshot record" do
        expect { subject }.to change { persistence.snapshot_count }.by(1)
      end

      it "creates as many new media record as there are files" do
        expect { subject }.to change { persistence.media_count }.by(2)
      end
    end

    describe "when there already is a previous snapshot" do
      let(:path) { "spec/samples/photo.jpg" }

      before do
        snap.create(path)
        expect(persistence.media_count).to eq(1)
      end

      it "creates a new snapshot record" do
        expect { subject }.to change { persistence.snapshot_count }.by(1)
        expect(persistence.snapshot_count).to eq(2)
      end

      it "creates a new media record" do
        expect { subject }.to change { persistence.media_count }.by(1)
        expect(persistence.media_count).to eq(2)
      end

      it "media records have a different snapshot id" do
        snap.create(path)

        media = persistence.media_all
        expect(media[0].snapshot_id).not_to eq(media[1].snapshot_id)
      end
    end
  end

  after do
    File.delete(DB_NAME)
  end
end
