module Preservation

  module Report

    # Transfer reporting
    #
    module Transfer

      # Transfers based on presence (or not) of a particular status
      #
      # @param status_to_find [String]
      # @param status_presence [Boolean]
      # @return [Array<Hash>]
      def self.status(status_to_find: nil, status_presence: true)
        if status_presence === true
          status_presence = '='
        else
          status_presence = '<>'
        end

        query = "SELECT id, uuid, hex(path) as hex_path, unit_type, status, microservice, current FROM unit WHERE status #{status_presence} ?"

        records = []
        db.results_as_hash = true
        db.execute( query, [ status_to_find ] ) do |row|
          bin_path = Preservation::Conversion.hex_to_bin row['hex_path']
          if !bin_path.nil? && !bin_path.empty?
            records << row_to_hash(row)
          end
        end

        records
      end

      # Current transfer
      #
      # @return [Hash]
      def self.current
        query = "SELECT id, uuid, hex(path) as hex_path, unit_type, status, microservice, current FROM unit WHERE current = 1"

        o = {}
        db.results_as_hash = true
        db.execute( query ) do |row|
          o = row_to_hash(row)
        end
        o
      end

      # Count of complete transfers
      #
      # @return [Integer]
      def self.complete_count
        query = 'SELECT count(*) FROM unit WHERE status = ?'

        status_to_find = 'COMPLETE'
        db.results_as_hash = true
        db.get_first_value( query, [status_to_find] )
      end

      # Pending transfers
      #
      # @return [Hash]
      def self.pending
        entries = Dir.entries Preservation.ingest_path
        dirs = []
        entries.each do |entry|
          path = File.join(Preservation.ingest_path, entry)
          if File.directory?(path)
            dirs << entry unless File.basename(path).start_with?('.')
          end
        end
        a = []
        # For each directory, if it isn't in the db, add it to list
        dirs.each do |dir|
          if in_db?(dir) === false
            o = {}
            o['path'] = dir
            o['path_timestamp'] = File.mtime File.join(Preservation.ingest_path, dir)
            a << o
          end
        end
        a
      end

      # Is there a pending transfer with this path?
      #
      # @return [Boolean]
      def self.pending?(path_to_find)
        is_pending = false
        pending.each do |i|
          if i['path'] == path_to_find
            is_pending = true
            break
          end
        end
        is_pending
      end


      # Compilation of statistics and data, with focus on exceptions
      #
      # @return [Hash]
      def self.exception
        incomplete_result = status(status_to_find: 'COMPLETE', status_presence: false)
        failed_result = status(status_to_find: 'FAILED', status_presence: true)
        pending_result = pending
        current_result = current
        complete_count_result = complete_count
        report = {}
        report['pending'] = {}
        report['pending']['count'] = pending_result.count
        report['pending']['data'] = pending_result if !pending_result.empty?
        report['current'] = current_result if !current_result.empty?
        report['failed'] = {}
        report['failed']['count'] = failed_result.count
        report['failed']['data'] = failed_result if !failed_result.empty?
        report['incomplete'] = {}
        report['incomplete']['count'] = incomplete_result.count
        report['incomplete']['data'] = incomplete_result if !incomplete_result.empty?
        report['complete'] = {}
        report['complete']['count'] = complete_count_result if complete_count_result
        report
      end

      # Is it in database?
      # @param path_to_find [String] directory name within ingest path
      # @return [Boolean]
      def self.in_db?(path_to_find)
        in_db = false

        # Get path out of DB as a hex string
        query = 'SELECT hex(path) FROM unit'

        # Archivematica stores path as BLOB, so need to convert path to Hex, to search for it
        # and use hex function in DB query
        db.execute( query ) do |row|
          bin_path = Preservation::Conversion.hex_to_bin row[0]
          if bin_path === path_to_find
            in_db = true
          end
        end

        in_db
      end

      # Has preservation been done?
      # @param path_to_find [String] directory name within ingest path
      # @return [Boolean]
      def self.preserved?(path_to_find)
        preserved = false

        # 'ingest' value in unit_type and 'COMPLETE' value in status DB fields
        # indicates completed
        unit_type_to_find = 'ingest'
        status_to_find = 'COMPLETE'

        # Get path out of DB as a hex string for completed ingests
        query = 'SELECT hex(path) FROM unit WHERE unit_type = ? AND status = ?'

        # Archivematica stores path as BLOB, so need to convert path to Hex, to search for it
        # and use hex function in DB query
        db.execute( query, [ unit_type_to_find, status_to_find ] ) do |row|
          bin_path = Preservation::Conversion.hex_to_bin row[0]
          if bin_path === path_to_find
            preserved = true
          end
        end

        preserved
      end

      private

      # Db
      #
      # @return [SQLite3::Database]
      def self.db
        Preservation::Report::Database.db_connection Preservation.db_path
      end

      def self.row_to_hash(row)
        id = row['id']
        uuid = row['uuid']
        # Archivematica stores path as BLOB, so need to convert path to Hex, to search for it
        # and use hex function in DB query
        bin_path = Preservation::Conversion.hex_to_bin row['hex_path']
        unit_type = row['unit_type']
        status = row['status']
        microservice = row['microservice']
        current = row['current']
        o = {}
        o['path'] = bin_path if !bin_path.nil? && !bin_path.empty?
        o['unit_type'] = unit_type if !unit_type.nil? && !unit_type.empty?
        o['status'] = status if !status.nil? && !status.empty?
        o['microservice'] = microservice if !microservice.nil? && !microservice.empty?
        o['current'] = current if current
        o['id'] = id if id
        o['uuid'] = uuid if !uuid.nil? && !uuid.empty?
        path = "#{Preservation.ingest_path}/#{bin_path}"
        if File.exist? path
          o['path_timestamp'] = File.mtime path
        end
        o
      end

    end

  end

end