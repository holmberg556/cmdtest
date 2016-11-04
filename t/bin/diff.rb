#!/usr/bin/ruby

a = File.read(ARGV[0], encoding: 'BINARY')
b = File.read(ARGV[1], encoding: 'BINARY')
if a == b
    exit(0)
else
    puts "file differ: %s and %s" % [ARGV[0], ARGV[1]]
    exit(1)
end
