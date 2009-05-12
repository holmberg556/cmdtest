#======================================================================

#-----------------------------------
# Using Array argument to cmd

cmd ["lines.rb", "this is an argument", "and another"] do
    stdout_equal [
        "this is an argument",
        "and another",
    ]
end

# stdout begin
# ### lines.rb "this is an argument" "and another"
# stdout end

#-----------------------------------
# only some arguments need quoting

cmd ["lines.rb", "arg1", "a r g 2", "<arg3>"] do
    stdout_equal [
        "arg1",
        "a r g 2",
        "<arg3>",
    ]
end

# stdout begin
# ### lines.rb arg1 "a r g 2" "<arg3>"
# stdout end

#-----------------------------------
# array with no arguments

cmd ["true.rb"] do
end

# stdout begin
# ### true.rb
# stdout end

#-----------------------------------
# array with no arguments (II)

cmd ["false.rb"] do
    exit_nonzero
end

# stdout begin
# ### false.rb
# stdout end

#-----------------------------------
# array with " and \ in arguments
#

cmd ["clines", "emb\"edded 1", "emb\\edded 2", "emb\\edd\"ed 3"] do
    stdout_equal [
        "emb\"edded 1",
        "emb\\edded 2",
        "emb\\edd\"ed 3",
    ]
end

# stdout begin
#/### .*clines.*
# stdout end

#-----------------------------------
# array with $ arguments
#

cmd ["clines", "emb$edded 1", "emb$$edded 2"] do
    stdout_equal [
        "emb$edded 1",
        "emb$$edded 2",
    ]
end

# stdout begin
#/### .*clines.*
# stdout end

#-----------------------------------
# array with $ arguments
#
# REQUIRE: RUBY_PLATFORM =~ /mswin32/

cmd ["clines", "emb$edded1", "emb$$edded2"] do
    stdout_equal [
        "emb$edded1",
        "emb$$edded2",
    ]
end

# stdout begin
# ### clines "emb$edded1" "emb$$edded2"
# stdout end

#-----------------------------------
# "all" characters (but not ` for now)
#
# REQUIRE: RUBY_PLATFORM !~ /mswin32/

all = " !\"\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_abcdefghijklmnopqrstuvwxyz{|}~"
cmd ["lines.rb", all] do
    stdout_equal [
        " !\"\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_abcdefghijklmnopqrstuvwxyz{|}~"
    ]
end

# stdout begin
# ### lines.rb " !\"#\$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_abcdefghijklmnopqrstuvwxyz{|}~"
# stdout end

#-----------------------------------
# "`" character
#

all = " ` "
cmd ["lines.rb", all] do
    stdout_equal [
        " ` ",
    ]
end

# stdout begin
#/### .*lines.*
# stdout end

