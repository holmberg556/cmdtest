#======================================================================
# test exit_zero

#-----------------------------------
# exit_zero -- correct

cmd "true.rb" do
    exit_zero
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# exit_zero -- incorrect

cmd "false.rb" do
    exit_zero
end

# stdout begin
# ### false.rb
# --- ERROR: expected zero exit status, got 1
# stdout end

#-----------------------------------
# exit_zero -- incorrect 18

cmd "exit.rb 18" do
    exit_zero
end

# stdout begin
# ### exit.rb 18
# --- ERROR: expected zero exit status, got 18
# stdout end

