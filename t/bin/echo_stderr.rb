#!/usr/bin/ruby

if ARGV.size > 0 && ARGV[0] == "--lines"
    for arg in ARGV[1..-1]
        STDERR.puts arg
    end
else
    STDERR.puts ARGV.join(" ")
end
