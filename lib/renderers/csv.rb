# frozen_string_literal: true
require_relative "./csv_options"

module Renderers
  module CSV
    ActionController::Renderers.add :csv do |collection, options|
      exporter, filename, type = Renderers::CSVOptions.new(options).attributes
      send_data(exporter.content(collection), type: type, filename: filename)
    end
  end
end
