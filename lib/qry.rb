require 'forwardable'
require 'icy'
require 'ivo'
require 'sequel'

Sequel.default_timezone = :utc

module Qry
  extend self

  def connect(**args)
    instrumenter = args.delete(:instrumenter) || NullInstrumenter.new

    sequel_args = if args.key?(:url)
      url = args.delete(:url)
      [url, args]
    else
      [args]
    end

    if block_given?
      Sequel.connect(*sequel_args) do |sequel_db|
        yield Interface.with(
          sequel_db: sequel_db,
          instrumenter: instrumenter,
        )
      end
    else
      Interface.with(
        sequel_db: Sequel.connect(*sequel_args),
        instrumenter: instrumenter,
      )
    end
  end
end

if defined? ::Rails
  require 'qry/rails'
else
  Icy.require_tree('qry', exclude: [
    'qry/rails',
    'qry/rails.rb',
    'qry/manager.rb',
  ])
end
