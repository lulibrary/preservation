module Preservation

  # Base class for metadata and file management
  #
  class Ingest

    attr_reader :logger

    # @param ingest_path [String] absolute path to ingest directory
    # @param log_path [String] absolute path to log file
    # @param db_path [String] absolute path to sqlite file
    def initialize(ingest_path: nil,
                   log_path: nil,
                   db_path: nil)
      set_ingest_path ingest_path
      setup_logger log_path
      setup_report db_path
    end

    # Free up disk space for completed transfers
    #
    def cleanup_preserved
      preserved = get_preserved
      if !preserved.nil? && !preserved.empty?
        preserved.each do |i|
          # skip anything that has a different owner to script
          if File.stat(i).grpowned?
            FileUtils.remove_dir i
            @logger.info 'Deleted ' + i
          end
        end
      end
    end


    private

    def build_wget(username, password, file_url)
      # construct wget command with parameters
      wget_str = ''
      wget_str << 'wget'
      wget_str << ' '
      wget_str << '--user'
      wget_str << ' '
      wget_str << username
      wget_str << ' '
      wget_str << '--password'
      wget_str << ' '
      wget_str << '"' + password + '"'
      wget_str << ' '
      wget_str << file_url
      wget_str << ' '
      wget_str << '--no-check-certificate'
      wget_str
    end

    def set_ingest_path(ingest_path)
      if ingest_path.empty?
        puts 'Missing ingest path'
        exit
      else
        @ingest_path = ingest_path
      end
    end

    def setup_logger(log_path)
      if @logger.nil?
        if !log_path.nil? && !log_path.empty?
          # Keep data for today and the past 20 days
          @logger = Logger.new File.new(log_path, 'a'), 20, 'daily'
        else
          @logger = Logger.new STDOUT
        end
      end
      @logger.level = Logger::INFO
    end

    def setup_report(db_path)
      if db_path.empty?
        puts 'Missing db path'
        exit
      else
        @report = IngestReport.new db_path: db_path
      end
    end

    def enough_storage_for_download?(required_bytes)
      # scale up the required space using a multiplier
      multiplier = 2
      available = FreeDiskSpace.bytes('/')
      required_bytes * multiplier < available ? true : false
    end

    def build_directory_name(metadata_record, directory_name_scheme)
      doi = metadata_record['doi']
      uuid = metadata_record['uuid']
      title = metadata_record['title'].strip.gsub(' ', '-').gsub('/', '-')
      time = Time.new
      date = time.strftime("%Y-%m-%d")
      time = time.strftime("%H:%M:%S")
      join_str = '-----'

      case directory_name_scheme
        when :uuid_title
          [uuid, title].join(join_str)
        when :title_uuid
          [title, uuid].join(join_str)
        when :date_uuid_title
          [date, uuid, title].join(join_str)
        when :date_title_uuid
          [date, title, uuid].join(join_str)
        when :date_time_uuid
          [date, time, uuid].join(join_str)
        when :date_time_title
          [date, time, title].join(join_str)
        when :date_time_uuid_title
          [date, time, uuid, title].join(join_str)
        when :date_time_title_uuid
          [date, time, title, uuid].join(join_str)
        when :uuid
          uuid
        when :doi
          if doi.empty?
            return ''
          end
          doi.gsub('/', '-')
        when :doi_short
          if doi.empty?
            return ''
          end
          doi_short_to_remove = 'http://dx.doi.org/'
          short = doi.gsub(doi_short_to_remove, '')
          short.gsub!('/', '-')
        else
          uuid
      end
    end

    # time_to_preserve?
    #
    # @param start_utc [String]
    # @param days_at_which_to_expire [Integer]
    # @return [Boolean]
    def time_to_preserve?(start_utc, days_until_time_to_preserve)
      now = DateTime.now
      modified_datetime = DateTime.parse(start_utc)
      days_since_modified = (now - modified_datetime).to_i # result in days
      days_since_modified >= days_until_time_to_preserve ? true : false
    end

    # # Collect all paths from DB where preservation has been done
    # # @return [Array<String>]
    def get_preserved
      ingest_complete = @report.transfer_status(status_to_find: 'COMPLETE',
                                                     status_presence: true)
      preserved = []
      ingest_complete.each do |i|
        dir_path = @ingest_path + '/' + i['path']
        if File.exists?(dir_path)
          preserved << dir_path
        end
      end

      preserved
    end

  end

end

