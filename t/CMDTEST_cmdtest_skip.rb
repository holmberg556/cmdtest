
require "selftest_utils"

class CMDTEST_cmdtest_skip < Cmdtest::Testcase

  include SelftestUtils

  #----------------------------------------
  # if CMDTEST_SKIP: occurs on stdout/stderr,
  # the test is skipped by an internal call to skip_test()

  def test_cmdtest_skip_CORRECT
    create_CMDTEST_foo [
      "cmd 'echo.rb CMDTEST_SKIP: why_test_is_skipped' do",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### echo.rb CMDTEST_SKIP: why_test_is_skipped",
        "--- SKIP: why_test_is_skipped",
      ]
    end
  end

  #----------------------------------------
  # other assertions don't matter at CMDTEST_SKIP:

  def test_cmdtest_skip_IGNORE_EXPECTED
    create_CMDTEST_foo [
      "cmd 'echo.rb CMDTEST_SKIP: why_test_is_skipped' do",
      "  stdout_equal ['alpha', 'beta']",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### echo.rb CMDTEST_SKIP: why_test_is_skipped",
        "--- SKIP: why_test_is_skipped",
      ]
    end
  end

  #----------------------------------------
  # CMDTEST_SKIP: must occur at start of line

  def test_cmdtest_skip_MISSED
    create_CMDTEST_foo [
      "cmd 'echo.rb garbage_CMDTEST_SKIP: why_test_is_skipped' do",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### echo.rb garbage_CMDTEST_SKIP: why_test_is_skipped",
         "--- ERROR: wrong stdout",
         "---        actual: garbage_CMDTEST_SKIP: why_test_is_skipped",
         "---        expect: [[empty]]",
      ]
      exit_nonzero
    end
  end

end
