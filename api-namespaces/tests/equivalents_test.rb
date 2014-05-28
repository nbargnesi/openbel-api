#!/usr/bin/env ruby

require '../lib/storage/redlander.rb'
require '../lib/namespaces/api.rb'

values = []
File.open(ARGV[0], 'r:UTF-8') do |f|
  f.each_line do |line|
    values << line.chomp
  end
end

api = OpenBEL::Namespace::API.new(StorageRedlander.new(:name => "../rdf.db"))
eq = api.find_equivalents(:hgnc, values, :result => :name)
puts eq.size