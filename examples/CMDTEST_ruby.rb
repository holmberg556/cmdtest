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
  # -a              autosplit mode with -n or -p (splits $_ into $F)

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
  # -c              check syntax only

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
  # -d              set debugging flags (set $DEBUG to true)

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
  # -e 'command'    one line of script. Several -e's allowed. Omit [programfile]

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
  # -i[extension]   edit ARGV files in place (make backup if extension supplied)

  def test_option_i_bak
    create_file "file.txt", "alpha\nbeta\ngamma\n"

    create_file "script.rb", [
      "$_.gsub!(/a/, 'A')",
      "$_.gsub!(/this/, 'THIS')",
    ]
    cmd "#{ruby} -i.bak -p script.rb file.txt"  do
      changed_files "file.txt"
      file_equal "file.txt", "AlphA\nbetA\ngAmmA\n"

      created_files "file.txt.bak"
      file_equal "file.txt.bak", "alpha\nbeta\ngamma\n"
    end

    create_file "file1.txt", "this is file1.txt\n"
    create_file "file2.txt", "this is file2.txt\n"
    create_file "file3.txt", "this is file3.txt\n"

    # several input files
    cmd "#{ruby} -i.bak -p script.rb file1.txt file2.txt file3.txt"  do
      changed_files "file1.txt", "file2.txt", "file3.txt"
      file_equal "file1.txt", "THIS is file1.txt\n"
      file_equal "file2.txt", "THIS is file2.txt\n"
      file_equal "file3.txt", "THIS is file3.txt\n"

      created_files "file1.txt.bak", "file2.txt.bak", "file3.txt.bak"
      file_equal "file1.txt.bak", "this is file1.txt\n"
      file_equal "file2.txt.bak", "this is file2.txt\n"
      file_equal "file3.txt.bak", "this is file3.txt\n"
    end
  end

  def test_option_i
    create_file "file.txt", "alpha\nbeta\ngamma\n"

    create_file "script.rb", [
      "$_.gsub!(/a/, 'A')",
      "$_.gsub!(/this/, 'THIS')",
    ]
    cmd "#{ruby} -i -p script.rb file.txt"  do
      changed_files "file.txt"
      file_equal "file.txt", "AlphA\nbetA\ngAmmA\n"
    end

    create_file "file1.txt", "this is file1.txt\n"
    create_file "file2.txt", "this is file2.txt\n"
    create_file "file3.txt", "this is file3.txt\n"

    # several input files
    cmd "#{ruby} -i -p script.rb file1.txt file2.txt file3.txt"  do
      changed_files "file1.txt", "file2.txt", "file3.txt"
      file_equal "file1.txt", "THIS is file1.txt\n"
      file_equal "file2.txt", "THIS is file2.txt\n"
      file_equal "file3.txt", "THIS is file3.txt\n"
    end
  end

  #--------------------
  # -l              enable line ending processing
  def test_option_l
    create_file "file.txt", [
      "aaa",
      "bbb",
    ]
    create_file "script.rb", [
      "p $_",
    ]

    # without -l
    cmd "#{ruby} -n script.rb file.txt" do
      stdout_equal [
        '"aaa\n"',
        '"bbb\n"',
      ]
    end

    # with -l
    cmd "#{ruby} -l -n script.rb file.txt" do
      stdout_equal [
        '"aaa"',
        '"bbb"',
      ]
    end
  end

  #--------------------
  # -n              assume 'while gets(); ... end' loop around your script

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
  # -p              assume loop like -n but print line also like sed

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
  # -rlibrary       require the library, before executing your script

  def test_option_r
    create_file "dir1/bbb.rb", [
      "puts 'this is dir1/bbb.rb'",
    ]
    create_file "aaa.rb", [
      "puts 'this is aaa.rb'",
    ]

    cmd "#{ruby} -Idir1 -rbbb aaa.rb" do
      comment "with -rbbb option"
      stdout_equal [
        "this is dir1/bbb.rb",
        "this is aaa.rb",
      ]
    end
  end

  #--------------------
  # -s              enable some switch parsing for switches after script name

  def test_option_s
    create_file "file.txt", [
      "abc",
      "def-ghi",
    ]
    create_file "script.rb", [
      "#!ruby -p",
      "$_.tr!('a-z', 'A-Z')",
    ]

    cmd "#{ruby} script.rb file.txt" do
      comment "with -p option in script header"
      stdout_equal [
        "ABC",
        "DEF-GHI",
      ]
    end
  end

  #--------------------
  # -v              print version number, then turn on verbose mode

  def test_option_v
    cmd "#{ruby} -v" do
      stdout_equal [ /^ruby / ]
    end

    create_file "script.rb", [
      "p $VERBOSE",
      "exit 34",
    ]

    cmd "#{ruby} -v script.rb" do
      exit_status 34
      stdout_equal [
        /ruby/,
        "true",
      ]
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
