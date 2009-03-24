#!/usr/bin/ruby

require "fileutils"

for file in ARGV
    FileUtils.touch(file)
end

