#!/usr/bin/ruby

pattern = Regexp.new(ARGV[0])

n = 0
for line in STDIN
    if line =~ pattern
	puts line
	n += 1
    end
end

exit(n == 0 ? 1 : 0)
