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

  describe "from_record" do
    it "construct a valid snapshot" do
      snapshot = Snapshot.new(nil, {id: 1, created_at: 2, finished_at: 3})
      expect(snapshot.id).to eq 1
      expect(snapshot.created_at).to eq 2
      expect(snapshot.finished_at).to eq 3
    end
  end

  describe "create" do
    subject { snap.create(path) }

    describe "when path does not exists" do
      let(:path) { "lorem" }

      it "raises an error" do
        expect { subject }.to raise_error "Path does not exist"
      end

      it "doesn't create a snapshot" do
        expect do
          begin
            subject
          rescue Exception
            nil
          end
        end.not_to change { persistence.snapshot_count }
      end
    end

    describe "when path is a file" do
      let(:path) { "spec/samples/photo.jpg" }

      it "creates a new snapshot record" do
        expect { subject }.to change { persistence.snapshot_count }.by(1)
      end

      it "populates the finish date" do
        snapshot = persistence.get_snapshot(subject)
        expect(snapshot.finished_at).not_to be_nil
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

      describe "when it's a file >2.5Gb" do
        # TODO
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

      describe "interruption" do

        "MAke sure a snapshot has a finished date"
        "Otherwise, it has been interrupted, and next snapshot should use the unfinished one, ignoring all files that were done during the unfinished snapshot"
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
        subject

        media = persistence.media_all
        expect(media[0].snapshot_id).not_to eq(media[1].snapshot_id)
      end
    end
  end

  after do
    File.delete(DB_NAME)
  end
end
