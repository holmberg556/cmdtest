
require "selftest_utils"

class CMDTEST_stdxxx_contain < Cmdtest::Testcase

  include SelftestUtils

  #========================================
  # Using "define_method" to avoid duplicating definitions of
  # stderr/stdout methods. The follwing section tests:
  #
  #     stderr_contain
  #     stdout_contain
  #

  def self._define_stdxxx_methods(stdxxx)

    #----------------------------------------
    # stdxxx_contain
    #----------------------------------------

    ## methods: test_stdout_contain_CORRECT_SIMPLE test_stderr_contain_CORRECT_SIMPLE

    define_method("test_#{stdxxx}_contain_CORRECT_SIMPLE") do
      create_CMDTEST_foo [
        "cmd 'lines.rb --#{stdxxx} 11 22' do",
        "    #{stdxxx}_contain ['11', '22']",
        "    #{stdxxx}_contain ['22']",
        "    #{stdxxx}_contain ['11']",
        "end",
      ]

      cmd_cmdtest do
        stdout_equal [
          "### lines.rb --#{stdxxx} 11 22",
        ]
      end
    end

    #----------------------------------------
    ## methods: test_stdout_contain_INCORRECT_SIMPLE test_stderr_contain_INCORRECT_SIMPLE

    define_method("test_#{stdxxx}_contain_INCORRECT_SIMPLE") do
      create_CMDTEST_foo [
        "cmd 'lines.rb --#{stdxxx} hello world' do",
        "    #{stdxxx}_contain ['HELLO']",
        "    #{stdxxx}_contain ['hello', 'WORLD']",
        "end",
      ]

      cmd_cmdtest do
        stdout_equal [
          "### lines.rb --#{stdxxx} hello world",
          "--- ERROR: not found in #{stdxxx}:",
          "---     HELLO",
          "--- ERROR: found only part in #{stdxxx}:",
          "---     hello",
          "--- ERROR: should have been followed by:",
          "---     WORLD",
          "--- ERROR: instead followed by:",
          "---     world",
        ]
        exit_nonzero
      end
    end

  end # _define_stdxxx_methods

  #----------------------------------------

  for stdxxx in ["stderr", "stdout"]
    _define_stdxxx_methods(stdxxx)
  end

end
