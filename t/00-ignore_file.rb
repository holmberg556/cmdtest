#======================================================================
# test ignore_file

#-----------------------------------
# ignore_file -- actually created

ignore_file "bbb"

cmd "touch.rb bbb" do
end

# stdout begin
# ### touch.rb bbb
# stdout end

#-----------------------------------
# ignore_file -- not created

ignore_file "aaa"

cmd "touch.rb bbb" do
end

# stdout begin
# ### touch.rb bbb
# --- ERROR: created files
# ---        actual: ["bbb"]
# ---        expect: []
# stdout end

#-----------------------------------
# ignore_file -- in subdir + ok

ignore_file "dir/bbb"
Dir.mkdir "dir"

cmd "touch.rb dir/bbb" do
end

# stdout begin
# ### touch.rb dir/bbb
# stdout end

#-----------------------------------
# ignore_file -- in subdir + error

ignore_file "bbb"
Dir.mkdir "dir"

cmd "touch.rb dir/bbb" do
end

# stdout begin
# ### touch.rb dir/bbb
# --- ERROR: created files
# ---        actual: ["dir/bbb"]
# ---        expect: []
# stdout end

