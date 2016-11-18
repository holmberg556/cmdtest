#!/usr/bin/ruby

out = STDOUT

for line in ARGV
    case line
    when "--stdout"
        out = STDOUT
    when "--stderr"
        out = STDERR
    else
        out.puts(line)
    end
end
