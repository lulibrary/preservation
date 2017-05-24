# Preservation

Extraction from the Pure Research Information System and transformation for
loading by Archivematica.

Includes transfer preparation, reporting and disk space management.

## Status

[![Gem Version](https://badge.fury.io/rb/preservation.svg)](https://badge.fury.io/rb/preservation)
[![Build Status](https://semaphoreci.com/api/v1/aalbinclark/preservation/branches/master/badge.svg)](https://semaphoreci.com/aalbinclark/preservation)
[![Code Climate](https://codeclimate.com/github/lulibrary/preservation/badges/gpa.svg)](https://codeclimate.com/github/lulibrary/preservation)
[![Dependency Status](https://www.versioneye.com/user/projects/5899e0d11e07ae0043969771/badge.svg?style=flat-square)](https://www.versioneye.com/user/projects/5899e0d11e07ae0043969771)
[![GitPitch](https://gitpitch.com/assets/badge.svg)](https://gitpitch.com/lulibrary/preservation)

## Installation

Add this line to your application's Gemfile:

    gem 'preservation'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install preservation

## Usage

### Configuration

Configure Preservation. If ```log_path``` is omitted, logging (standard library)
writes to STDOUT.

```ruby
Preservation.configure do |config|
  config.db_path     = ENV['ARCHIVEMATICA_DB_PATH']
  config.ingest_path = ENV['ARCHIVEMATICA_INGEST_PATH']
  config.log_path    = ENV['PRESERVATION_LOG_PATH']
end
```

Create a hash for passing to a transfer.

```ruby
# Pure host with authentication.
config = {
  url:      ENV['PURE_URL'],
  username: ENV['PURE_USERNAME'],
  password: ENV['PURE_PASSWORD']
}
```

```ruby
# Pure host without authentication.
config = {
  url: ENV['PURE_URL']
}
```

### Transfer

Configure a transfer to retrieve data from a Pure host.

```ruby
transfer = Preservation::Transfer::Dataset.new config
```

#### Single

If necessary, fetch the metadata, prepare a directory in the ingest path and
populate it with the files and JSON description file.

```ruby
transfer.prepare uuid: 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
```

#### Batch

For multiple Pure datasets, if necessary, fetch the metadata, prepare a
directory in the ingest path and populate it with the files and JSON description
file.

A maximum of 10 will be prepared using the doi_short directory naming scheme.
Each dataset will only be prepared if 20 days have elapsed since the metadata
record was last modified.

```ruby
transfer.prepare_batch max: 10,
                       dir_scheme: :doi_short,
                       delay: 20
```

#### Directory name

The following are permitted values for the dir_scheme parameter:

```ruby
:uuid_title
:title_uuid
:date_uuid_title
:date_title_uuid
:date_time_uuid
:date_time_title
:date_time_uuid_title
:date_time_title_uuid
:uuid
:doi
:doi_short
```

#### Load directory

A transfer-ready directory, with a name built according to the directory scheme
specified, in this case doi_short. This particular example has only one file
Ebola_data_Jun15.zip in the dataset.
```
.
├── 10.17635-lancaster-researchdata-6
│   ├── Ebola_data_Jun15.zip
│   └── metadata
│       └── metadata.json
```

metadata.json:

```json
[
  {
    "filename": "objects/Ebola_data_Jun15.zip",
    "dc.title": "Ebolavirus evolution 2013-2015",
    "dc.description": "Data used for analysis of selection and evolutionary rate in Zaire Ebolavirus variant Makona",
    "dcterms.created": "2015-06-04",
    "dcterms.available": "2015-06-04",
    "dc.publisher": "Lancaster University",
    "dc.identifier": "http://dx.doi.org/10.17635/lancaster/researchdata/6",
    "dcterms.spatial": [
      "Guinea, Sierra Leone, Liberia"
    ],
    "dc.creator": [
      "Gatherer, Derek"
    ],
    "dc.contributor": [
      "Robertson, David",
      "Lovell, Simon"
    ],
    "dc.subject": [
      "Ebolavirus",
      "evolution",
      "phylogenetics",
      "virulence",
      "Filoviridae",
      "positive selection"
    ],
    "dcterms.license": "CC BY",
    "dc.relation": [
      "http://dx.doi.org/10.1136/ebmed-2014-110127",
      "http://dx.doi.org/10.1099/vir.0.067199-0"
    ]
  }
]
```

### Storage

Free up disk space for completed transfers. Can be done at any time.

```ruby
Preservation::Storage.cleanup
```

### Report

Can be used for scheduled monitoring of transfers.

```ruby
Preservation::Report::Transfer.exception
```

Formatted as JSON:

```javascript
{
  "pending": {
    "count": 3,
    "data": [
      {
        "path": "10.17635-lancaster-researchdata-72",
        "path_timestamp": "2016-09-29 12:08:58 +0100"
      },
      {
        "path": "10.17635-lancaster-researchdata-74",
        "path_timestamp": "2016-09-29 12:08:59 +0100"
      },
      {
        "path": "10.17635-lancaster-researchdata-75",
        "path_timestamp": "2016-09-29 12:09:00 +0100"
      }
    ]
  },
  "current": {
    "path": "10.17635-lancaster-researchdata-90",
    "unit_type": "ingest",
    "status": "PROCESSING",
    "current": 1,
    "id": 91,
    "uuid": "ebf048c3-0ca8-409c-94cf-ab3e5d97e901",
    "path_timestamp": "2016-09-28 17:09:33 +0100"
  },
  "failed": {
    "count": 0
  },
  "incomplete": {
    "count": 1,
    "data": [
      {
         "path": "10.17635-lancaster-researchdata-90",
         "unit_type": "ingest",
         "status": "PROCESSING",
         "current": 1,
         "id": 91,
         "uuid": "ebf048c3-0ca8-409c-94cf-ab3e5d97e901",
         "path_timestamp": "2016-09-28 17:09:33 +0100"
      }
    ]
  },
  "complete": {
    "count": 78
  }
}
```