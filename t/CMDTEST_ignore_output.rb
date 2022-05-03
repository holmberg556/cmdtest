
require "selftest_utils"

class CMDTEST_ignore_output < Cmdtest::Testcase

  include SelftestUtils

  #----------------------------------------
  # an ignored file is not counted as a created file
  # even when it is actually created

  def test_ignore_output_GLOBAL
    create_CMDTEST_foo [
      "ignore_output()",
      "",
      "cmd 'echo.rb some-ignored-output-1' do",
      "end",
      "cmd 'echo.rb some-ignored-output-2' do",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### echo.rb some-ignored-output-1",
        "### echo.rb some-ignored-output-2",
      ]
    end
  end

  def test_ignore_output_LOCAL
    create_CMDTEST_foo [
      "",
      "cmd 'echo.rb some-ignored-output-1' do",
      "  ignore_output()",
      "end",
      "cmd 'echo.rb some-ignored-output-2' do",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### echo.rb some-ignored-output-1",
        "### echo.rb some-ignored-output-2",
        "--- ERROR: wrong stdout",
        "---        actual: some-ignored-output-2",
        "---        expect: [[empty]]",
      ]
      exit_nonzero
    end
  end

  def test_ignore_output_EXIT_NONZERO
    create_CMDTEST_foo [
      "",
      "cmd 'echo.rb some-ignored-output-1 && false.rb' do",
      "  ignore_output()",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### echo.rb some-ignored-output-1 && false.rb",
        "--- ERROR: expected zero exit status, got 1",
        "--- INFO: the stdout",
        "---        actual: some-ignored-output-1",
        "--- INFO: the stderr",
        "---        actual: [[empty]]",
      ]
      exit_nonzero
    end
  end

end
