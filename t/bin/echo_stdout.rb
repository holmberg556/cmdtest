#!/usr/bin/ruby

if ARGV.size > 0 && ARGV[0] == "--lines"
    for arg in ARGV[1..-1]
        puts arg
    end
else
    puts ARGV.join(" ")
end
