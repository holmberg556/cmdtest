# coding: utf-8

require "selftest_utils"

class CMDTEST_output_encoding < Cmdtest::Testcase

  include SelftestUtils

  def test_output_encoding_ASCII_DEFAULT
    create_CMDTEST_foo [
      'cmd "echo.rb raksmorgas" do',
      '    comment "ok"',
      '    stdout_equal "raksmorgas\n"',
      'end',
      'cmd "echo.rb räksmörgås" do',
      '    comment "error"',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        "### ok",
        "### error",
        "--- ERROR: unexpected encoding: STDOUT not 'ascii'",
      ]
      exit_nonzero
    end
  end

  def test_output_encoding_UTF8_GLOBAL
    create_CMDTEST_foo [
      'output_encoding "utf-8"',
      'cmd "echo.rb raksmorgas" do',
      '    comment "ok ascii"',
      '    stdout_equal "raksmorgas\n"',
      'end',
      'cmd "echo.rb räksmörgås" do',
      '    comment "ok utf8"',
      '    stdout_equal "räksmörgås\n"',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        "### ok ascii",
        "### ok utf8",
      ]
    end
  end

  def test_output_encoding_UTF8_DOBLOCK
    create_CMDTEST_foo [
      'cmd "echo.rb räksmörgås" do',
      '    comment "ok in doblock"',
      '    output_encoding "utf-8" do',
      '        stdout_equal "räksmörgås\n"',
      '    end',
      'end',
      'cmd "echo.rb räksmörgås" do',
      '    comment "error outside doblock"',
      '    stdout_equal "räksmörgås\n"',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        "### ok in doblock",
        "### error outside doblock",
        "--- ERROR: unexpected encoding: STDOUT not 'ascii'",
      ]
      exit_nonzero
    end
  end


end
