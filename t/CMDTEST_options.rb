
require "selftest_utils"

class CMDTEST_options < Cmdtest::Testcase

  include SelftestUtils

  def make_files(cmd="true")
    create_file "CMDTEST_foo.rb", [
      "class CMDTEST_foo1 < Cmdtest::Testcase",
      "  def setup",
      "    prepend_path #{BIN.inspect}",
      "    prepend_path #{PLATFORM_BIN.inspect}",
      "  end",
      "",

      '  def test_foo1',
      '    cmd "%s" do' % cmd,
      '      exit_zero',
      '    end',
      '  end',
      '',
      'end',
    ]
  end

  #-----------------------------------

  def test_option_quiet
    make_files

    cmd_cmdtest_verbose "--quiet" do
      stdout_equal [
        "### true",
      ]
    end

    cmd_cmdtest_verbose do
      stdout_equal /.===== CMDTEST_foo.rb/
      stdout_equal /.----- CMDTEST_foo1$/
      stdout_equal /.\.\.\.\.\. test_foo1$/
      stdout_equal /test methods, \d+ commands, \d+ errors,/
    end
  end

  def test_option_verbose
    make_files

    cmd_cmdtest_verbose "--verbose" do
      stdout_equal /^### \.\.\.$/
    end
  end

  def test_option_xml
    make_files

    cmd_cmdtest_verbose "--quiet --xml=tmp.xml" do
      stdout_equal [
        "### true",
      ]
      created_files "tmp.xml"
    end
  end

  def test_option_incremental
    make_files

    cmd_cmdtest_verbose "--quiet -i" do
      stdout_equal [
        "### true",
      ]
    end

    cmd_cmdtest_verbose "--quiet -i" do
      stdout_equal [
      ]
    end

    make_files("false")

    cmd_cmdtest_verbose "--quiet -i" do
      stdout_equal [
        '### false',
        '--- ERROR: expected zero exit status, got 1',
      ]
      exit_nonzero
    end

    cmd_cmdtest_verbose "--quiet -i" do
      stdout_equal [
        '### false',
        '--- ERROR: expected zero exit status, got 1',
      ]
      exit_nonzero
    end
  end

  def test_option_no_exit_code
    make_files("false")

    cmd_cmdtest_verbose "--quiet --no-exit-code" do
      stdout_equal [
        '### false',
        '--- ERROR: expected zero exit status, got 1',
      ]
    end

    cmd_cmdtest_verbose "--quiet" do
      stdout_equal [
        '### false',
        '--- ERROR: expected zero exit status, got 1',
      ]
      exit_nonzero
    end
  end

  def test_option_help
    cmd_cmdtest_verbose "-h" do
      stdout_equal /^usage: cmdtest /
      stdout_equal /^\s+-h, --help\s+show this help/
    end

    cmd_cmdtest_verbose "--help" do
      stdout_equal /^usage: cmdtest /
      stdout_equal /^\s+-h, --help\s+show this help/
    end
  end

end
