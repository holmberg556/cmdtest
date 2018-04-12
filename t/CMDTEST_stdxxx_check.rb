
require "selftest_utils"

class CMDTEST_stdxxx_check < Cmdtest::Testcase

  include SelftestUtils

  #========================================
  # Using "define_method" to avoid duplicating definitions of
  # stderr/stdout methods.

  def self._define_stdxxx_methods(stdxxx)

    #----------------------------------------
    # stdxxx_check
    #----------------------------------------

    define_method("test_#{stdxxx}_check_CORRECT") do
      create_CMDTEST_foo [
        "cmd 'echo_#{stdxxx}.rb --lines A B C A' do",
        "    #{stdxxx}_check do |lines|",
        "        n = 0",
        "        for line in lines",
        "            n +=1 if line == 'A'",
        "        end",
        "        assert n == 2, \"A occurs \#{n} times (not 2)\"",
        "    end",
        "end",
      ]

      cmd_cmdtest do
        stdout_equal [
          "### echo_#{stdxxx}.rb --lines A B C A",
        ]
      end
    end

    define_method("test_#{stdxxx}_check_INCORRECT") do
      create_CMDTEST_foo [
        "cmd 'echo_#{stdxxx}.rb --lines A B C D' do",
        "    #{stdxxx}_check do |lines|",
        "        n = 0",
        "        for line in lines",
        "            n +=1 if line == 'A'",
        "        end",
        "        assert n == 2, \"A occurs \#{n} times (not 2)\"",
        "    end",
        "end",
      ]

      cmd_cmdtest do
        stdout_equal [
          "### echo_#{stdxxx}.rb --lines A B C D",
          "--- ERROR: assertion: A occurs 1 times (not 2)",
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

