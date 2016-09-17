module Preservation

  # Storage
  #
  module Storage

    # Free up disk space for completed transfers
    #
    def self.cleanup
      preserved = get_preserved
      if !preserved.nil? && !preserved.empty?
        preserved.each do |i|
          # skip anything that has a different owner to script
          if File.stat(i).grpowned?
            FileUtils.remove_dir i
            # @logger.info 'Deleted ' + i
          end
        end
      end
    end

    # Enough storage for download?
    #
    # @return [Boolean]
    def self.enough_storage_for_download?(required_bytes)
      # scale up the required space using a multiplier
      multiplier = 2
      available = FreeDiskSpace.bytes('/')
      required_bytes * multiplier < available ? true : false
    end

    # Collect all paths from DB where preservation has been done
    # @return [Array<String>]
    def self.get_preserved
      ingest_complete = Preservation::Report::Transfer.status(status_to_find: 'COMPLETE',
                                                              status_presence: true)
      preserved = []
      ingest_complete.each do |i|
        dir_path = Preservation.ingest_path + '/' + i['path']
        if File.exists?(dir_path)
          preserved << dir_path
        end
      end

      preserved
    end

  end

end