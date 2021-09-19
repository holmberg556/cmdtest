
require "selftest_utils"

class CMDTEST_shell < Cmdtest::Testcase

  include SelftestUtils

  def test_shell_CORRECT
    create_CMDTEST_foo [
      "shell 'echo.rb 1 2 3 > alpha.txt'",
      "shell 'cp.rb alpha.txt beta.txt'",
      "cmd 'cat.rb beta.txt' do",
      "    exit_zero",
      "    stdout_equal [",
      "        '1 2 3',",
      "    ]",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        '### shell: echo.rb 1 2 3 > alpha.txt',
        '### shell: cp.rb alpha.txt beta.txt',
        '### cat.rb beta.txt',
      ]
    end
  end

  #----------------------------------------

  def test_shell_INCORRECT
    create_CMDTEST_foo [
      "shell 'echo.rb 1 2 3 > alpha.txt'",
      "shell 'cp.rb non-existing.txt beta.txt'",
      "cmd 'cat.rb beta.txt' do",
      "    exit_zero",
      "    stdout_equal [",
      "        '1 2 3',",
      "    ]",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        '### shell: echo.rb 1 2 3 > alpha.txt',
        '### shell: cp.rb non-existing.txt beta.txt',
        '--- ERROR: expected zero exit status, got 1',
        '--- INFO: the stdout',
        '---        actual: cp.rb: error: no such file: non-existing.txt',
        '--- INFO: the stderr',
        '---        actual: [[empty]]',
      ]
      exit_nonzero
    end
  end

  #----------------------------------------

  def test_shell_INCORRECT_EXIT_ONLY
    create_CMDTEST_foo [
      "shell 'echo.rb 1 2 3 > alpha.txt'",
      "shell 'cp.rb alpha.txt beta.txt && exit.rb 1'",
      "cmd 'cat.rb beta.txt' do",
      "    exit_zero",
      "    stdout_equal [",
      "        '1 2 3',",
      "    ]",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        '### shell: echo.rb 1 2 3 > alpha.txt',
        '### shell: cp.rb alpha.txt beta.txt && exit.rb 1',
        '--- ERROR: expected zero exit status, got 1',
        '--- INFO: the stdout',
        '---        actual: [[empty]]',
        '--- INFO: the stderr',
        '---        actual: [[empty]]',
      ]
      exit_nonzero
    end
  end

  #----------------------------------------

end
