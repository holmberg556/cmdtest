#!/usr/bin/ruby

require "fileutils"

src = ARGV[0]
tgt = ARGV[1]

if ! File.file?(src)
    puts "cp.rb: error: no such file: #{src}"
    exit(1)
end

FileUtils.cp(src, tgt)

