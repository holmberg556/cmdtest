
require "selftest_utils"

class CMDTEST_exit_status < Cmdtest::Testcase

  include SelftestUtils

  def test_exit_status_CORRECT_0
    create_CMDTEST_foo [
      "cmd 'true.rb' do",
      "    exit_status 0",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
      ]
    end
  end

  #----------------------------------------

  def test_exit_status_INCORRECT_0
    create_CMDTEST_foo [
      "cmd 'false.rb' do",
      "    exit_status 0",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### false.rb",
        "--- ERROR: expected 0 exit status, got 1",
      ]
      exit_nonzero
    end
  end

  #----------------------------------------

  def test_exit_status_CORRECT_18
    create_CMDTEST_foo [
      "cmd 'exit.rb 18' do",
      "    exit_status 18",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### exit.rb 18",
      ]
    end
  end

  #----------------------------------------

  def test_exit_status_INCORRECT_18
    create_CMDTEST_foo [
      "cmd 'exit.rb 10' do",
      "    exit_status 18",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### exit.rb 10",
        "--- ERROR: expected 18 exit status, got 10",
      ]
      exit_nonzero
    end
  end

end
