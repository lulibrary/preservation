module Preservation

  # Ingest for Pure
  #
  class PureIngest < Ingest

    def initialize
      super
    end

    # For each uuid, if necessary, fetch the metadata,
    # prepare a directory in the ingest path and populate it with the files and
    # JSON description file.
    #
    # @param uuids [Array<String>] uuids to preserve
    # @param dir_name_scheme [Symbol] method to make directory name
    # @param delay [Integer] days to wait (after modification date) before preserving
    def prepare_dataset(uuids: [],
                        dir_name_scheme: :uuid,
                        delay: 0)
      dir_base_path = Preservation.ingest_path

      uuids.each do |uuid|
        dataset = Puree::Dataset.new
        dataset.find uuid: uuid
        d = dataset.metadata
        if d.empty?
          @logger.info 'No metadata for ' + uuid
          next
        end
        # configurable to become more human-readable
        dir_name = build_directory_name(d, dir_name_scheme)

        # continue only if dir_name is not empty (e.g. because there was no DOI)
        # continue only if there is no DB entry
        # continue only if the dataset has a DOI
        # continue only if there are files for this resource
        # continue only if it is time to preserve
        if !dir_name.nil? &&
           !dir_name.empty? &&
           !@report.in_db?(dir_name) &&
           !d['doi'].empty? &&
           !d['file'].empty? &&
           time_to_preserve?(d['modified'], delay)

          dir_file_path = dir_base_path + '/' + dir_name
          dir_metadata_path = dir_file_path + '/metadata/'
          metadata_filename = dir_metadata_path + 'metadata.json'

          # calculate total size of data files
          download_storage_required = 0
          d['file'].each { |i| download_storage_required += i['size'].to_i }

          # do we have enough space in filesystem to fetch data files?
          if enough_storage_for_download? download_storage_required
            # @logger.info 'Sufficient disk space for ' + dir_file_path
          else
            @logger.error 'Insufficient disk space to store files fetched from Pure. Skipping ' + dir_file_path
            next
          end

          # has metadata file been created? if so, files and metadata are in place
          # continue only if files not present in ingest location
          if !File.size? metadata_filename

            @logger.info 'Preparing ' + dir_name + ', Pure UUID ' + d['uuid']

            data = []
            d['file'].each do |f|
              o = package_dataset_metadata d, f
              data << o
              wget_str = build_wget Puree.username,
                                    Puree.password,
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
          end
        else
          @logger.info 'Skipping ' + dir_name + ', Pure UUID ' + d['uuid']
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
          o_related = {}
          o_related['dc.title'] = i['title']
          o_related['type'] = i['type']
          pub = Puree::Publication.new
          pub.find uuid: i['uuid']
          doi = pub.doi
          if doi
            o_related['dc.identifier'] = doi
          end
          related << o_related
        end
        if !related.empty?
          o['related'] = related
        end

        o
    end

  end

end