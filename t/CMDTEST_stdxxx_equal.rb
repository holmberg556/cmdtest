
require "selftest_utils"

class CMDTEST_stdxxx_equal < Cmdtest::Testcase

  include SelftestUtils

  #========================================
  # Using "define_method" to avoid duplicating definitions of
  # stderr/stdout methods. The follwing section tests:
  #
  #     stderr_equal
  #     stderr_not_equal
  #     stdout_equal
  #     stdout_not_equal
  #

  def self._define_stdxxx_methods(stdxxx)

    #----------------------------------------
    # stdxxx_equal
    #----------------------------------------

    ## methods: test_stdout_equal_CORRECT_EMPTY test_stderr_equal_CORRECT_EMPTY

    define_method("test_#{stdxxx}_equal_CORRECT_EMPTY") do
      create_CMDTEST_foo [
        "cmd 'true.rb' do",
        "    #{stdxxx}_equal ''",
        "end",
      ]

      cmd_cmdtest do
        stdout_equal [
          "### true.rb",
        ]
      end
    end

    #----------------------------------------
    ## methods: test_stdout_equal_INCORRECT_EMPTY test_stderr_equal_INCORRECT_EMPTY

    define_method("test_#{stdxxx}_equal_INCORRECT_EMPTY") do
      create_CMDTEST_foo [
        "cmd 'echo_#{stdxxx}.rb hello world' do",
        "    #{stdxxx}_equal ''",
        "end",
      ]

      cmd_cmdtest do
        stdout_equal [
          "### echo_#{stdxxx}.rb hello world",
          "--- ERROR: wrong #{stdxxx}",
          "---        actual: hello world",
          "---        expect: [[empty]]",
        ]
        exit_nonzero
      end
    end

    #----------------------------------------

    ## methods: test_stdout_equal_CORRECT_NO_LINES test_stderr_equal_CORRECT_NO_LINES

    define_method("test_#{stdxxx}_equal_CORRECT_NO_LINES") do
      create_CMDTEST_foo [
        "cmd 'true.rb' do",
        "    #{stdxxx}_equal []",
        "end",
      ]

      cmd_cmdtest do
        stdout_equal [
          "### true.rb",
        ]
      end
    end

    #----------------------------------------

    ## methods: test_stdout_equal_INCORRECT_NO_LINES test_stderr_equal_INCORRECT_NO_LINES

    define_method("test_#{stdxxx}_equal_INCORRECT_NO_LINES") do
      create_CMDTEST_foo [
        "cmd 'echo_#{stdxxx}.rb hello world' do",
        "    #{stdxxx}_equal []",
        "end",
      ]

      cmd_cmdtest do
        stdout_equal [
          "### echo_#{stdxxx}.rb hello world",
          "--- ERROR: wrong #{stdxxx}",
          "---        actual: hello world",
          "---        expect: [[empty]]",
        ]
        exit_nonzero
      end
    end

    #----------------------------------------

    ## methods: test_stdout_equal_CORRECT_1_LINE test_stderr_equal_CORRECT_1_LINE

    define_method("test_#{stdxxx}_equal_CORRECT_1_LINE") do
      create_CMDTEST_foo [
        "cmd 'echo_#{stdxxx}.rb hello world' do",
        "    #{stdxxx}_equal [ 'hello world' ]",
        "end",
      ]

      cmd_cmdtest do
        stdout_equal [
          "### echo_#{stdxxx}.rb hello world",
        ]
      end
    end

    #----------------------------------------

    ## methods: test_stdout_equal_INCORRECT_1_LINE test_stderr_equal_INCORRECT_1_LINE

    define_method("test_#{stdxxx}_equal_INCORRECT_1_LINE") do
      create_CMDTEST_foo [
        "cmd 'true.rb' do",
        "    #{stdxxx}_equal [ 'hello world' ]",
        "end",
      ]

      cmd_cmdtest do
        stdout_equal [
          "### true.rb",
          "--- ERROR: wrong #{stdxxx}",
          "---        actual: [[empty]]",
          "---        expect: hello world",
        ]
        exit_nonzero
      end
    end

    #----------------------------------------

    ## methods: test_stdout_equal_CORRECT_2_LINES test_stderr_equal_CORRECT_2_LINES

    define_method("test_#{stdxxx}_equal_CORRECT_2_LINES") do

      create_CMDTEST_foo [
        "cmd 'echo_#{stdxxx}.rb hello && echo_#{stdxxx}.rb world' do",
        "    #{stdxxx}_equal [ 'hello', 'world' ]",
        "end",
      ]

      cmd_cmdtest do
        stdout_equal [
          "### echo_#{stdxxx}.rb hello && echo_#{stdxxx}.rb world",
        ]
      end
    end

    #----------------------------------------

    ## methods: test_stdout_equal_INCORRECT_2_LINES test_stderr_equal_INCORRECT_2_LINES

    define_method("test_#{stdxxx}_equal_INCORRECT_2_LINES") do

      create_CMDTEST_foo [
        "cmd 'true.rb' do",
        "    #{stdxxx}_equal [ 'hello', 'world' ]",
        "end",
      ]

      cmd_cmdtest do
        stdout_equal [
          "### true.rb",
          "--- ERROR: wrong #{stdxxx}",
          "---        actual: [[empty]]",
          "---        expect: hello",
          "---                world",
        ]
        exit_nonzero
      end
    end

    #----------------------------------------

    ## methods: test_stdout_equal_DIFF test_stderr_equal_DIFF

    define_method("test_#{stdxxx}_equal_DIFF") do

      create_CMDTEST_foo [
        "cmd 'echo_#{stdxxx}.rb --lines 11 33 44 55-changed 66 77 88' do",
        "    #{stdxxx}_equal [ '11', '22', '33', '44', '55', '66', '77' ]",
        "end",
      ]

      cmd_cmdtest_diff do
        stdout_equal [
          "### echo_#{stdxxx}.rb --lines 11 33 44 55-changed 66 77 88",
          "--- ERROR: wrong #{stdxxx}",
          "---     11",
          "---   - 22",
          "---     33",
          "---     44",
          "---   - 55",
          "---   + 55-changed",
          "---     66",
          "---     77",
          "---   + 88",
        ]
        exit_nonzero
      end
    end

    #----------------------------------------
    # stdxxx_not_equal
    #----------------------------------------

    ## methods: test_stdout_not_equal_CORRECT_EMPTY test_stderr_not_equal_CORRECT_EMPTY

    define_method("test_#{stdxxx}_not_equal_CORRECT_EMPTY") do
      create_CMDTEST_foo [
        "cmd 'echo_#{stdxxx}.rb hello' do",
        "    #{stdxxx}_not_equal ''",
        "end",
      ]

      cmd_cmdtest do
        stdout_equal [
          "### echo_#{stdxxx}.rb hello",
        ]
      end
    end

    #----------------------------------------

    ## methods: test_stdout_not_equal_INCORRECT_EMPTY test_stderr_not_equal_INCORRECT_EMPTY

    define_method("test_#{stdxxx}_not_equal_INCORRECT_EMPTY") do
      create_CMDTEST_foo [
        "cmd 'true.rb' do",
        "    #{stdxxx}_not_equal ''",
        "end",
      ]

      cmd_cmdtest do
        stdout_equal [
          "### true.rb",
          "--- ERROR: wrong #{stdxxx}",
          "---        actual: [[empty]]",
          "---        expect: [[empty]]",
        ]
        exit_nonzero
      end
    end

    #----------------------------------------

    ## methods: test_stdout_not_equal_CORRECT_NO_LINES test_stderr_not_equal_CORRECT_NO_LINES

    define_method("test_#{stdxxx}_not_equal_CORRECT_NO_LINES") do
      create_CMDTEST_foo [
        "cmd 'echo_#{stdxxx}.rb hello' do",
        "    #{stdxxx}_not_equal []",
        "end",
      ]

      cmd_cmdtest do
        stdout_equal [
          "### echo_#{stdxxx}.rb hello",
        ]
      end
    end

    #----------------------------------------
    ## methods: test_stdout_not_equal_INCORRECT_NO_LINES test_stderr_not_equal_INCORRECT_NO_LINES

    define_method("test_#{stdxxx}_not_equal_INCORRECT_NO_LINES") do
      create_CMDTEST_foo [
        "cmd 'true.rb' do",
        "    #{stdxxx}_not_equal []",
        "end",
      ]

      cmd_cmdtest do
        stdout_equal [
          "### true.rb",
          "--- ERROR: wrong #{stdxxx}",
          "---        actual: [[empty]]",
          "---        expect: [[empty]]",
        ]
        exit_nonzero
      end
    end

    #----------------------------------------

    ## methods: test_stdout_not_equal_CORRECT_1_LINE test_stderr_not_equal_CORRECT_1_LINE

    define_method("test_#{stdxxx}_not_equal_CORRECT_1_LINE") do
      create_CMDTEST_foo [
        "cmd 'echo_#{stdxxx}.rb not hello world' do",
        "    #{stdxxx}_not_equal [ 'hello world' ]",
        "end",
      ]

      cmd_cmdtest do
        stdout_equal [
          "### echo_#{stdxxx}.rb not hello world",
        ]
      end
    end

    #----------------------------------------

    ## methods: test_stdout_not_equal_INCORRECT_1_LINE test_stderr_not_equal_INCORRECT_1_LINE

    define_method("test_#{stdxxx}_not_equal_INCORRECT_1_LINE") do
      create_CMDTEST_foo [
        "cmd 'echo_#{stdxxx}.rb hello world' do",
        "    #{stdxxx}_not_equal [ 'hello world' ]",
        "end",
      ]

      cmd_cmdtest do
        stdout_equal [
          "### echo_#{stdxxx}.rb hello world",
          "--- ERROR: wrong #{stdxxx}",
          "---        actual: hello world",
          "---        expect: hello world",
        ]
        exit_nonzero
      end
    end

    #----------------------------------------

    ## methods: test_stdout_not_equal_CORRECT_2_LINES test_stderr_not_equal_CORRECT_2_LINES

    define_method("test_#{stdxxx}_not_equal_CORRECT_2_LINES") do
      create_CMDTEST_foo [
        "cmd 'echo_#{stdxxx}.rb hello world' do",
        "    #{stdxxx}_not_equal [ 'hello', 'world' ]",
        "end",
      ]

      cmd_cmdtest do
        stdout_equal [
          "### echo_#{stdxxx}.rb hello world",
        ]
      end
    end

    #----------------------------------------

    ## methods: test_stdout_not_equal_INCORRECT_2_LINES test_stderr_not_equal_INCORRECT_2_LINES

    define_method("test_#{stdxxx}_not_equal_INCORRECT_2_LINES") do
      create_CMDTEST_foo [
        "cmd 'echo_#{stdxxx}.rb hello && echo_#{stdxxx}.rb world' do",
        "    #{stdxxx}_not_equal [ 'hello', 'world' ]",
        "end",
      ]

      cmd_cmdtest do
        stdout_equal [
          "### echo_#{stdxxx}.rb hello && echo_#{stdxxx}.rb world",
          "--- ERROR: wrong #{stdxxx}",
          "---        actual: hello",
          "---                world",
          "---        expect: hello",
          "---                world",
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

