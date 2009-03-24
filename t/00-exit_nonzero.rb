#======================================================================
# test exit_nonzero

#-----------------------------------
# exit_nonzero -- correct

cmd "false.rb" do
    exit_nonzero
end

# stdout begin
# ### false.rb
# stdout end

#-----------------------------------
# exit_nonzero -- correct 18

cmd "exit.rb 18" do
    exit_nonzero
end

# stdout begin
# ### exit.rb 18
# stdout end

#-----------------------------------
# exit_nonzero -- incorrect

cmd "true.rb" do
    exit_nonzero
end

# stdout begin
# ### true.rb
# --- ERROR: expected nonzero exit status
# stdout end

