
#-----------------------------------
# try to run non-existing command
#
# REQUIRE: RUBY_PLATFORM !~ /mswin32/

cmd "non-existing" do
    exit_nonzero
    stderr_equal /non-existing: .*not found/
end

# stdout begin
# ### non-existing
# stdout end

#-----------------------------------
# try to run non-existing command
#
# REQUIRE: RUBY_PLATFORM =~ /mswin32/

cmd "non-existing" do
    exit_nonzero
    stderr_equal [
        /non-existing.*not recognized/,
        /program or batch file/,
    ]
end

# stdout begin
# ### non-existing
# stdout end

#-----------------------------------
# FAILING try to run non-existing command
#
# REQUIRE: RUBY_PLATFORM !~ /mswin32/

cmd "non-existing" do
end

# stdout begin
# ### non-existing
# --- ERROR: expected zero exit status, got 127
# --- ERROR: wrong stderr
#/---        actual:.*non-existing: .*not found
# ---        expect: [[empty]]
# stdout end

#-----------------------------------
# FAILING try to run non-existing command
#
# REQUIRE: RUBY_PLATFORM =~ /mswin32/

cmd "non-existing" do
end

# stdout begin
# ### non-existing
# --- ERROR: expected zero exit status, got 1
# --- ERROR: wrong stderr
#/---        actual:.*non-existing.*not recognized
#/---               .*program or batch file
# ---        expect: [[empty]]
# stdout end

#-----------------------------------
# "true.rb" is archetypic command: zero exit status, no output

cmd "true.rb" do
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# true - explicit exit_zero

cmd "true.rb" do
    exit_zero
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# true - incorrect exit_nonzero

cmd "true.rb" do
    exit_nonzero
end

# stdout begin
# ### true.rb
# --- ERROR: expected nonzero exit status
# stdout end

#-----------------------------------
# true - incorrect exit_status

cmd "true.rb" do
    exit_status 18
end

# stdout begin
# ### true.rb
# --- ERROR: expected 18 exit status, got 0
# stdout end

#-----------------------------------
# true - correct exit_status

cmd "true.rb" do
    exit_status 0
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# true - incorrect stdout

cmd "true.rb" do
    stdout_equal ["hello"]
end

# stdout begin
# ### true.rb
# --- ERROR: wrong stdout
# ---        actual: [[empty]]
# ---        expect: hello
# stdout end

#-----------------------------------
# true - correct stdout

cmd "true.rb" do
    stdout_equal []
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# true - incorrect stderr

cmd "true.rb" do
    stderr_equal ["hello"]
end

# stdout begin
# ### true.rb
# --- ERROR: wrong stderr
# ---        actual: [[empty]]
# ---        expect: hello
# stdout end

#-----------------------------------
# true - correct stderr

cmd "true.rb" do
    stderr_equal []
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# true - incorrect created_files

cmd "true.rb" do
    created_files "foo"
end

# stdout begin
# ### true.rb
# --- ERROR: created files
# ---        actual: []
# ---        expect: ["foo"]
# stdout end

#-----------------------------------
# true - incorrect created_files

cmd "true.rb" do
    created_files "foo", "bar"
end

# stdout begin
# ### true.rb
# --- ERROR: created files
# ---        actual: []
# ---        expect: ["bar", "foo"]
# stdout end

#-----------------------------------
# true - correct created_files

cmd "true.rb" do
    created_files
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# true - incorrect changed_files

cmd "true.rb" do
    changed_files "foo"
end

# stdout begin
# ### true.rb
# --- ERROR: changed files
# ---        actual: []
# ---        expect: ["foo"]
# stdout end

#-----------------------------------
# true - incorrect changed_files

cmd "true.rb" do
    changed_files "foo", "bar"
end

# stdout begin
# ### true.rb
# --- ERROR: changed files
# ---        actual: []
# ---        expect: ["bar", "foo"]
# stdout end

#-----------------------------------
# true - correct changed_files

cmd "true.rb" do
    changed_files
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# true - incorrect removed_files

cmd "true.rb" do
    removed_files "foo"
end

# stdout begin
# ### true.rb
# --- ERROR: removed files
# ---        actual: []
# ---        expect: ["foo"]
# stdout end

#-----------------------------------
# true - incorrect removed_files

cmd "true.rb" do
    removed_files "foo", "bar"
end

# stdout begin
# ### true.rb
# --- ERROR: removed files
# ---        actual: []
# ---        expect: ["bar", "foo"]
# stdout end

#-----------------------------------
# true - correct removed_files

cmd "true.rb" do
    removed_files
end

# stdout begin
# ### true.rb
# stdout end

#======================================================================
# test - without assertions

#-----------------------------------
# without assertions -- correct

cmd "true.rb" do
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# without assertions -- incorrect exit status

cmd "false.rb" do
end

# stdout begin
# ### false.rb
# --- ERROR: expected zero exit status, got 1
# stdout end

#-----------------------------------
# without assertions -- incorrect stdout

cmd "echo.rb hello" do
end

# stdout begin
# ### echo.rb hello
# --- ERROR: wrong stdout
# ---        actual: hello
# ---        expect: [[empty]]
# stdout end

#-----------------------------------
# without assertions -- incorrect stderr

cmd "echo.rb hello >&2" do
end

# stdout begin
# ### echo.rb hello >&2
# --- ERROR: wrong stderr
# ---        actual: hello
# ---        expect: [[empty]]
# stdout end

#-----------------------------------
# without assertions -- incorrect created_files

cmd "touch.rb new_file" do
end

# stdout begin
# ### touch.rb new_file
# --- ERROR: created files
# ---        actual: ["new_file"]
# ---        expect: []
# stdout end

#-----------------------------------
# without assertions -- incorrect changed_files

touch_file "changed_file"
cmd "echo.rb ... >> changed_file" do
end

# stdout begin
# ### echo.rb ... >> changed_file
# --- ERROR: changed files
# ---        actual: ["changed_file"]
# ---        expect: []
# stdout end

#-----------------------------------
# without assertions -- incorrect removed_files

touch_file "removed_file"
cmd "rm.rb removed_file" do
end

# stdout begin
# ### rm.rb removed_file
# --- ERROR: removed files
# ---        actual: ["removed_file"]
# ---        expect: []
# stdout end

