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

cmd ["lines.rb", "emb\"edded1", "emb\\edded2", "emb\\edd\"ed3"] do
    stdout_equal [
        "emb\"edded1",
        "emb\\edded2",
        "emb\\edd\"ed3",
    ]
end

# stdout begin
# ### lines.rb "emb\"edded1" "emb\edded2" "emb\edd\"ed3"
# stdout end

#-----------------------------------
# array with $ arguments

cmd ["lines.rb", "emb$edded1", "emb$$edded2"] do
    stdout_equal [
        "emb$edded1",
        "emb$$edded2",
    ]
end

# stdout begin
# ### lines.rb "emb\$edded1" "emb\$\$edded2"
# stdout end

#-----------------------------------
# "all" characters (but not ` for now)

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

all = " ` "
cmd ["lines.rb", all] do
    stdout_equal [
        " ` ",
    ]
end

# stdout begin
# ### lines.rb " \` "
# stdout end

