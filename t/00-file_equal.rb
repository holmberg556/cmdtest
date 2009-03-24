#======================================================================
# test file_equal

#-----------------------------------
# file_equal -- correct ""

File.open("foo", "w") {}

cmd "true.rb" do
    file_equal "foo", ""
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# file_equal -- incorrect ""

File.open("foo", "w") {|f| f.puts "hello world" }

cmd "true.rb" do
    file_equal "foo", ""
end

# stdout begin
# ### true.rb
# --- ERROR: wrong file 'foo'
# ---        actual: hello world
# ---        expect: [[empty]]
# stdout end

#-----------------------------------
# file_equal -- correct []

File.open("foo", "w") {}

cmd "true.rb" do
    file_equal "foo", []
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# file_equal -- incorrect []

File.open("foo", "w") {|f| f.puts "hello world" }

cmd "true.rb" do
    file_equal "foo", []
end

# stdout begin
# ### true.rb
# --- ERROR: wrong file 'foo'
# ---        actual: hello world
# ---        expect: [[empty]]
# stdout end

#-----------------------------------
# file_equal -- correct [ "hello world" ]

File.open("foo", "w") {|f| f.puts "hello world" }

cmd "true.rb" do
    file_equal "foo", [ "hello world" ]
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# file_equal -- incorrect [ "hello world" ]

File.open("foo", "w") {}

cmd "true.rb" do
    file_equal "foo", [ "hello world" ]
end

# stdout begin
# ### true.rb
# --- ERROR: wrong file 'foo'
# ---        actual: [[empty]]
# ---        expect: hello world
# stdout end

#-----------------------------------
# file_equal -- correct [ "hello", "world" ]

File.open("foo", "w") {|f| f.puts "hello"; f.puts "world" }

cmd "true.rb" do
    file_equal "foo", [ "hello", "world" ]
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# file_equal -- incorrect [ "hello", "world" ]

File.open("foo", "w") {}

cmd "true.rb" do
    file_equal "foo", [ "hello", "world" ]
end

# stdout begin
# ### true.rb
# --- ERROR: wrong file 'foo'
# ---        actual: [[empty]]
# ---        expect: hello
# ---                world
# stdout end

#-----------------------------------
# file_equal -- non-existing file

cmd "true.rb" do
    file_equal "foo", ""
end

# stdout begin
# ### true.rb
# --- ERROR: no such file: 'foo'
# stdout end

#-----------------------------------
# file_equal -- file is directory

Dir.mkdir "foo"

cmd "true.rb" do
    file_equal "foo", ""
end

# stdout begin
# ### true.rb
# --- ERROR: is a directory: 'foo'
# stdout end

#-----------------------------------
# file_equal -- other error
# SKIP mswin32

File.symlink "foo", "foo"

cmd "true.rb" do
    file_equal "foo", ""
end

# stdout begin
# ### true.rb
# --- ERROR: error reading file: 'foo'
# stdout end

