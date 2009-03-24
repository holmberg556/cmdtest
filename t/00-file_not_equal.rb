#======================================================================
# test file_not_equal

#-----------------------------------
# file_not_equal -- correct ""

File.open("foo", "w") {|f| f.puts "hello" }

cmd "true.rb" do
    file_not_equal "foo", ""
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# file_not_equal -- incorrect ""

File.open("foo", "w") {}

cmd "true.rb" do
    file_not_equal "foo", ""
end

# stdout begin
# ### true.rb
# --- ERROR: wrong file 'foo'
# ---        actual: [[empty]]
# ---        expect: [[empty]]
# stdout end

