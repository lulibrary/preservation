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

##  Preservation: ingest

Create an ingestor for Pure.
```ruby
ingest = Preservation::PureIngest.new
```

For each uuid, if necessary, fetch the metadata, prepare a directory in the
ingest path and populate it with the files and JSON description file.

```ruby
ingest.prepare_dataset uuids: uuids,
                       dir_name_scheme: :doi_short,
                       delay: 0
```

Free up disk space for completed transfers.

```ruby
ingest.cleanup_preserved
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
    "related": [
      {
        "dc.title": "The unprecedented scale of the West African Ebola virus disease outbreak is due to environmental and sociological factors, not special attributes of the currently circulating strain of the virus",
        "type": "Journal article",
        "dc.identifier": "http://dx.doi.org/10.1136/ebmed-2014-110127"
      },
      {
        "dc.title": "The 2014 Ebola virus disease outbreak in West Africa",
        "type": "Journal article",
        "dc.identifier": "http://dx.doi.org/10.1099/vir.0.067199-0"
      }
    ]
  }
]
```

#HSLIDE

##  Preservation: reporting

Can be used for scheduled monitoring of transfers.

```ruby
report = Preservation::IngestReport.new
report.transfer_exception
```

#HSLIDE

## Location

<a href="https://rubygems.org/gems/preservation" target="_blank">RubyGems</a>

<a href="https://github.com/lulibrary/preservation" target="_blank">GitHub</a>

#HSLIDE

## Documentation

<a href="http://www.rubydoc.info/gems/preservation" target="_blank">API in YARD</a>