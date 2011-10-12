
require "selftest_utils"

class CMDTEST_file_equal < Cmdtest::Testcase

  include SelftestUtils

  #----------------------------------------
  # 'file_equal' detects equal file content

  def test_file_equal_CORRECT_EMPTY
    create_CMDTEST_foo [
      "File.open('foo', 'w') {}",
      "",
      "cmd 'true.rb' do",
      "    file_equal 'foo', ''",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
      ]
    end
  end

  #----------------------------------------
  # 'file_equal' detects different file content
  # and reports an error

  def test_file_equal_INCORRECT_EMPTY

    create_CMDTEST_foo [
      "File.open('foo', 'w') {|f| f.puts 'hello world' }",
      "",
      "cmd 'true.rb' do",
      "    file_equal 'foo', ''",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
        "--- ERROR: wrong file 'foo'",
        "---        actual: hello world",
        "---        expect: [[empty]]",
      ]
      exit_nonzero
    end
  end
      
  #----------------------------------------
  # 'file_equal' detects equal file content,
  # using [] argument too

  def test_file_equal_CORRECT_NO_LINES

    create_CMDTEST_foo [
      "File.open('foo', 'w') {}",
      "",
      "cmd 'true.rb' do",
      "    file_equal 'foo', []",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
      ]
    end
  end

  #----------------------------------------
  # 'file_equal' detects different file content
  # and reports an error,
  # using [] argument too

  def test_file_equal_INCORRECT_NO_LINES

    create_CMDTEST_foo [
      "File.open('foo', 'w') {|f| f.puts 'hello world' }",
      "",
      "cmd 'true.rb' do",
      "    file_equal 'foo', []",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
        "--- ERROR: wrong file 'foo'",
        "---        actual: hello world",
        "---        expect: [[empty]]",
      ]
      exit_nonzero
    end
  end

  #----------------------------------------
  # testing [] argument with one line (equal)

  def test_file_equal_CORRECT_LINE

    create_CMDTEST_foo [
      "File.open('foo', 'w') {|f| f.puts 'hello world' }",
      "",
      "cmd 'true.rb' do",
      "    file_equal 'foo', [ 'hello world' ]",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
      ]
    end
  end

  #----------------------------------------
  # testing [] argument with one line (different)

  def test_file_equal_INCORRECT_LINE

    create_CMDTEST_foo [
      "File.open('foo', 'w') {}",
      "",
      "cmd 'true.rb' do",
      "    file_equal 'foo', [ 'hello world' ]",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
        "--- ERROR: wrong file 'foo'",
        "---        actual: [[empty]]",
        "---        expect: hello world",
      ]
      exit_nonzero
    end
  end

  #----------------------------------------
  # testing [] argument with two lines (equal)

  def test_file_equal_CORRECT_2_LINES

    create_CMDTEST_foo [
      "File.open('foo', 'w') {|f| f.puts 'hello'; f.puts 'world' }",
      "",
      "cmd 'true.rb' do",
      "    file_equal 'foo', [ 'hello', 'world' ]",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
      ]
    end
  end

  #----------------------------------------
  # testing [] argument with two lines (different)

  def test_file_equal_INCORRECT_2_LINES

    create_CMDTEST_foo [
      "File.open('foo', 'w') {}",
      "",
      "cmd 'true.rb' do",
      "    file_equal 'foo', [ 'hello', 'world' ]",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
        "--- ERROR: wrong file 'foo'",
        "---        actual: [[empty]]",
        "---        expect: hello",
        "---                world",
      ]
      exit_nonzero
    end
  end

  #----------------------------------------
  # non-existing file gives an error

  def test_file_equal_NON_EXISTING_FILE

    create_CMDTEST_foo [
      "cmd 'true.rb' do",
      "    file_equal 'foo', ''",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
        "--- ERROR: no such file: 'foo'",
      ]
      exit_nonzero
    end
  end

  #----------------------------------------
  # file being a directory gives an error

  def test_file_equal_FILE_IS_DIRECTORY

    create_CMDTEST_foo [
      "Dir.mkdir 'foo'",
      "",
      "cmd 'true.rb' do",
      "    file_equal 'foo', ''",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
        "--- ERROR: is a directory: 'foo'",
      ]
      exit_nonzero
    end
  end

  #----------------------------------------
  # other error also detected (recursive symlink)

  def test_file_equal_OTHER_ERROR
    #
    return unless RUBY_PLATFORM !~ /mswin32/

    create_CMDTEST_foo [
      "File.symlink 'foo', 'foo'",
      "",
      "cmd 'true.rb' do",
      "    file_equal 'foo', ''",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
        "--- ERROR: error reading file: 'foo'",
      ]
      exit_nonzero
    end
  end

end
