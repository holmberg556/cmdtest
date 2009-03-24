#======================================================================
# test import_file

#-----------------------------------
# import_file -- different dirs

import_file "file1.txt", "qwerty1.txt"
import_file "file2.txt", "subdir/qwerty2.txt"

cmd "cat.rb qwerty1.txt subdir/qwerty2.txt > qwerty3.txt" do
    created_files "qwerty3.txt"
end

# stdout begin
# ### cat.rb qwerty1.txt subdir/qwerty2.txt > qwerty3.txt
# stdout end

#-----------------------------------
# import_file -- after chdir

Dir.mkdir("dir")
Dir.chdir("dir")
import_file "file1.txt", "qwerty1.txt"
import_file "file2.txt", "subdir/qwerty2.txt"

cmd "cat.rb qwerty1.txt subdir/qwerty2.txt > qwerty3.txt" do
    created_files "dir/qwerty3.txt"
end

# stdout begin
# ### cat.rb qwerty1.txt subdir/qwerty2.txt > qwerty3.txt
# stdout end

