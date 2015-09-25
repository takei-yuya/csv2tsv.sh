#!/usr/bin/env ruby

require 'csv'

CSV.open("sample.csv").each do |r|
  puts r.map{ |c| (c || "").gsub(/\t/,'\\t').gsub(/\n/,'\\n') }.join("\t")
end
