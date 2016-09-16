module Preservation

  # Reporting
  #
  module Report

    # Database connection
    #
    module Database

      private

      def create_db_connection(db_path)
        if db_path.nil?
          puts 'Missing db_path'
          exit
        end
        SQLite3::Database.new db_path
      end

    end

  end

end