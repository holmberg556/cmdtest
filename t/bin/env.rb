#!/usr/bin/ruby

for k in ENV.keys.sort
    puts("%s=%s" % [k, ENV[k]])
end

