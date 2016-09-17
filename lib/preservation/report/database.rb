module Preservation

  # Reporting
  #
  module Report

    # Database
    #
    module Database

      # Database connection
      #
      # @return [SQLite3::Database]
       def self.db_connection(db_path)
        if db_path.nil?
          puts 'Missing db_path'
          exit
        end
        @db ||= SQLite3::Database.new db_path
      end

    end

  end

end