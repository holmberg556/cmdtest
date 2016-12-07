#!/usr/bin/ruby

for arg in ARGV
  if arg =~ /^(\d+):(\d+)$/
    a = Integer($1)
    b = Integer($2)
    for i in a...b
      puts "--- %s --- %s ---" % ["^" + (i+64).chr, i.chr]
    end
  end
end

