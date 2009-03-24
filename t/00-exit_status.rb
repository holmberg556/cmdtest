#======================================================================
# test exit_status

#-----------------------------------
# exit_status -- correct 0

cmd "true.rb" do
    exit_status 0
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# exit_status -- incorrect 0

cmd "false.rb" do
    exit_status 0
end

# stdout begin
# ### false.rb
# --- ERROR: expected 0 exit status, got 1
# stdout end

#-----------------------------------
# exit_status -- correct 18

cmd "exit.rb 18" do
    exit_status 18
end

# stdout begin
# ### exit.rb 18
# stdout end

#-----------------------------------
# exit_status -- incorrect 18

cmd "exit.rb 10" do
    exit_status 18
end

# stdout begin
# ### exit.rb 10
# --- ERROR: expected 18 exit status, got 10
# stdout end

