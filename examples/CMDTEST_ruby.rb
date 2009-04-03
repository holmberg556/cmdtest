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
  # -C   chdir to a directory before running script

  def test_option_C
    create_file "some/dir/script.rb", [
      'puts "cwd = " + Dir.pwd',
    ]

    # chdir before script
    cmd "#{ruby} -Csome/dir script.rb" do
      stdout_equal [
        /^cwd = .*some\/dir$/,
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
  # -a   auto-split (used with -n or -p)

  def test_option_a
    create_file "a.txt", [
      "a 1  x",
      "b 2 \t y",
      "c 3 ",
    ]

    # with -n
    cmd %Q|#{ruby} -na -e "p $F" a.txt| do
      stdout_equal [
        '["a", "1", "x"]',
        '["b", "2", "y"]',
        '["c", "3"]',
      ]
    end

    # with -p
    cmd %Q|#{ruby} -pa -e "$_ = $F.inspect" a.txt| do
      stdout_equal '["a", "1", "x"]["b", "2", "y"]["c", "3"]'
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
    cmd %Q|#{ruby} -e "puts :hello" -e "puts :world" -e "puts 123"| do
      stdout_equal [
        "hello",
        "world",
        "123",
      ]
    end

    # ARGV as usual
    cmd %Q|#{ruby} -e "p ARGV" 11 22 33| do
      stdout_equal [
        '["11", "22", "33"]',
      ]
    end

    # side effects seen in later -e
    cmd %Q|#{ruby} -e "a = []" -e "a << 11" -e "a << 22" -e "p a"| do
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
    cmd %Q|#{ruby} -p -e "puts $_ if /[13]/" a.txt| do
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
    cmd %Q|#{ruby} -p -e "$_ = '...' + $_" a.txt| do
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
