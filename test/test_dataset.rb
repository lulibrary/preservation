require 'test_helper'

class TestDatasetTransfer < Minitest::Test
  def configure
    Preservation.configure do |config|
      config.db_path     = ENV['ARCHIVEMATICA_DB_PATH']
      config.ingest_path = ENV['ARCHIVEMATICA_INGEST_PATH']
      config.log_path    = ENV['PRESERVATION_LOG_PATH']
    end
    @config = {
        url:      ENV['PURE_URL'],
        username: ENV['PURE_USERNAME'],
        password: ENV['PURE_PASSWORD']
    }
    @transfer = Preservation::Transfer::Dataset.new @config
  end

  def prepare_transfer
    configure

    collection_extractor = Puree::Extractor::Collection.new config:   @config,
                                                            resource: :dataset
    dataset = collection_extractor.random_resource

    @metadata_record = {
       doi:   dataset.doi,
       uuid:  dataset.uuid,
       title: dataset.title
    }

    @files = dataset.files

    # could randomise dir_scheme
    # but doi must be present in metadata_record if using doi-based scheme
    dir_scheme = :uuid

    @success = @transfer.prepare uuid: @metadata_record[:uuid]

    build_paths_to_check dir_scheme if @success
  end

  def build_paths_to_check(dir_scheme)
    transfer_dir = Preservation::Builder.build_directory_name(@metadata_record, dir_scheme)
    @transfer_path = File.join(Preservation.ingest_path, transfer_dir)
    @metadata_path = File.join(@transfer_path, 'metadata')
    @metadata_description_file_path = File.join(@metadata_path, 'metadata.json')

    @file_paths = []
    @files.each do |i|
      dataset_filename = i.name
      dataset_file_path = File.join(@transfer_path, dataset_filename)
      @file_paths << dataset_file_path
    end
  end

  def test_is_a_dataset_transfer
    configure
    assert_instance_of Preservation::Transfer::Dataset, @transfer
  end

  def test_load_directory
    prepare_transfer
    if @success
      assert Dir.exist?(@transfer_path)
      assert Dir.exist?(@metadata_path)
      assert File.size?(@metadata_description_file_path)
      assert @file_paths.size > 0
      @file_paths.each { |i| assert File.size?(i) }
    end
  end

end