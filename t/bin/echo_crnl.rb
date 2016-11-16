#!/usr/bin/ruby

STDOUT.binmode

for arg in ARGV
    arg = arg.dup
    if arg.sub!(/:rn$/, "")
        print arg + "\r\n"
    elsif arg.sub!(/:n$/, "")
        print arg + "\n"
    end
end
