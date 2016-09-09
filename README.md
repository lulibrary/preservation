# Preservation

Ingest management for Archivematica's [Automation Tools](https://github.com/artefactual/automation-tools).

## Installation

Add this line to your application's Gemfile:

    gem 'preservation'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install preservation

## Usage

### Reporting
```ruby
ingest_report = Preservation::IngestReport.new db_path: ENV['ARCHIVEMATICA_DB_PATH']
transfer_report = ingest_report.transfer_report
```

### Transfers
If ```log_path``` is omitted, logging (standard library) redirects to STDOUT.

```ruby
ingest = Preservation::PureIngest.new ingest_path: ENV['ARCHIVEMATICA_INGEST_PATH'],
                                      db_path:     ENV['ARCHIVEMATICA_DB_PATH'],
                                      log_path:    ENV['ARCHIVEMATICA_LOG_PATH']
```

Configure HTTP data source.

```ruby
Puree.configure do |config|
  config.base_url   = ENV['PURE_BASE_URL']
  config.username   = ENV['PURE_USERNAME']
  config.password   = ENV['PURE_PASSWORD']
  config.basic_auth = true
end
```

Free up disk space for completed transfers.

```ruby
ingest.cleanup_preserved
```

Fetch a batch of dataset metadata records. For each one, if necessary, prepare
a directory in the ingest path and populate it with the files and JSON description file.

```ruby
ingest.prepare_batch limit:             100,
                     offset:            5,
                     max_to_prepare:    1,
                     dir_name_scheme:   :doi_short,
                     days_until_time_to_preserve:   100
```

## Documentation
[API in YARD](http://www.rubydoc.info/gems/preservation)