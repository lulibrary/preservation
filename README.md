# Preservation [![Gem Version](https://badge.fury.io/rb/preservation.svg)](https://badge.fury.io/rb/preservation) [![GitPitch](https://gitpitch.com/assets/badge.svg)](https://gitpitch.com/lulibrary/preservation/master?grs=github&t=sky)

Extraction and Transformation in preparation for Loading by Archivematica's Automation Tools.

## Installation

Add this line to your application's Gemfile:

    gem 'preservation'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install preservation

## Usage

### Configuration
Configure Preservation. If ```log_path``` is omitted, logging (standard library) writes to STDOUT.

```ruby
Preservation.configure do |config|
  config.db_path     = ENV['ARCHIVEMATICA_DB_PATH']
  config.ingest_path = ENV['ARCHIVEMATICA_INGEST_PATH']
  config.log_path    = ENV['PRESERVATION_LOG_PATH']
end
```


### Transfer
Create a transfer using Pure Research Information System as a data source.

```ruby
transfer = Preservation::Transfer::Pure.new base_url:   ENV['PURE_BASE_URL'],
                                            username:   ENV['PURE_USERNAME'],
                                            password:   ENV['PURE_PASSWORD'],
                                            basic_auth: true
```

For a Pure dataset, if necessary, fetch the metadata, prepare
a directory in the ingest path and populate it with the files and JSON description file.

```ruby
transfer.prepare_dataset uuid:       uuid,
                         dir_scheme: :doi_short,
                         delay:      100
```

Free up disk space for completed transfers. Can be done at any time.

```ruby
transfer.cleanup
```

### Report
Can be used for scheduled monitoring of transfers.

```ruby
Preservation::Report::Transfer.new.exception
```

## Documentation
[API in YARD](http://www.rubydoc.info/gems/preservation)