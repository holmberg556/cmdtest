#======================================================================
# test stderr_equal

#-----------------------------------
# stderr_equal -- correct ""

cmd "true.rb" do
    stderr_equal ""
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# stderr_equal -- incorrect ""

cmd "echo.rb hello world >&2" do
    stderr_equal ""
end

# stdout begin
# ### echo.rb hello world >&2
# --- ERROR: wrong stderr
# ---        actual: hello world
# ---        expect: [[empty]]
# stdout end

#-----------------------------------
# stderr_equal -- correct []

cmd "true.rb" do
    stderr_equal []
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# stderr_equal -- incorrect []

cmd "echo.rb hello world >&2" do
    stderr_equal []
end

# stdout begin
# ### echo.rb hello world >&2
# --- ERROR: wrong stderr
# ---        actual: hello world
# ---        expect: [[empty]]
# stdout end

#-----------------------------------
# stderr_equal -- correct [ "hello world" ]

cmd "echo.rb hello world >&2" do
    stderr_equal [ "hello world" ]
end

# stdout begin
# ### echo.rb hello world >&2
# stdout end

#-----------------------------------
# stderr_equal -- incorrect [ "hello world" ]

cmd "true.rb" do
    stderr_equal [ "hello world" ]
end

# stdout begin
# ### true.rb
# --- ERROR: wrong stderr
# ---        actual: [[empty]]
# ---        expect: hello world
# stdout end

#-----------------------------------
# stderr_equal -- correct [ "hello", "world" ]

cmd "echo.rb hello >&2 && echo.rb world >&2" do
    stderr_equal [ "hello", "world" ]
end

# stdout begin
# ### echo.rb hello >&2 && echo.rb world >&2
# stdout end

#-----------------------------------
# stderr_equal -- incorrect [ "hello", "world" ]

cmd "true.rb" do
    stderr_equal [ "hello", "world" ]
end

# stdout begin
# ### true.rb
# --- ERROR: wrong stderr
# ---        actual: [[empty]]
# ---        expect: hello
# ---                world
# stdout end

