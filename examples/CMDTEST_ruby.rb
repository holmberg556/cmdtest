#
# Basic tests of command line options to ruby.
# Run it like:
#
#    $ cmdtest CMDTEST_ruby.rb
#    $ env CMDTEST_RUBY=jruby cmdtest CMDTEST_ruby.rb
#

class CMDTEST_ruby_options < Cmdtest::Testcase

  def ruby
    ENV["CMDTEST_RUBY"] || "ruby"
  end

  #--------------------
  # -Cdirectory     cd to directory, before executing your script

  def test_option_C
    create_file "some/dir/script.rb", [
      'puts "cwd = " + Dir.pwd',
    ]
    cwd = Dir.pwd

    # chdir before script
    cmd "#{ruby} -Csome/dir script.rb" do
      stdout_equal [
        /^cwd = #{cwd}\/some\/dir$/,
      ]
    end

    # non-existing dir ---> error
    cmd "#{ruby} -Cnon/existing script.rb" do
      exit_nonzero
      stderr_equal [
        /Can't chdir/,
      ]
    end
  end

  #--------------------
  # -Fpattern       split() pattern for autosplit (-a)

  def test_option_F
    create_file "file.txt", [
      "123delimiter456 delimiter 789",
      "delimiterHELLOdelimiterWORLD",
    ]
    create_file "script.rb", [
      "p $F",
    ]

    cmd "#{ruby} -na -Fdelimiter script.rb file.txt" do
      stdout_equal [
        '["123", "456 ", " 789\n"]',
        '["", "HELLO", "WORLD\n"]',
      ]
    end
  end

  #--------------------
  # -Idirectory     specify $LOAD_PATH directory (may be used more than once)

  def test_option_I
    create_file "some/dir1/req1.rb", [
      "puts 'This is ' + __FILE__",
    ]
    create_file "some/dir1/req2.rb", [
      "puts 'This is ' + __FILE__",
    ]
    create_file "some/dir2/req1.rb", [
      "puts 'This is ' + __FILE__",
    ]

    create_file "script.rb", [
      "require 'req1'",
      "require 'req2'",
    ]

    cmd "#{ruby} script.rb" do
      exit_nonzero
      stderr_equal /no such file to load/
    end

    cmd "#{ruby} -I some/dir1 script.rb" do
      stdout_equal [
        "This is ./some/dir1/req1.rb",
        "This is ./some/dir1/req2.rb",
      ]
    end

    cmd "#{ruby} -I some/dir2 -I some/dir1 script.rb" do
      stdout_equal [
        "This is ./some/dir2/req1.rb",
        "This is ./some/dir1/req2.rb",
      ]
    end
  end

  #--------------------
  # -Kkcode         specifies KANJI (Japanese) code-set

  def test_option_K
    # TODO: how to test this ?
  end

  #--------------------
  # -S              look for the script using PATH environment variable

  def test_option_S
    create_file "some/dir/script.rb", [
      "puts 'this is script.rb'",
    ]
    prepend_local_path "some/dir"

    cmd "#{ruby} script.rb" do
      exit_nonzero
      stderr_equal /No such file or directory/
    end

    cmd "#{ruby} -S script.rb" do
      stdout_equal "this is script.rb\n"
    end
  end

  #--------------------
  # -T[level]       turn on tainting checks

  def test_option_T
    # TODO: how to test this ?
  end

  #--------------------
  # -W[level]       set warning level; 0=silence, 1=medium, 2=verbose (default)

  def test_option_W
    create_file "script.rb", [
      "exit @x ? 11 : 22",
    ]

    cmd "#{ruby} -w -W0 script.rb" do
      exit_status 22
    end

    cmd "#{ruby} -w -W2 script.rb" do
      stderr_equal /warning: instance variable @x not initialized/
      exit_status 22
    end

    # -W2 is default
    cmd "#{ruby} -w script.rb" do
      stderr_equal /warning: instance variable @x not initialized/
      exit_status 22
    end
  end

  #--------------------
  # -0[octal]       specify record separator (\0, if no argument)

  def test_option_0
    create_file "file.txt", "abxc\0dexf\0ghxi\0"

    create_file "script.rb", [
      "puts $_.chomp"
    ]

    cmd "#{ruby} -0 -n script.rb file.txt" do
      stdout_equal [
        "abxc",
        "dexf",
        "ghxi",
      ]
    end

    create_file "file.txt", "abxcydexfyghxiy"

    cmd "#{ruby} -0171 -n script.rb file.txt" do
      stdout_equal [
        "abxc",
        "dexf",
        "ghxi",
      ]
    end

    cmd "#{ruby} -0170 -n script.rb file.txt" do
      stdout_equal [
        "ab",
        "cyde",
        "fygh",
        "iy",
      ]
    end

  end

  #--------------------
  # -a   auto-split (used with -n or -p)

  def test_option_a
    create_file "a.txt", [
      "a 1  x",
      "b 2 \t y",
      "c 3 ",
    ]

    # with -n
    cmd ["#{ruby}", "-na",  "-e",  "p $F", "a.txt"] do
      stdout_equal [
        '["a", "1", "x"]',
        '["b", "2", "y"]',
        '["c", "3"]',
      ]
    end

    # with -p
    cmd ["#{ruby}", "-pa", "-e", "$_ = $F.inspect; $_ << 10", "a.txt"] do
      stdout_equal [
        '["a", "1", "x"]',
        '["b", "2", "y"]',
        '["c", "3"]',
      ]
    end

  end

  #--------------------
  # -c   check syntax only

  def test_option_c
    # script with no syntax errors
    create_file "script_ok.rb", [
      'puts 123 + 456',
    ]
    cmd "#{ruby} -c script_ok.rb" do
      stdout_equal "Syntax OK\n"
    end

    # script with syntax error
    create_file "script_error.rb", [
      'puts 123 +',
    ]
    cmd "#{ruby} -c script_error.rb" do
      exit_nonzero
      stderr_equal /syntax.*error/i
    end
  end

  #--------------------
  # -d   debug option & $DEBUG

  def test_option_d
    create_file "script.rb", [
      'p $DEBUG',
    ]

    # with -d
    cmd "#{ruby} -d script.rb" do
      stdout_equal "true\n"
    end

    # without -d
    cmd "#{ruby} script.rb" do
      stdout_equal "false\n"
    end
  end

  #--------------------
  # -e   one-line program

  def test_option_e
    # simple case
    cmd "#{ruby} -e 'puts :hello'" do
      stdout_equal "hello\n"
    end

    # several -e options
    cmd "#{ruby} -e 'puts :hello' -e 'puts :world' -e 'puts 123'" do
      stdout_equal [
        "hello",
        "world",
        "123",
      ]
    end

    # ARGV as usual
    cmd "#{ruby} -e 'p ARGV' 11 22 33" do
      stdout_equal [
        '["11", "22", "33"]',
      ]
    end

    # side effects seen in later -e
    cmd ["#{ruby}",  "-e",  "a = []", "-e",  "a << 11",
      "-e", "a << 22", "-e", "p a"] do
      stdout_equal [
        '[11, 22]',
      ]
    end
  end

  #--------------------
  # -h   help

  def test_option_h
    cmd "#{ruby} -h" do
      stdout_equal /^Usage: /
    end
  end

  #--------------------
  # -n   non-printing loop

  def test_option_n
    create_file "a.txt", [
      'line 1',
      'line 2',
      'line 3',
    ]

    # one-line script
    cmd "#{ruby} -n -e 'puts $_ if /[13]/' a.txt" do
      stdout_equal [
        'line 1',
        'line 3',
      ]
    end

    # real script
    create_file "script.rb", [
      'puts $_ if $_ =~ /[13]/',
    ]

    cmd "#{ruby} -n script.rb a.txt" do
      stdout_equal [
        'line 1',
        'line 3',
      ]
    end
  end

  #--------------------
  # -p   printing loop

  def test_option_p
    create_file "a.txt", [
      'line 1',
      'line 2',
      'line 3',
    ]

    # one-line script
    cmd "#{ruby} -p -e 'puts $_ if /[13]/' a.txt" do
      stdout_equal [
        'line 1',
        'line 1',
        'line 2',
        'line 3',
        'line 3',
      ]
    end

    # real script
    create_file "script.rb", [
      'puts $_ if $_ =~ /[13]/',
    ]
    cmd "#{ruby} -p script.rb a.txt" do
      stdout_equal [
        'line 1',
        'line 1',
        'line 2',
        'line 3',
        'line 3',
      ]
    end

    # modifying $_ before automatic print
    cmd ["#{ruby}",  "-p", "-e", "$_ = '...' + $_", "a.txt"] do
      stdout_equal [
        '...line 1',
        '...line 2',
        '...line 3',
      ]
    end
  end

  #--------------------

  def test_option_v
    cmd "#{ruby} -v" do
      stdout_equal [ /^ruby / ]
    end
  end

  #--------------------

  def test_script_on_stdin
    cmd "echo puts :hello_world | ruby" do
      stdout_equal "hello_world\n"
    end

    create_file "script.rb", [
      'puts "hello"',
      'puts "world"',
    ]

    cmd "#{ruby} < script.rb" do
      stdout_equal [
        "hello",
        "world",
      ]
    end
  end

end
