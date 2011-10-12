
require "selftest_utils"

class CMDTEST_exit_zero < Cmdtest::Testcase

  include SelftestUtils

  def test_exit_zero_CORRECT
    create_CMDTEST_foo [
      "cmd 'true.rb' do",
      "    exit_zero",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
      ]
    end
  end

  #----------------------------------------

  def test_exit_zero_INCORRECT
    create_CMDTEST_foo [
      "cmd 'false.rb' do",
      "    exit_zero",
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

  #----------------------------------------

  def test_exit_zero_INCORRECT_18
    create_CMDTEST_foo [
      "cmd 'exit.rb 18' do",
      "    exit_zero",
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

end
