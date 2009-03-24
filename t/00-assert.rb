#======================================================================
# test assert

#-----------------------------------
# assert -- correct

cmd "true.rb" do
    assert true
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# assert -- incorrect

cmd "true.rb" do
    assert false
end

# stdout begin
# ### true.rb
# --- ERROR: assertion failed
# stdout end

#-----------------------------------
# assert -- incorrect with msg

cmd "true.rb" do
    assert false, "got false"
end

# stdout begin
# ### true.rb
# --- ERROR: assertion: got false
# stdout end

