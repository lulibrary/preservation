module Preservation

  # Transfer preparation
  #
  module Transfer

    # Transfer preparation for dataset
    #
    class Dataset < Preservation::Transfer::Base

      # @param config [Hash]
      def initialize(config)
        super()
        @pure_config = config
      end

      # For given uuid, if necessary, fetch the metadata,
      # prepare a directory in the ingest path and populate it with the files and
      # JSON description file.
      #
      # @param uuid [String] uuid to preserve
      # @param dir_scheme [Symbol] how to make directory name
      # @param delay [Integer] days to wait (after modification date) before preserving
      # @return [Boolean] indicates presence of metadata description file
      def prepare(uuid: nil,
                  dir_scheme: :uuid,
                  delay: 0)
        success = false

        if uuid.nil?
          @logger.error 'Missing ' + uuid
          exit
        end
        dir_base_path = Preservation.ingest_path

        dataset_extractor = Puree::Extractor::Dataset.new @pure_config
        d = dataset_extractor.find uuid: uuid
        if !d
          @logger.error 'No metadata for ' + uuid
          exit
        end

        metadata_record = {
          doi:   d.doi,
          uuid:  d.uuid,
          title: d.title
        }

        # configurable to become more human-readable
        dir_name = Preservation::Builder.build_directory_name(metadata_record, dir_scheme)

        # continue only if dir_name is not empty (e.g. because there was no DOI)
        # continue only if there is no DB entry
        # continue only if the dataset has a DOI
        # continue only if there are files for this resource
        # continue only if it is time to preserve
        if !dir_name.nil? &&
           !dir_name.empty? &&
           !Preservation::Report::Transfer.in_db?(dir_name) &&
           d.doi &&
           !d.files.empty? &&
           Preservation::Temporal.time_to_preserve?(d.modified, delay)

          dir_file_path = dir_base_path + '/' + dir_name
          dir_metadata_path = dir_file_path + '/metadata/'
          metadata_filename = dir_metadata_path + 'metadata.json'

          # calculate total size of data files
          download_storage_required = 0
          d.files.each { |i| download_storage_required += i.size.to_i }

          # do we have enough space in filesystem to fetch data files?
          if Preservation::Storage.enough_storage_for_download? download_storage_required
            # @logger.info 'Sufficient disk space for ' + dir_file_path
          else
            @logger.error 'Insufficient disk space to store files fetched from Pure. Skipping ' + dir_file_path
          end

          # has metadata file been created? if so, files and metadata are in place
          # continue only if files not present in ingest location
          if !File.size? metadata_filename

            @logger.info 'Preparing ' + dir_name + ', Pure UUID ' + d.uuid

            data = []
            d.files.each do |f|
              o = package_metadata d, f
              data << o
              wget_str = Preservation::Builder.build_wget @pure_config[:username],
                                                          @pure_config[:password],
                                                          f.url

              Dir.mkdir(dir_file_path) if !Dir.exists?(dir_file_path)

              # fetch the file
              Dir.chdir(dir_file_path) do
                # puts 'Changing dir to ' + Dir.pwd
                # puts 'Size of ' + f.name + ' is ' + File.size(f.name).to_s
                if File.size?(f.name)
                  # puts 'Should be deleting ' + f['name']
                  File.delete(f.name)
                end
                # puts f.name + ' missing or empty'
                # puts wget_str
                `#{wget_str}`
              end
            end

            Dir.mkdir(dir_metadata_path) if !Dir.exists?(dir_metadata_path)

            pretty = JSON.pretty_generate( data, :indent => '  ')
            # puts pretty
            File.write(metadata_filename,pretty)
            @logger.info 'Created ' + metadata_filename
            success = true
          else
            @logger.info 'Skipping ' + dir_name + ', Pure UUID ' + d.uuid +
                         ' because ' + metadata_filename + ' exists'
          end
        else
          @logger.info 'Skipping ' + dir_name + ', Pure UUID ' + d.uuid
        end
        success
      end

      # For multiple datasets, if necessary, fetch the metadata,
      # prepare a directory in the ingest path and populate it with the files and
      # JSON description file.
      #
      # @param max [Integer] maximum to prepare, omit to set no maximum
      # @param dir_scheme [Symbol] how to make directory name
      # @param delay [Integer] days to wait (after modification date) before preserving
      def prepare_batch(max: nil,
                        dir_scheme: :uuid,
                        delay: 30)
        collection_extractor = Puree::Extractor::Collection.new config:   @pure_config,
                                                                resource: :dataset
        count = collection_extractor.count

        max = count if max.nil?

        batch_size = 10
        num_prepared = 0
        0.step(count, batch_size) do |n|

          dataset_collection = collection_extractor.find limit:  batch_size,
                                                         offset: n
          dataset_collection.each do |dataset|
            success = prepare uuid:       dataset.uuid,
                              dir_scheme: dir_scheme.to_sym,
                              delay:      delay

            num_prepared += 1 if success
            exit if num_prepared == max
          end
        end
      end

      private

      def package_metadata(d, f)
          o = {}
          o['filename'] = 'objects/' + f.name
          o['dc.title'] = d.title
          if d.description
            o['dc.description'] = d.description
          end
          o['dcterms.created'] = d.created.to_s
          if d.available
            o['dcterms.available'] = d.available
          end
          o['dc.publisher'] = d.publisher
          if d.doi
            o['dc.identifier'] = d.doi
          end
          if !d.spatial_places.empty?
            o['dcterms.spatial'] = d.spatial_places
          end

          temporal = d.temporal
          temporal_range = ''
          if temporal
            if temporal.start
              temporal_range << temporal.start.strftime("%F")
              if temporal.end
                temporal_range << '/'
                temporal_range << temporal.end.strftime("%F")
              end
              o['dcterms.temporal'] = temporal_range
            end
          end

          creators = []
          contributors = []
          all_persons = []
          all_persons << d.persons_internal
          all_persons << d.persons_external
          all_persons << d.persons_other
          all_persons.each do |person_type|
            person_type.each do |i|
              name = i.name.last_first if i.name
              if i.role == 'Creator'
                creators << name if name
              end
              if i.role == 'Contributor'
                contributors << name if name
              end
            end
          end

          o['dc.creator'] = creators
          if !contributors.empty?
            o['dc.contributor'] = contributors
          end
          keywords = []
          d.keywords.each { |i|
            keywords << i
          }
          if !keywords.empty?
            o['dc.subject'] = keywords
          end

          o['dcterms.license'] = f.license.name if f.license
          # o['dc.format'] = f.mime

          related = []
          publications = d.publications
          publications.each do |i|
            if i.type === 'Dataset'
              extractor = Puree::Extractor::Dataset.new @pure_config
              dataset = extractor.find uuid: i.uuid
              doi = dataset.doi
              if doi
                related << doi
              end
            end
            if i.type === 'Publication'
              extractor = Puree::Extractor::Publication.new @pure_config
              publication = extractor.find uuid: i.uuid
              dois = publication.dois
              if !dois.empty?
                # Only one needed
                related << dois[0]
              end
            end
          end
          if !related.empty?
            o['dc.relation'] = related
          end

          o
      end

    end

  end

end