#======================================================================

#-----------------------------------
# Ruby script called with "ruby -S"

cmd "echo.rb this  is  a  line" do
    stdout_equal "this is a line\n"
end

# stdout begin
# ### echo.rb this  is  a  line
# stdout end

#-----------------------------------
# actual "false.rb" will give error

cmd "true.rb" do
end

cmd "false.rb" do
end

# stdout begin
# ### true.rb
# ### false.rb
# --- ERROR: expected zero exit status, got 1
# stdout end

#-----------------------------------
# actual "false.rb" will give error

cmd "false.rb" do
end

# stdout begin
# ### false.rb
# --- ERROR: expected zero exit status, got 1
# stdout end

#-----------------------------------
# another non-zero exit will give error

cmd "exit.rb 18" do
end

# stdout begin
# ### exit.rb 18
# --- ERROR: expected zero exit status, got 18
# stdout end

#-----------------------------------
# actual STDOUT will give error

cmd "echo.rb a line on stdout" do
end

# stdout begin
# ### echo.rb a line on stdout
# --- ERROR: wrong stdout
# ---        actual: a line on stdout
# ---        expect: [[empty]]
# stdout end

#-----------------------------------
# actual STDERR will give error

cmd "echo.rb a line on stderr 1>&2" do
end

# stdout begin
# ### echo.rb a line on stderr 1>&2
# --- ERROR: wrong stderr
# ---        actual: a line on stderr
# ---        expect: [[empty]]
# stdout end

#-----------------------------------
# existing files is OK

File.open("before1", "w") {}
File.open("before2", "w") {}
cmd "true.rb" do
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# actual created file will give error

cmd "echo.rb content > a-new-file" do
end

# stdout begin
# ### echo.rb content > a-new-file
# --- ERROR: created files
# ---        actual: ["a-new-file"]
# ---        expect: []
# stdout end

#-----------------------------------
# several actual created files will give error

File.open("before1", "w") {}
File.open("before2", "w") {}
cmd "echo.rb x > a && echo.rb x > b" do
end

# stdout begin
# ### echo.rb x > a && echo.rb x > b
# --- ERROR: created files
# ---        actual: ["a", "b"]
# ---        expect: []
# stdout end

#-----------------------------------
# actual removed file will give error

File.open("before", "w") {}
cmd "rm.rb before" do
end

# stdout begin
# ### rm.rb before
# --- ERROR: removed files
# ---        actual: ["before"]
# ---        expect: []
# stdout end

#-----------------------------------
# several actual removed files will give error

File.open("before1", "w") {}
File.open("before2", "w") {}
File.open("before3", "w") {}
cmd "rm.rb before1 before2" do
end

# stdout begin
# ### rm.rb before1 before2
# --- ERROR: removed files
# ---        actual: ["before1", "before2"]
# ---        expect: []
# stdout end

#-----------------------------------
# actual changed files will give error

# NOTE: order of writing/testing is important below

File.open("changed1", "w") {}
File.open("changed2", "w") {}

File.open("script.rb", "w") do |f|
    f.puts "t1 = File.mtime('changed2')"
    f.puts "while File.mtime('changed2') == t1"
    f.puts "    File.open('changed2', 'w') {|f| f.puts 111 }"
    f.puts "    File.open('changed1', 'w') {|f| f.puts 111 }"
    f.puts "end"
end

cmd "ruby script.rb" do
end

# stdout begin
# ### ruby script.rb
# --- ERROR: changed files
# ---        actual: ["changed1", "changed2"]
# ---        expect: []
# stdout end

#-----------------------------------
# mix of actual created/removed files will give error

File.open("before1", "w") {}
File.open("before2", "w") {}
File.open("before3", "w") {}
cmd "rm.rb before1 before2 && echo.rb x > a && echo.rb x > b" do
end

# stdout begin
# ### rm.rb before1 before2 && echo.rb x > a && echo.rb x > b
# --- ERROR: created files
# ---        actual: ["a", "b"]
# ---        expect: []
# --- ERROR: removed files
# ---        actual: ["before1", "before2"]
# ---        expect: []
# stdout end

#-----------------------------------
# mix of "all" errros

File.open("before1", "w") {}
File.open("before2", "w") {}
File.open("before3", "w") {}
File.open("script.rb", "w") do |f|
    f.puts "File.unlink 'before1'"
    f.puts "File.unlink 'before2'"
    f.puts "File.open('a', 'w') {}"
    f.puts "File.open('b', 'w') {}"
    f.puts "STDOUT.puts [11,22,33]"
    f.puts "STDERR.puts [44,55,66]"
    f.puts "exit 39"
end
cmd "ruby script.rb" do
end

# stdout begin
# ### ruby script.rb
# --- ERROR: expected zero exit status, got 39
# --- ERROR: wrong stdout
# ---        actual: 11
# ---                22
# ---                33
# ---        expect: [[empty]]
# --- ERROR: wrong stderr
# ---        actual: 44
# ---                55
# ---                66
# ---        expect: [[empty]]
# --- ERROR: created files
# ---        actual: ["a", "b"]
# ---        expect: []
# --- ERROR: removed files
# ---        actual: ["before1", "before2"]
# ---        expect: []
# stdout end

#-----------------------------------
# removed_files

File.open("file1", "w") {}
File.open("file2", "w") {}

cmd "rm.rb file1" do
    comment "removed_files"
    removed_files "file1"
end

# stdout begin
# ### removed_files
# stdout end

#-----------------------------------
# FAILED removed_files

File.open("file1", "w") {}
File.open("file2", "w") {}

cmd "true.rb" do
    comment "FAILED removed_files"
    removed_files "file1"
end

# stdout begin
# ### FAILED removed_files
# --- ERROR: removed files
# ---        actual: []
# ---        expect: ["file1"]
# stdout end

#-----------------------------------
# changed_files

File.open("file1", "w") {}
File.open("file2", "w") {}

cmd "sleep.rb 1 && touch.rb file1" do
    comment "changed_files"
    changed_files "file1"
end

# stdout begin
# ### changed_files
# stdout end

#-----------------------------------
# FAILED changed_files

File.open("file1", "w") {}
File.open("file2", "w") {}

cmd "true.rb" do
    comment "FAILED changed_files"
    changed_files "file1"
end

# stdout begin
# ### FAILED changed_files
# --- ERROR: changed files
# ---        actual: []
# ---        expect: ["file1"]
# stdout end

#-----------------------------------
# created_files

File.open("file1", "w") {}
File.open("file2", "w") {}

cmd "touch.rb file3" do
    comment "created_files"
    created_files "file3"
end

# stdout begin
# ### created_files
# stdout end

#-----------------------------------
# FAILED created_files

File.open("file1", "w") {}
File.open("file2", "w") {}

cmd "true.rb" do
    comment "FAILED created_files"
    created_files "file3"
end

# stdout begin
# ### FAILED created_files
# --- ERROR: created files
# ---        actual: []
# ---        expect: ["file3"]
# stdout end

#-----------------------------------
# with comment

cmd "true.rb" do
    comment "this-is-the-comment"
end

# stdout begin
# ### this-is-the-comment
# stdout end

#-----------------------------------
# exit_nonzero

cmd "exit.rb 33" do
    comment "exit_nonzero"
    exit_nonzero
end

# stdout begin
# ### exit_nonzero
# stdout end

#-----------------------------------
# FAILING exit_nonzero

cmd "exit.rb 0" do
    comment "failing exit_nonzero"
    exit_nonzero
end

# stdout begin
# ### failing exit_nonzero
# --- ERROR: expected nonzero exit status
# stdout end

#-----------------------------------
# exit_status

cmd "exit.rb 33" do
    comment "exit_status"
    exit_status 33
end

# stdout begin
# ### exit_status
# stdout end

#-----------------------------------
# FAILING exit_status

cmd "exit.rb 44" do
    comment "failing exit_status"
    exit_status 33
end

# stdout begin
# ### failing exit_status
# --- ERROR: expected 33 exit status, got 44
# stdout end

#-----------------------------------
# stdout_equal -- one line

cmd "lines.rb 11" do
    comment "stdout_equal"
    stdout_equal "11\n"
end

# stdout begin
# ### stdout_equal
# stdout end

#-----------------------------------
# FAILING stdout_equal -- one line

cmd "lines.rb 22" do
    comment "stdout_equal"
    stdout_equal "11\n"
end

# stdout begin
# ### stdout_equal
# --- ERROR: wrong stdout
# ---        actual: 22
# ---        expect: 11
# stdout end

#-----------------------------------
# stdout_equal -- two lines

cmd "lines.rb 11 22" do
    comment "stdout_equal"
    stdout_equal "11\n22\n"
end

# stdout begin
# ### stdout_equal
# stdout end

#-----------------------------------
# FAILING stdout_equal -- two lines

cmd "lines.rb 33 44" do
    comment "stdout_equal"
    stdout_equal "11\n22\n"
end

# stdout begin
# ### stdout_equal
# --- ERROR: wrong stdout
# ---        actual: 33
# ---                44
# ---        expect: 11
# ---                22
# stdout end

#-----------------------------------
# stdout_equal(arr) -- two lines

cmd "lines.rb 11 22" do
    comment "stdout_equal"
    stdout_equal ["11", "22"]
end

# stdout begin
# ### stdout_equal
# stdout end

#-----------------------------------
# FAILING stdout_equal(arr) -- two lines

cmd "lines.rb 33 44" do
    comment "stdout_equal"
    stdout_equal ["11", "22"]
end

# stdout begin
# ### stdout_equal
# --- ERROR: wrong stdout
# ---        actual: 33
# ---                44
# ---        expect: 11
# ---                22
# stdout end

#-----------------------------------
# FAILING stdout_equal(arr) -- different # lines

cmd "lines.rb 11 22 33" do
    comment "stdout_equal"
    stdout_equal ["11", "22"]
end

# stdout begin
# ### stdout_equal
# --- ERROR: wrong stdout
# ---        actual: 11
# ---                22
# ---                33
# ---        expect: 11
# ---                22
# stdout end

#-----------------------------------
# stdout_equal -- regexp argument

cmd "lines.rb 11 22" do
    comment "stdout_equal"
    stdout_equal /^22$/
end

# stdout begin
# ### stdout_equal
# stdout end

#-----------------------------------
# stdout_equal -- twice, regexp argument

cmd "lines.rb 11 22" do
    comment "stdout_equal"
    stdout_equal /^22$/
    stdout_equal /^11$/
end

# stdout begin
# ### stdout_equal
# stdout end

#-----------------------------------
# FAILING first, stdout_equal -- twice, regexp argument

cmd "lines.rb 99 22" do
    comment "stdout_equal"
    stdout_equal /^22$/
    stdout_equal /^11$/
end

# stdout begin
# ### stdout_equal
# --- ERROR: wrong stdout
# ---        actual: 99
# ---                22
# ---        expect: (?-mix:^11$)
# stdout end

#-----------------------------------
# FAILING second, stdout_equal -- twice, regexp argument

cmd "lines.rb 11 99" do
    comment "stdout_equal"
    stdout_equal /^22$/
    stdout_equal /^11$/
end

# stdout begin
# ### stdout_equal
# --- ERROR: wrong stdout
# ---        actual: 11
# ---                99
# ---        expect: (?-mix:^22$)
# stdout end

#-----------------------------------
# FAILING stdout_equal -- regexp argument

cmd "lines.rb 11 22" do
    comment "stdout_equal"
    stdout_equal /^\d+ \d+$/
end

# stdout begin
# ### stdout_equal
# --- ERROR: wrong stdout
# ---        actual: 11
# ---                22
# ---        expect: (?-mix:^\d+ \d+$)
# stdout end

#-----------------------------------
# stdout_equal(arr) -- regexp argument

cmd "lines.rb 11 22" do
    comment "stdout_equal"
    stdout_equal ["11", /^22$/]
end

# stdout begin
# ### stdout_equal
# stdout end

#-----------------------------------
# stdout_equal(arr) -- regexp argument (II)

cmd "lines.rb 11 22" do
    comment "stdout_equal"
    stdout_equal ["11", /^\d+$/]
end

# stdout begin
# ### stdout_equal
# stdout end

#-----------------------------------
# FAILING stdout_equal(arr) -- regexp argument

cmd "lines.rb 11 22" do
    comment "stdout_equal"
    stdout_equal ["11", /^\d+ \d+$/]
end

# stdout begin
# ### stdout_equal
# --- ERROR: wrong stdout
# ---        actual: 11
# ---                22
# ---        expect: 11
# ---                (?-mix:^\d+ \d+$)
# stdout end

#======================================================================

#-----------------------------------
# symlinks in tree -- should work
# TODO: this test should be improved to actually trigger the difference
# between lstat/stat in "_update_hardlinks".
#
# REQUIRE: RUBY_PLATFORM !~ /mswin32/

File.symlink "non-existing", "non-existing-link"

File.open("existing", "w") {}
File.symlink "existing", "existing-link"

cmd "true.rb" do
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# file with mtime in future

File.open("future-file", "w") {}
future = Time.now + 86400
File.utime future, future, "future-file"

cmd "true.rb" do
end

# stdout begin
# ### true.rb
# stdout end

