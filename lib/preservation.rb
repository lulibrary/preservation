require 'date'
require 'fileutils'
require 'free_disk_space'
require 'logger'
require 'puree'
require 'sqlite3'
require 'preservation/configuration'
require 'preservation/ingest_report'
require 'preservation/ingest'
require 'preservation/pure_ingest'
require 'preservation/string_util'
require 'preservation/version'

# Top level namespace
#
module Preservation

  class << self

    include Preservation::Configuration

  end

end