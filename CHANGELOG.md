# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## Unreleased

## 0.5.0 - 2017-05-23
### Changed
- Transfer - created as ISO8601 date format.

### Fixed
- Transfer - handling DOIs of related works for both datasets and publications.
- Transfer - handling missing DOIs of related works.

## 0.4.2 - 2017-05-18
### Fixed
- Transfer - presence check for DOI of a related work.

## 0.4.1 - 2016-09-30
### Fixed
- Reporting - pending transfers false positives.

## 0.4.0 - 2016-09-30
### Added
- Transfer - prepare batches of datasets.
- Reporting - pending transfers.

## 0.2.2 - 2016-09-28
### Fixed
- Transfer - related work as simple array in metadata.

## 0.2.1 - 2016-09-26
### Fixed
- Reporting - handling nulls in database.
- Reporting - namespace for hex/bin conversion.

## 0.2.0 - 2016-09-18
### Changed
- Singular uuid rather than an array of uuids as parameter for transfer preparation.
- Modules, classes and API.

## 0.1.0 - 2016-09-13
### Added
- Transfer preparation.
- Reporting from transfers database.
- Disk space management.