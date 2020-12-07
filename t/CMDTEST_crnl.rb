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
          "--- ERROR: wrong stdout",
          "---        actual: 1\\r",
          "---                2\\r",
          "---        expect: 1",
          "---                2",
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
        "--- ERROR: wrong stdout",
        "---        actual: 1",
        "---                2\\r",
        "---        expect: [[empty]]",
      ]
      exit_nonzero
    end
  end

  def test_crnl_EXPECTED
    create_CMDTEST_foo [
      'cmd "echo_crnl.rb 1:rn 2:rn" do',
      '    comment "windows line endings"',
      '    output_newline "\r\n" do',
      '      stdout_equal "1\n2\n"',
      '    end',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        "### windows line endings",
      ]
    end
  end

  def test_crnl_NOT_EXPECTED
    create_CMDTEST_foo [
      'cmd "echo_crnl.rb 1:rn 2:rn" do',
      '    comment "windows line endings"',
      '    output_newline "\n" do',
      '      stdout_equal "1\n2\n"',
      '    end',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        "### windows line endings",
        "--- ERROR: Windows line ending: STDOUT",
        "--- ERROR: wrong stdout",
        "---        actual: 1\\r",
        "---                2\\r",
        "---        expect: 1",
        "---                2",
      ]
      exit_nonzero
    end
  end

  def test_nl_EXPECTED
    create_CMDTEST_foo [
      'cmd "echo_crnl.rb 1:n 2:n" do',
      '    comment "linux line endings"',
      '    output_newline "\n" do',
      '      stdout_equal "1\n2\n"',
      '    end',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        "### linux line endings",
      ]
    end
  end

  def test_nl_NOT_EXPECTED
    create_CMDTEST_foo [
      'cmd "echo_crnl.rb 1:n 2:n" do',
      '    comment "linux line endings"',
      '    output_newline "\r\n" do',
      '      stdout_equal "1\n2\n"',
      '    end',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        "### linux line endings",
        "--- ERROR: UNIX line ending: STDOUT",
      ]
      exit_nonzero
    end
  end

  def test_unknown_OUTPUT_NEWLINE
    create_CMDTEST_foo [
      'cmd "echo_crnl.rb 1:n 2:n" do',
      '    comment "linux line endings"',
      '    output_newline "foobar" do',
      '      stdout_equal "1\n2\n"',
      '    end',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal /unkown newline type: "foobar"/
      exit_nonzero
    end
  end

  def test_CONSISTENT_EXPECTED_nl
    create_CMDTEST_foo [
      'cmd "echo_crnl.rb 1:n 2:n" do',
      '    comment "consistent line endings"',
      '    output_newline :consistent do',
      '      stdout_equal "1\n2\n"',
      '    end',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        "### consistent line endings",
      ]
    end
  end

  def test_CONSISTENT_EXPECTED_crnl
    create_CMDTEST_foo [
      'cmd "echo_crnl.rb 1:rn 2:rn" do',
      '    comment "consistent line endings"',
      '    output_newline :consistent do',
      '      stdout_equal "1\n2\n"',
      '    end',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        "### consistent line endings",
      ]
    end
  end

  def test_CONSISTENT_EXPECTED_mixed
    create_CMDTEST_foo [
      'cmd "echo_crnl.rb 1:rn 2:n" do',
      '    comment "consistent line endings"',
      '    output_newline :consistent do',
      '      stdout_equal "1\n2\n"',
      '    end',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        "### consistent line endings",
        "--- ERROR: mixed line ending: STDOUT",
        "--- ERROR: wrong stdout",
        "---        actual: 1\\r",
        "---                2",
        "---        expect: 1",
        "---                2",
        ]
      exit_nonzero
    end
  end

end
