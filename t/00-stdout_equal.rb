#======================================================================
# test stdout_equal

#-----------------------------------
# stdout_equal -- correct ""

cmd "true.rb" do
    stdout_equal ""
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# stdout_equal -- incorrect ""

cmd "echo.rb hello world" do
    stdout_equal ""
end

# stdout begin
# ### echo.rb hello world
# --- ERROR: wrong stdout
# ---        actual: hello world
# ---        expect: [[empty]]
# stdout end

#-----------------------------------
# stdout_equal -- correct []

cmd "true.rb" do
    stdout_equal []
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# stdout_equal -- incorrect []

cmd "echo.rb hello world" do
    stdout_equal []
end

# stdout begin
# ### echo.rb hello world
# --- ERROR: wrong stdout
# ---        actual: hello world
# ---        expect: [[empty]]
# stdout end

#-----------------------------------
# stdout_equal -- correct [ "hello world" ]

cmd "echo.rb hello world" do
    stdout_equal [ "hello world" ]
end

# stdout begin
# ### echo.rb hello world
# stdout end

#-----------------------------------
# stdout_equal -- incorrect [ "hello world" ]

cmd "true.rb" do
    stdout_equal [ "hello world" ]
end

# stdout begin
# ### true.rb
# --- ERROR: wrong stdout
# ---        actual: [[empty]]
# ---        expect: hello world
# stdout end

#-----------------------------------
# stdout_equal -- correct [ "hello", "world" ]

cmd "echo.rb hello && echo.rb world" do
    stdout_equal [ "hello", "world" ]
end

# stdout begin
# ### echo.rb hello && echo.rb world
# stdout end

#-----------------------------------
# stdout_equal -- incorrect [ "hello", "world" ]

cmd "true.rb" do
    stdout_equal [ "hello", "world" ]
end

# stdout begin
# ### true.rb
# --- ERROR: wrong stdout
# ---        actual: [[empty]]
# ---        expect: hello
# ---                world
# stdout end

