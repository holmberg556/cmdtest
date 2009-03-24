#======================================================================
# test stderr_not_equal

#-----------------------------------
# stderr_not_equal -- correct ""

cmd "echo.rb hello >&2" do
    stderr_not_equal ""
end

# stdout begin
# ### echo.rb hello >&2
# stdout end

#-----------------------------------
# stderr_not_equal -- incorrect ""

cmd "true.rb" do
    stderr_not_equal ""
end

# stdout begin
# ### true.rb
# --- ERROR: wrong stderr
# ---        actual: [[empty]]
# ---        expect: [[empty]]
# stdout end

#-----------------------------------
# stderr_not_equal -- correct []

cmd "echo.rb hello >&2" do
    stderr_not_equal []
end

# stdout begin
# ### echo.rb hello >&2
# stdout end

#-----------------------------------
# stderr_not_equal -- incorrect []

cmd "true.rb" do
    stderr_not_equal []
end

# stdout begin
# ### true.rb
# --- ERROR: wrong stderr
# ---        actual: [[empty]]
# ---        expect: [[empty]]
# stdout end

#-----------------------------------
# stderr_not_equal -- correct [ "hello world" ]

cmd "echo.rb not hello world >&2" do
    stderr_not_equal [ "hello world" ]
end

# stdout begin
# ### echo.rb not hello world >&2
# stdout end

#-----------------------------------
# stderr_not_equal -- incorrect [ "hello world" ]

cmd "echo.rb hello world >&2" do
    stderr_not_equal [ "hello world" ]
end

# stdout begin
# ### echo.rb hello world >&2
# --- ERROR: wrong stderr
# ---        actual: hello world
# ---        expect: hello world
# stdout end

#-----------------------------------
# stderr_not_equal -- correct [ "hello", "world" ]

cmd "echo.rb hello world >&2" do
    stderr_not_equal [ "hello", "world" ]
end

# stdout begin
# ### echo.rb hello world >&2
# stdout end

#-----------------------------------
# stderr_not_equal -- incorrect [ "hello", "world" ]

cmd "echo.rb hello >&2 && echo.rb world >&2" do
    stderr_not_equal [ "hello", "world" ]
end

# stdout begin
# ### echo.rb hello >&2 && echo.rb world >&2
# --- ERROR: wrong stderr
# ---        actual: hello
# ---                world
# ---        expect: hello
# ---                world
# stdout end

