#!/usr/bin/env ruby

File.open('tmp-ΑΒΓ-αβγ-א-Њ-åäöÅÄÖ.txt', 'w', encoding: 'UTF-8') do |f|
    f.puts 'this is tmp-ΑΒΓ-αβγ-א-Њ-åäöÅÄÖ.txt'
end
