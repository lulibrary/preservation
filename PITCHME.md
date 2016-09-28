#HSLIDE

## Rationale
Archivematica's <a href="https://github.com/artefactual/automation-tools" target="_blank">Automation Tools</a>
work with files and descriptive metadata which must be provided in a certain way.

#HSLIDE

## Preservation: a way to manage ingest

#VSLIDE

- Transfer preparation.
- Reporting from transfers database. <!-- .element: class="fragment" -->
- Disk space management. <!-- .element: class="fragment" -->

#HSLIDE

##  Preservation: transfer

Create a transfer using the Pure Research Information System as a data source.

```ruby
transfer = Preservation::Transfer::Pure.new base_url:   ENV['PURE_BASE_URL'],
                                            username:   ENV['PURE_USERNAME'],
                                            password:   ENV['PURE_PASSWORD'],
                                            basic_auth: true
```

For a Pure dataset, if necessary, fetch the metadata, prepare
a directory in the ingest path and populate it with the files and JSON description file.

```ruby
transfer.prepare_dataset uuid: 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
```

Free up disk space for completed transfers. Can be done at any time.

```ruby
Preservation::Storage.cleanup
```

#VSLIDE

## Transfer-ready directory
```
.
├── 10.17635-lancaster-researchdata-6
│   ├── Ebola_data_Jun15.zip
│   └── metadata
│       └── metadata.json
```

#VSLIDE

## Transfer-ready metadata

```json
[
  {
    "filename": "objects/Ebola_data_Jun15.zip",
    "dc.title": "Ebolavirus evolution 2013-2015",
    "dc.description": "Data used for analysis of selection and evolutionary rate in Zaire Ebolavirus variant Makona",
    "dcterms.created": "2015-06-04T16:11:34.713+01:00",
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

#HSLIDE

##  Preservation: reporting

Can be used for scheduled monitoring of transfers.

```ruby
Preservation::Report::Transfer.exception
```

#HSLIDE

## Location

<a href="https://rubygems.org/gems/preservation" target="_blank">RubyGems</a>

<a href="https://github.com/lulibrary/preservation" target="_blank">GitHub</a>

#HSLIDE

## Documentation

<a href="http://www.rubydoc.info/gems/preservation" target="_blank">API in YARD</a>

<a href="https://aalbinclark.gitbooks.io/preservation" target="_blank">Detailed usage in GitBook</a>