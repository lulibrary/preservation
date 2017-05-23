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
          raise 'Missing db_path'
        end
        @db ||= SQLite3::Database.new db_path
      end

    end

  end

end