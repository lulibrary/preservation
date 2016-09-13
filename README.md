# Preservation [![Gem Version](https://badge.fury.io/rb/preservation.svg)](https://badge.fury.io/rb/preservation) [![GitPitch](https://gitpitch.com/assets/badge.svg)](https://gitpitch.com/lulibrary/preservation/master?grs=github&t=sky)

Ingest management for Archivematica's <a href="https://github.com/artefactual/automation-tools" target="_blank">Automation Tools</a>.

## Installation

Add this line to your application's Gemfile:

    gem 'preservation'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install preservation

## Usage

### Configuration
Configure Preservation. If ```log_path``` is omitted, logging (standard library) redirects to STDOUT.

```ruby
  Preservation.configure do |config|
    config.db_path     = ENV['ARCHIVEMATICA_DB_PATH']
    config.ingest_path = ENV['ARCHIVEMATICA_INGEST_PATH']
    config.log_path    = ENV['PRESERVATION_LOG_PATH']
  end
```

Configure data source.

```ruby
Puree.configure do |config|
  config.base_url   = ENV['PURE_BASE_URL']
  config.username   = ENV['PURE_USERNAME']
  config.password   = ENV['PURE_PASSWORD']
  config.basic_auth = true
end
```

### Transfers

Get some dataset UUIDs for preservation.

```ruby
c = Puree::Collection.new resource: :dataset
minimal_metadata = c.find limit: 2,
                          offset: 10,
                          full: false
uuids = []
minimal_metadata.each do |i|
  uuids << i['uuid']
end
```

Create an ingestor for Pure.

```ruby
ingest = Preservation::PureIngest.new
```

For each uuid, if necessary, fetch the metadata, prepare
a directory in the ingest path and populate it with the files and JSON description file.

```ruby
ingest.prepare_dataset uuids: uuids,
                       dir_name_scheme: :doi_short,
                       delay: 0
```

Free up disk space for completed transfers.

```ruby
ingest.cleanup_preserved
```

### Reporting
Can be used for scheduled monitoring of transfers.

```ruby
report = Preservation::IngestReport.new
report.transfer_exception
```

## Documentation
[API in YARD](http://www.rubydoc.info/gems/preservation)