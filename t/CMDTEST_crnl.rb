# coding: utf-8

require "selftest_utils"

class CMDTEST_crnl < Cmdtest::Testcase

  include SelftestUtils

  def test_crnl
    create_CMDTEST_foo [
      'cmd "echo_crnl.rb 1:rn 2:rn" do',
      '    comment "windows line endings"',
      '    stdout_equal "1\n2\n"',
      'end',
    ]

    if Cmdtest::Util.windows?
      cmd_cmdtest do
        stdout_equal [
          "### windows line endings",
        ]
      end
    else
      cmd_cmdtest do
        stdout_equal [
          "### windows line endings",
          "--- ERROR: Windows line ending: STDOUT",
        ]
        exit_nonzero
      end
    end
  end

  def test_nl
    create_CMDTEST_foo [
      'cmd "echo_crnl.rb 1:n 2:n" do',
      '    comment "unix line endings"',
      '    stdout_equal "1\n2\n"',
      'end',
    ]

    if Cmdtest::Util.windows?
      cmd_cmdtest do
        stdout_equal [
          "### unix line endings",
          "--- ERROR: UNIX line ending: STDOUT",
        ]
        exit_nonzero
      end
    else
      cmd_cmdtest do
        stdout_equal [
          "### unix line endings",
        ]
      end
    end
  end

  def test_crnl_and_nl
    create_CMDTEST_foo [
      'cmd "echo_crnl.rb 1:n 2:rn" do',
      '    comment "mixed line endings"',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        "### mixed line endings",
        "--- ERROR: mixed line ending: STDOUT",
      ]
      exit_nonzero
    end
  end

end
