
require "selftest_utils"

class CMDTEST_assert < Cmdtest::Testcase

  include SelftestUtils

  #----------------------------------------
  # a positive assert is "quiet"

  def test_assert_CORRECT
    create_CMDTEST_foo [
      "    cmd 'true.rb' do",
      "      assert true",
      "    end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
      ]
    end
  end

  #----------------------------------------
  # a negative assert is prints an error

  def test_assert_INCORRECT
    create_CMDTEST_foo [
      "    cmd 'true.rb' do",
      "      assert false",
      "    end",
    ]
 
    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
        "--- ERROR: assertion failed",
      ]
      exit_nonzero
    end
  end

  #----------------------------------------
  # an assert can have an extra message parameter,
  # that is printed if the assert is negative

  def test_assert_INCORRECT_WITH_MSG
    create_CMDTEST_foo [
      "    cmd 'true.rb' do",
      "      assert false, 'got false'",
      "    end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
        "--- ERROR: assertion: got false",
      ]
      exit_nonzero
    end
  end

  #----------------------------------------
  # two negative asserts are both reported

  def test_assert_INCORRECT_WITH_MSG_2
    create_CMDTEST_foo [
      "    cmd 'true.rb' do",
      "      assert false, 'got false 1'",
      "      assert false, 'got false 2'",
      "    end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
        "--- ERROR: assertion: got false 1",
        "--- ERROR: assertion: got false 2",
      ]
      exit_nonzero
    end
  end

end
