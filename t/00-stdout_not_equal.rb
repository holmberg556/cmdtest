#======================================================================
# test stdout_not_equal

#-----------------------------------
# stdout_not_equal -- correct ""

cmd "echo.rb hello" do
    stdout_not_equal ""
end

# stdout begin
# ### echo.rb hello
# stdout end

#-----------------------------------
# stdout_not_equal -- incorrect ""

cmd "true.rb" do
    stdout_not_equal ""
end

# stdout begin
# ### true.rb
# --- ERROR: wrong stdout
# ---        actual: [[empty]]
# ---        expect: [[empty]]
# stdout end

#-----------------------------------
# stdout_not_equal -- correct []

cmd "echo.rb hello" do
    stdout_not_equal []
end

# stdout begin
# ### echo.rb hello
# stdout end

#-----------------------------------
# stdout_not_equal -- incorrect []

cmd "true.rb" do
    stdout_not_equal []
end

# stdout begin
# ### true.rb
# --- ERROR: wrong stdout
# ---        actual: [[empty]]
# ---        expect: [[empty]]
# stdout end

#-----------------------------------
# stdout_not_equal -- correct [ "hello world" ]

cmd "echo.rb not hello world" do
    stdout_not_equal [ "hello world" ]
end

# stdout begin
# ### echo.rb not hello world
# stdout end

#-----------------------------------
# stdout_not_equal -- incorrect [ "hello world" ]

cmd "echo.rb hello world" do
    stdout_not_equal [ "hello world" ]
end

# stdout begin
# ### echo.rb hello world
# --- ERROR: wrong stdout
# ---        actual: hello world
# ---        expect: hello world
# stdout end

#-----------------------------------
# stdout_not_equal -- correct [ "hello", "world" ]

cmd "echo.rb hello world" do
    stdout_not_equal [ "hello", "world" ]
end

# stdout begin
# ### echo.rb hello world
# stdout end

#-----------------------------------
# stdout_not_equal -- incorrect [ "hello", "world" ]

cmd "echo.rb hello && echo.rb world" do
    stdout_not_equal [ "hello", "world" ]
end

# stdout begin
# ### echo.rb hello && echo.rb world
# --- ERROR: wrong stdout
# ---        actual: hello
# ---                world
# ---        expect: hello
# ---                world
# stdout end

