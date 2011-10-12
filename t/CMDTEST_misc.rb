
require "selftest_utils"

class CMDTEST_misc < Cmdtest::Testcase

  include SelftestUtils

  #----------------------------------------
  # Ruby script called with "ruby -S"
  #----------------------------------------

  def test_ruby_script
    create_CMDTEST_foo [
      "cmd 'echo.rb this  is  a  line' do",
      "  stdout_equal ['this is a line']",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### echo.rb this  is  a  line",
      ]
    end
  end

  #-----------------------------------

  def test_actual_false_rb_will_give_error
    create_CMDTEST_foo [
      "cmd 'true.rb' do",
      "end",
      "",
      "cmd 'false.rb' do",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
        "### false.rb",
        "--- ERROR: expected zero exit status, got 1",
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_actual_false_rb_will_give_error_2
    create_CMDTEST_foo [
      "cmd 'false.rb' do",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### false.rb",
        "--- ERROR: expected zero exit status, got 1",
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_another_non_zero_exit_will_give_error
    create_CMDTEST_foo [
      "cmd 'exit.rb 18' do",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### exit.rb 18",
        "--- ERROR: expected zero exit status, got 18",
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_actual_STDOUT_will_give_error
    create_CMDTEST_foo [
      "cmd 'echo.rb a line on stdout' do",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### echo.rb a line on stdout",
        "--- ERROR: wrong stdout",
        "---        actual: a line on stdout",
        "---        expect: [[empty]]",
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_actual_STDERR_will_give_error
    create_CMDTEST_foo [
      "cmd 'echo.rb a line on stderr 1>&2' do",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### echo.rb a line on stderr 1>&2",
        "--- ERROR: wrong stderr",
        "---        actual: a line on stderr",
        "---        expect: [[empty]]",
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_existing_files_is_OK
    create_CMDTEST_foo [
      "File.open('before1', 'w') {}",
      "File.open('before2', 'w') {}",
      "cmd 'true.rb' do",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
      ]
    end
  end

  #-----------------------------------

  def test_actual_created_file_will_give_error
    create_CMDTEST_foo [
      "cmd 'echo.rb content > a-new-file' do",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### echo.rb content > a-new-file",
        "--- ERROR: created files",
        '---        actual: ["a-new-file"]',
        "---        expect: []",
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_several_actual_created_files_will_give_error
    create_CMDTEST_foo [
      "File.open('before1', 'w') {}",
      "File.open('before2', 'w') {}",
      "cmd 'echo.rb x > a && echo.rb x > b' do",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### echo.rb x > a && echo.rb x > b",
        "--- ERROR: created files",
        '---        actual: ["a", "b"]',
        "---        expect: []",
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_actual_removed_file_will_give_error
    create_CMDTEST_foo [
      "File.open('before', 'w') {}",
      "cmd 'rm.rb before' do",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### rm.rb before",
        "--- ERROR: removed files",
        '---        actual: ["before"]',
        "---        expect: []",
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_several_actual_removed_files_will_give_error
    create_CMDTEST_foo [
      "File.open('before1', 'w') {}",
      "File.open('before2', 'w') {}",
      "File.open('before3', 'w') {}",
      "cmd 'rm.rb before1 before2' do",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### rm.rb before1 before2",
        "--- ERROR: removed files",
        '---        actual: ["before1", "before2"]',
        "---        expect: []",
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_actual_changed_files_will_give_error
    # NOTE: order of writing/testing is important below
    create_CMDTEST_foo <<'_END_'
      File.open('changed1', 'w') {}
      File.open('changed2', 'w') {}

      File.open('script.rb', 'w') do |f|
          f.puts 't1 = File.mtime("changed2")'
          f.puts 'while File.mtime("changed2") == t1'
          f.puts '    File.open("changed2", "w") {|f| f.puts 111 }'
          f.puts '    File.open("changed1", "w") {|f| f.puts 111 }'
          f.puts 'end'
      end

      cmd 'ruby script.rb' do
      end
_END_

    cmd_cmdtest do
      stdout_equal [
        "### ruby script.rb",
        "--- ERROR: changed files",
        '---        actual: ["changed1", "changed2"]',
        "---        expect: []",
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_mix_of_actual_created_removed_files_will_give_error
    create_CMDTEST_foo [
      "File.open('before1', 'w') {}",
      "File.open('before2', 'w') {}",
      "File.open('before3', 'w') {}",
      "cmd 'rm.rb before1 before2 && echo.rb x > a && echo.rb x > b' do",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### rm.rb before1 before2 && echo.rb x > a && echo.rb x > b",
        "--- ERROR: created files",
        '---        actual: ["a", "b"]',
        "---        expect: []",
        "--- ERROR: removed files",
        '---        actual: ["before1", "before2"]',
        "---        expect: []",
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_mix_of_all_errros
    create_CMDTEST_foo <<'_END_'
      File.open('before1', 'w') {}
      File.open('before2', 'w') {}
      File.open('before3', 'w') {}
      File.open('script.rb', 'w') do |f|
          f.puts 'File.unlink "before1"'
          f.puts 'File.unlink "before2"'
          f.puts 'File.open("a", "w") {}'
          f.puts 'File.open("b", "w") {}'
          f.puts 'STDOUT.puts [11,22,33]'
          f.puts 'STDERR.puts [44,55,66]'
          f.puts 'exit 39'
      end
      cmd 'ruby script.rb' do
      end
_END_

    cmd_cmdtest do
      stdout_equal [
        "### ruby script.rb",
        "--- ERROR: expected zero exit status, got 39",
        "--- ERROR: wrong stdout",
        "---        actual: 11",
        "---                22",
        "---                33",
        "---        expect: [[empty]]",
        "--- ERROR: wrong stderr",
        "---        actual: 44",
        "---                55",
        "---                66",
        "---        expect: [[empty]]",
        "--- ERROR: created files",
        '---        actual: ["a", "b"]',
        "---        expect: []",
        "--- ERROR: removed files",
        '---        actual: ["before1", "before2"]',
        "---        expect: []",
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_removed_files
    create_CMDTEST_foo [
      "File.open('file1', 'w') {}",
      "File.open('file2', 'w') {}",
      "",
      "cmd 'rm.rb file1' do",
      "    comment 'removed_files'",
      "    removed_files 'file1'",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### removed_files",
      ]
    end
  end

  #-----------------------------------

  def test_FAILED_removed_files
    create_CMDTEST_foo [
      "File.open('file1', 'w') {}",
      "File.open('file2', 'w') {}",
      "",
      "cmd 'true.rb' do",
      "    comment 'FAILED removed_files'",
      "    removed_files 'file1'",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### FAILED removed_files",
        "--- ERROR: removed files",
        "---        actual: []",
        '---        expect: ["file1"]',
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_changed_files
    create_CMDTEST_foo [
      "File.open('file1', 'w') {}",
      "File.open('file2', 'w') {}",
      "",
      "cmd 'sleep.rb 1 && touch.rb file1' do",
      "    comment 'changed_files'",
      "    changed_files 'file1'",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### changed_files",
      ]
    end
  end

  #-----------------------------------

  def test_FAILED_changed_files

    create_CMDTEST_foo [
      "File.open('file1', 'w') {}",
      "File.open('file2', 'w') {}",
      "",
      "cmd 'true.rb' do",
      "    comment 'FAILED changed_files'",
      "    changed_files 'file1'",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### FAILED changed_files",
        "--- ERROR: changed files",
        "---        actual: []",
        '---        expect: ["file1"]',
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_created_files
    create_CMDTEST_foo [
      "File.open('file1', 'w') {}",
      "File.open('file2', 'w') {}",
      "",
      "cmd 'touch.rb file3' do",
      "    comment 'created_files'",
      "    created_files 'file3'",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### created_files",
      ]
    end
  end

  #-----------------------------------

  def test_FAILED_created_files
    create_CMDTEST_foo [
      "File.open('file1', 'w') {}",
      "File.open('file2', 'w') {}",
      "",
      "cmd 'true.rb' do",
      "    comment 'FAILED created_files'",
      "    created_files 'file3'",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### FAILED created_files",
        "--- ERROR: created files",
        "---        actual: []",
        '---        expect: ["file3"]',
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_with_comment
    create_CMDTEST_foo [
      "cmd 'true.rb' do",
      "    comment 'this-is-the-comment'",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### this-is-the-comment",
      ]
    end
  end

  #-----------------------------------

  def test_exit_nonzero
    create_CMDTEST_foo [
      "cmd 'exit.rb 33' do",
      "    comment 'exit_nonzero'",
      "    exit_nonzero",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### exit_nonzero",
      ]
    end
  end

  #-----------------------------------

  def test_FAILING_exit_nonzero
    create_CMDTEST_foo [
      "cmd 'exit.rb 0' do",
      "    comment 'failing exit_nonzero'",
      "    exit_nonzero",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### failing exit_nonzero",
        "--- ERROR: expected nonzero exit status",
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_exit_status
    create_CMDTEST_foo [
      "cmd 'exit.rb 33' do",
      "    comment 'exit_status'",
      "    exit_status 33",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### exit_status",
      ]
    end
  end

  #-----------------------------------

  def test_FAILING_exit_status
    create_CMDTEST_foo [
      "cmd 'exit.rb 44' do",
      "    comment 'failing exit_status'",
      "    exit_status 33",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### failing exit_status",
        "--- ERROR: expected 33 exit status, got 44",
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_stdout_equal_ONE_LINE
    create_CMDTEST_foo [
      "cmd 'lines.rb 11' do",
      "    comment 'stdout_equal'",
      "    stdout_equal '11\n'",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### stdout_equal",
      ]
    end
  end

  #-----------------------------------

  def test_FAILING_stdout_equal_ONE_LINE
    create_CMDTEST_foo [
      "cmd 'lines.rb 22' do",
      "    comment 'stdout_equal'",
      "    stdout_equal '11\n'",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### stdout_equal",
        "--- ERROR: wrong stdout",
        "---        actual: 22",
        "---        expect: 11",
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_stdout_equal_TWO_LINES
    create_CMDTEST_foo [
      "cmd 'lines.rb 11 22' do",
      "    comment 'stdout_equal'",
      "    stdout_equal '11\n22\n'",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### stdout_equal",
      ]
    end
  end

  #-----------------------------------

  def test_FAILING_stdout_equal_TWO_LINES
    create_CMDTEST_foo [
      "cmd 'lines.rb 33 44' do",
      "    comment 'stdout_equal'",
      "    stdout_equal '11\n22\n'",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### stdout_equal",
        "--- ERROR: wrong stdout",
        "---        actual: 33",
        "---                44",
        "---        expect: 11",
        "---                22",
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_stdout_equal_ARR_TWO_LINES
    create_CMDTEST_foo [
      "cmd 'lines.rb 11 22' do",
      "    comment 'stdout_equal'",
      "    stdout_equal ['11', '22']",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### stdout_equal",
      ]
    end
  end

  #-----------------------------------

  def test_FAILING_stdout_equal_ARR_TWO_LINES
    create_CMDTEST_foo [
      "cmd 'lines.rb 33 44' do",
      "    comment 'stdout_equal'",
      "    stdout_equal ['11', '22']",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### stdout_equal",
        "--- ERROR: wrong stdout",
        "---        actual: 33",
        "---                44",
        "---        expect: 11",
        "---                22",
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_FAILING_stdout_equal_ARR_DIFFERENT_NR_LINES
    create_CMDTEST_foo [
      "cmd 'lines.rb 11 22 33' do",
      "    comment 'stdout_equal'",
      "    stdout_equal ['11', '22']",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### stdout_equal",
        "--- ERROR: wrong stdout",
        "---        actual: 11",
        "---                22",
        "---                33",
        "---        expect: 11",
        "---                22",
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_stdout_equal_REGEXP_ARGUMENT
    create_CMDTEST_foo [
      "cmd 'lines.rb 11 22' do",
      "    comment 'stdout_equal'",
      "    stdout_equal /^22$/",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### stdout_equal",
      ]
    end
  end

  #-----------------------------------

  def test_stdout_equal_TWICE_REGEXP_ARGUMENT
    create_CMDTEST_foo [
      "cmd 'lines.rb 11 22' do",
      "    comment 'stdout_equal'",
      "    stdout_equal /^22$/",
      "    stdout_equal /^11$/",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### stdout_equal",
      ]
    end
  end

  #-----------------------------------

  def test_FAILING_first_stdout_equal_twice_regexp_argument
    create_CMDTEST_foo [
      "cmd 'lines.rb 99 22' do",
      "    comment 'stdout_equal'",
      "    stdout_equal /^22$/",
      "    stdout_equal /^11$/",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### stdout_equal",
        "--- ERROR: wrong stdout",
        "---        actual: 99",
        "---                22",
        "---        expect: (?-mix:^11$)",
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_FAILING_second_stdout_equal_twice_regexp_argument
    create_CMDTEST_foo [
      "cmd 'lines.rb 11 99' do",
      "    comment 'stdout_equal'",
      "    stdout_equal /^22$/",
      "    stdout_equal /^11$/",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### stdout_equal",
        "--- ERROR: wrong stdout",
        "---        actual: 11",
        "---                99",
        "---        expect: (?-mix:^22$)",
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_FAILING_stdout_equal_REGEXP_ARGUMENT
    create_CMDTEST_foo [
      "cmd 'lines.rb 11 22' do",
      "    comment 'stdout_equal'",
      "    stdout_equal /^\d+ \d+$/",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### stdout_equal",
        "--- ERROR: wrong stdout",
        "---        actual: 11",
        "---                22",
        "---        expect: (?-mix:^\d+ \d+$)",
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_stdout_equal_ARR_REGEXP_ARGUMENT
    create_CMDTEST_foo [
      "cmd 'lines.rb 11 22' do",
      "    comment 'stdout_equal'",
      "    stdout_equal ['11', /^22$/]",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### stdout_equal",
      ]
    end
  end

  #-----------------------------------

  def test_stdout_equal_ARR_REGEXP_ARGUMENT_II
    create_CMDTEST_foo [
      "cmd 'lines.rb 11 22' do",
      "    comment 'stdout_equal'",
      "    stdout_equal ['11', /^\\d+$/]",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### stdout_equal",
      ]
    end
  end

  #-----------------------------------

  def test_FAILING_stdout_equal_ARR_REGEXP_ARGUMENT
    create_CMDTEST_foo [
      "cmd 'lines.rb 11 22' do",
      "    comment 'stdout_equal'",
      "    stdout_equal ['11', /^\d+ \d+$/]",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### stdout_equal",
        "--- ERROR: wrong stdout",
        "---        actual: 11",
        "---                22",
        "---        expect: 11",
        "---                (?-mix:^\d+ \d+$)",
      ]
      exit_nonzero
    end
  end

  #======================================================================

  #-----------------------------------
  # symlinks in tree -- should work
  # TODO: this test should be improved to actually trigger the difference
  # between lstat/stat in "_update_hardlinks".
  #
  # REQUIRE: RUBY_PLATFORM !~ /mswin32/

  def test_symlinks_in_tree
    create_CMDTEST_foo [
      "File.symlink 'non-existing', 'non-existing-link'",
      "",
      "File.open('existing', 'w') {}",
      "File.symlink 'existing', 'existing-link'",
      "",
      "cmd 'true.rb' do",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
      ]
    end
  end

  #-----------------------------------

  def test_file_with_mtime_in_future
    create_CMDTEST_foo [
      "File.open('future-file', 'w') {}",
      "future = Time.now + 86400",
      "File.utime future, future, 'future-file'",
      "",
      "cmd 'true.rb' do",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
      ]
    end
  end


end

