require "pissaro/persistence"
require "sqlite3"

DB_TEST="test.db"
TABLE_TEST="foo"

RSpec.describe Persistence do
  let(:db) { SQLite3::Database.new(DB_TEST) }
  let(:persistence) { Persistence.new(DB_TEST) }
  let(:table_test) { Persistence::MEDIA_TABLE_NAME }
  let(:columns) { Persistence::MEDIA_BASE_COLUMNS_NAMES }

  before do
    raise "Don't test on #{Persistence::DB_NAME}!" if DB_TEST == Persistence::DB_NAME

    sql_columns = columns.map { |c| "#{c} TEXT"}.join(",")
    db.execute("CREATE TABLE #{table_test}(#{sql_columns})")
  end

  describe "delete" do
    subject { persistence.delete }

    it "deletes the file" do
      expect { subject }
        .to change { File.exists?(DB_TEST) }
              .from(true).to(false)
    end
  end

  describe "columns" do
    subject { persistence.columns(table_test) }

    it { is_expected.to eq(columns) }

    describe "when table is invalid" do
      it "is empty" do
        expect { persistence.columns("lorem").to be_empty }
      end
    end
  end

  describe "record_count" do
    subject { persistence.record_count(table_test) }

    let(:nb_records) { 5 }

    before do
      values = columns.map { |c| (65 + rand(26)).chr }.map { |c| "'#{c}'" }.join(",")
      nb_records.times { db.execute("INSERT INTO #{table_test} VALUES (#{values})") }
    end

    describe "when the table is empty" do
      let(:nb_records) { 0 }

      it { is_expected.to be_zero }
    end

    describe "when the table has some records" do
      it { is_expected.to eq nb_records }
    end

    describe "when the table name is invalid" do
      it "returns nil" do
        expect(persistence.record_count("lorem")).to be_nil
      end
    end
  end

  describe "set" do
    before do
      File.delete(DB_TEST) if File.exists?(DB_TEST)
    end

    it "setup the database" do
      expect { persistence.set }
        .to change { File.exists?(DB_TEST) }
              .from(false).to(true)
      expect(persistence.columns(Persistence::MEDIA_TABLE_NAME))
        .to eq(%W{id file_name snapshot_id md5})
      expect(persistence.columns(Persistence::SNAPSHOT_TABLE_NAME))
        .to eq(%W{id created_at finished_at})
    end
  end

  describe "insert_media" do
    let(:data) { Hash.new }

    subject { persistence.insert_media(data) }

    describe "when data doesn't contain base columns" do
      let(:data) { { foo: "lorem" } }

      it "raises an error" do
        expect { subject }.to raise_error "Data is missing base columns"
      end

      it "does not insert a new record" do
        expect { begin subject rescue String end }
          .not_to change { persistence.record_count(table_test) }
      end

      it "does not change the table's schema" do
        expect { begin subject rescue String end }
          .not_to change { persistence.columns(Persistence::MEDIA_TABLE_NAME) }
      end

    end

    describe "when data is valid" do
      describe "when data contains no new column" do
        let(:data) { columns.map { |c| [c, "lorem"] }.to_h }

        it "inserts a new record" do
          expect { subject }
            .to change { persistence.record_count(table_test) }.by(1)
        end

        it "does not change the table's schema" do
          expect { subject }
            .not_to change { persistence.columns(table_test) }
        end
      end

      describe "when data contains new columns" do
        let(:media_columns) { columns + %W{foo bar} }
        let(:data) { media_columns.map { |c| [c, "lorem"] }.to_h }

        it "inserts a new record" do
          expect { subject }
            .to change { persistence.record_count(table_test) }.by(1)
        end

        it "adds the new columns to the table" do
          expect { subject }
            .to change { persistence.columns(table_test) }
                  .from(columns).to(media_columns)
        end
      end
    end
  end

  after do
    db.close
    File.delete(DB_TEST) if File.exists?(DB_TEST)
  end
end
