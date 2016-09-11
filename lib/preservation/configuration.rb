module Preservation

  # Configuration options
  #
  module Configuration

    attr_accessor :db_path, :ingest_path, :log_path

    def configure
      yield self
    end

  end

end