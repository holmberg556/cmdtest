
require "selftest_utils"

class CMDTEST_exit_nonzero < Cmdtest::Testcase

  include SelftestUtils

  #----------------------------------------
  # 'exit_nonzero' expects the command to exit
  # with a non-zero exit status

  def test_exit_nonzero_CORRECT
    create_CMDTEST_foo [
      "cmd 'false.rb' do",
      "    exit_nonzero",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### false.rb",
      ]
    end
  end

  #----------------------------------------
  # 'exit_nonzero' works for other non-zero
  # exit statuses than 1 too

  def test_exit_nonzero_CORRECT_18
    create_CMDTEST_foo [
      "cmd 'exit.rb 18' do",
      "    exit_nonzero",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### exit.rb 18",
      ]
    end
  end

  #----------------------------------------
  # 'exit_nonzero' gives an error if the exit status is 0

  def test_exit_nonzero_INCORRECT
    create_CMDTEST_foo [
      "cmd 'true.rb' do",
      "    exit_nonzero",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
        "--- ERROR: expected nonzero exit status",
      ]
      exit_nonzero
    end
  end

end
