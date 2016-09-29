module Preservation

  # Builder
  #
  module Builder

    # Build wget string
    #
    # @param username [String]
    # @param password [String]
    # @param file_url [String]
    # @return [String]
    def self.build_wget(username, password, file_url)
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

    # Build directory name
    #
    # @param metadata_record [Hash]
    # @param directory_name_scheme [Symbol]
    # @return [String]
    def self.build_directory_name(metadata_record, directory_name_scheme)
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

  end

end