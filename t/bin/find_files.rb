#!/usr/bin/ruby

require "find"

files = []
Find.find('.') do |path|
    if File.file?(path)
        files << path
    end
end

puts files.sort
