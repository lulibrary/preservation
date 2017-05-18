module Preservation

  # Transfer preparation
  #
  module Transfer

    # Transfer preparation for Pure
    #
    class Pure < Ingest

      # @param base_url [String]
      # @param username [String]
      # @param password [String]
      # @param basic_auth [Boolean]
      def initialize(base_url: nil, username: nil, password: nil, basic_auth: nil)
        super()
        @base_url = base_url
        @basic_auth = basic_auth
        if basic_auth === true
          @username = username
          @password = password
        end
      end

      # For given uuid, if necessary, fetch the metadata,
      # prepare a directory in the ingest path and populate it with the files and
      # JSON description file.
      #
      # @param uuid [String] uuid to preserve
      # @param dir_scheme [Symbol] how to make directory name
      # @param delay [Integer] days to wait (after modification date) before preserving
      # @return [Boolean] indicates presence of metadata description file
      def prepare_dataset(uuid: nil,
                          dir_scheme: :uuid,
                          delay: 0)
        success = false

        if uuid.nil?
          @logger.error 'Missing ' + uuid
          exit
        end
        dir_base_path = Preservation.ingest_path

        dataset = Puree::Dataset.new base_url: @base_url,
                                     username: @username,
                                     password: @password,
                                     basic_auth: @basic_auth

        dataset.find uuid: uuid
        d = dataset.metadata
        if d.empty?
          @logger.error 'No metadata for ' + uuid
          exit
        end

        # configurable to become more human-readable
        dir_name = Preservation::Builder.build_directory_name(d, dir_scheme)

        # continue only if dir_name is not empty (e.g. because there was no DOI)
        # continue only if there is no DB entry
        # continue only if the dataset has a DOI
        # continue only if there are files for this resource
        # continue only if it is time to preserve
        if !dir_name.nil? &&
           !dir_name.empty? &&
           !Preservation::Report::Transfer.in_db?(dir_name) &&
           !d['doi'].empty? &&
           !d['file'].empty? &&
           Preservation::Temporal.time_to_preserve?(d['modified'], delay)

          dir_file_path = dir_base_path + '/' + dir_name
          dir_metadata_path = dir_file_path + '/metadata/'
          metadata_filename = dir_metadata_path + 'metadata.json'

          # calculate total size of data files
          download_storage_required = 0
          d['file'].each { |i| download_storage_required += i['size'].to_i }

          # do we have enough space in filesystem to fetch data files?
          if Preservation::Storage.enough_storage_for_download? download_storage_required
            # @logger.info 'Sufficient disk space for ' + dir_file_path
          else
            @logger.error 'Insufficient disk space to store files fetched from Pure. Skipping ' + dir_file_path
          end

          # has metadata file been created? if so, files and metadata are in place
          # continue only if files not present in ingest location
          if !File.size? metadata_filename

            @logger.info 'Preparing ' + dir_name + ', Pure UUID ' + d['uuid']

            data = []
            d['file'].each do |f|
              o = package_dataset_metadata d, f
              data << o
              wget_str = Preservation::Builder.build_wget @username,
                                                          @password,
                                                          f['url']

              Dir.mkdir(dir_file_path) if !Dir.exists?(dir_file_path)

              # fetch the file
              Dir.chdir(dir_file_path) do
                # puts 'Changing dir to ' + Dir.pwd
                # puts 'Size of ' + f['name'] + ' is ' + File.size(f['name']).to_s
                if File.size?(f['name'])
                  # puts 'Should be deleting ' + f['name']
                  File.delete(f['name'])
                end
                # puts f['name'] + ' missing or empty'
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
            @logger.info 'Skipping ' + dir_name + ', Pure UUID ' + d['uuid'] +
                         ' because ' + metadata_filename + ' exists'
          end
        else
          @logger.info 'Skipping ' + dir_name + ', Pure UUID ' + d['uuid']
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
      def prepare_dataset_batch(max: nil,
                                dir_scheme: :uuid,
                                delay: 30)
        collection = Puree::Collection.new resource:  :dataset,
                                           base_url:   @base_url,
                                           username:   @username,
                                           password:   @password,
                                           basic_auth: @basic_auth
        count = collection.count

        max = count if max.nil?

        batch_size = 10
        num_prepared = 0
        0.step(count, batch_size) do |n|

          minimal_metadata = collection.find limit:  batch_size,
                                             offset: n,
                                             full:   false
          uuids = []
          minimal_metadata.each do |i|
            uuids << i['uuid']
          end

          uuids.each do |uuid|
            success = prepare_dataset uuid:       uuid,
                                      dir_scheme: dir_scheme.to_sym,
                                      delay:      delay

            num_prepared += 1 if success
            exit if num_prepared == max
          end
        end
      end

      private

      def package_dataset_metadata(d, f)
          o = {}
          o['filename'] = 'objects/' + f['name']
          o['dc.title'] = d['title']
          if !d['description'].empty?
            o['dc.description'] = d['description']
          end
          o['dcterms.created'] = d['created']
          if !d['available']['year'].empty?
            o['dcterms.available'] = Puree::Date.iso(d['available'])
          end
          o['dc.publisher'] = d['publisher']
          if !d['doi'].empty?
            o['dc.identifier'] = d['doi']
          end
          if !d['spatial'].empty?
            o['dcterms.spatial'] = d['spatial']
          end
          if !d['temporal']['start']['year'].empty?
            temporal_range = ''
            temporal_range << Puree::Date.iso(d['temporal']['start'])
            if !d['temporal']['end']['year'].empty?
              temporal_range << '/'
              temporal_range << Puree::Date.iso(d['temporal']['end'])
            end
            o['dcterms.temporal'] = temporal_range
          end
          creators = []
          contributors = []
          person_types = %w(internal external other)
          person_types.each do |person_type|
            d['person'][person_type].each do |i|
              if i['role'] == 'Creator'
                creator = i['name']['last'] + ', ' + i['name']['first']
                creators << creator
              end
              if i['role'] == 'Contributor'
                contributor = i['name']['last'] + ', ' + i['name']['first']
                contributors << contributor
              end
            end
          end
          o['dc.creator'] = creators
          if !contributors.empty?
            o['dc.contributor'] = contributors
          end
          keywords = []
          d['keyword'].each { |i|
            keywords << i
          }
          if !keywords.empty?
            o['dc.subject'] = keywords
          end
          if !f['license']['name'].empty?
            o['dcterms.license'] = f['license']['name']
          end
          # o['dc.format'] = f['mime']

          related = []
          publications = d['publication']
          publications.each do |i|
            pub = Puree::Publication.new base_url: @base_url,
                                         username: @username,
                                         password: @password,
                                         basic_auth: @basic_auth
            pub.find uuid: i['uuid']
            doi = pub.doi
            if doi
              related << doi
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