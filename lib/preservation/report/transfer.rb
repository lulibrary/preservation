module Preservation

  module Report

    # Transfer reporting
    #
    module Transfer

      # Transfers based on presence (or not) of a particular status
      #
      # @param status_to_find [String]
      # @param status_presence [Boolean]
      def self.status(status_to_find: nil, status_presence: true)
        if status_presence === true
          status_presence = '='
        else
          status_presence = '<>'
        end

        query = "SELECT id, uuid, hex(path) as hex_path, unit_type, status, microservice, current FROM unit WHERE status #{status_presence} ?"

        # Archivematica stores path as BLOB, so need to convert path to Hex, to search for it
        # and use hex function in DB query
        records = []
        db.results_as_hash = true
        db.execute( query, [ status_to_find ] ) do |row|
          id = row['id']
          uuid = row['uuid']
          bin_path = Preservation::Conversion.hex_to_bin row['hex_path']
          unit_type = row['unit_type']
          status = row['status']
          microservice = row['microservice']
          current = row['current']
          o = {}
          o['path'] = bin_path if !bin_path.empty?
          o['unit_type'] = unit_type if !unit_type.empty?
          o['status'] = status if !status.empty?
          o['microservice'] = microservice if !microservice.empty?
          o['current'] = current if current
          o['id'] = id if id
          o['uuid'] = uuid if !uuid.empty?

          records << o
        end

        records
      end

      # Current transfer
      #
      # @return [Hash]
      def self.current
        query = "SELECT id, uuid, hex(path) as hex_path, unit_type, status, microservice, current FROM unit WHERE current = 1"

        # Archivematica stores path as BLOB, so need to convert path to Hex, to search for it
        # and use hex function in DB query
        o = {}
        db.results_as_hash = true
        db.execute( query ) do |row|
          id = row['id']
          uuid = row['uuid']
          bin_path = hex_to_bin row['hex_path']
          unit_type = row['unit_type']
          status = row['status']
          microservice = row['microservice']
          current = row['current']
          o['path'] = bin_path if !bin_path.empty?
          o['unit_type'] = unit_type if !unit_type.empty?
          o['status'] = status if !status.empty?
          o['microservice'] = microservice if !microservice.empty?
          o['current'] = current if current
          o['id'] = id if id
          o['uuid'] = uuid if !uuid.empty?
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

      # Compilation of statistics and data, with focus on exceptions
      #
      # @return [Hash]
      def self.exception
        incomplete = status(status_to_find: 'COMPLETE', status_presence: false)
        failed = status(status_to_find: 'FAILED', status_presence: true)
        report = {}
        report['current'] = current if !current.empty?
        report['failed'] = {}
        report['failed']['count'] = failed.count
        report['failed']['data'] = failed if !failed.empty?
        report['incomplete'] = {}
        report['incomplete']['count'] = incomplete.count
        report['incomplete']['data'] = incomplete if !incomplete.empty?
        report['complete'] = {}
        report['complete']['count'] = complete_count if complete_count
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

      # Db
      #
      # @return [SQLite3::Database]
      def self.db
        Preservation::Report::Database.db_connection Preservation.db_path
      end

    end

  end

end