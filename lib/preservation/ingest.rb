module Preservation

  # Ingest
  #
  class Ingest

    attr_reader :logger

    def initialize
      setup_logger
      check_ingest_path
     end

    private

    def check_ingest_path
      if Preservation.ingest_path.nil?
        @logger.error 'Missing ingest path'
        exit
      end
    end

    def setup_logger
      if @logger.nil?
        if Preservation.log_path.nil?
          @logger = Logger.new STDOUT
        else
          # Keep data for today and the past 20 days
          @logger = Logger.new File.new(Preservation.log_path, 'a'), 20, 'daily'
        end
      end
      @logger.level = Logger::INFO
    end

  end

end

