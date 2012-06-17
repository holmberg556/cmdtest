
require "selftest_utils"

class CMDTEST_file_not_equal < Cmdtest::Testcase

  include SelftestUtils

  #----------------------------------------
  # 'file_not_equal' detects different file content

  def test_file_not_equal_CORRECT
    create_CMDTEST_foo [
      "file_open('foo', 'w') {|f| f.puts 'hello' }",
      "",
      "cmd 'true.rb' do",
      "    file_not_equal 'foo', ['world']",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
      ]
    end
  end

  #-----------------------------------
  # 'file_not_equal' detects equal file content
  # and reports an error

  def test_file_not_equal_INCORRECT
    create_CMDTEST_foo [
      "file_open('foo', 'w') {|f| f.puts 'hello' }",
      "",
      "cmd 'true.rb' do",
      "    file_not_equal 'foo', ['hello']",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
        "--- ERROR: wrong file 'foo'",
        "---        actual: hello",
        "---        expect: hello",
      ]
      exit_nonzero
    end
  end

end
