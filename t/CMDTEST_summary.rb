
require "selftest_utils"

class CMDTEST_summery < Cmdtest::Testcase

  include SelftestUtils

  #-----------------------------------

  def test_summary

    create_file "CMDTEST_foo.rb", [
      "class CMDTEST_foo1 < Cmdtest::Testcase",
      "  def setup",
      "    prepend_path #{BIN.inspect}",
      "    prepend_path #{PLATFORM_BIN.inspect}",
      "  end",
      "",

      '  def test_foo1',
      '    cmd "true" do',
      '      exit_zero',
      '    end',
      '    cmd "true" do',
      '      exit_zero',
      '    end',
      '    cmd "true" do',
      '      exit_zero',
      '    end',
      '    cmd "true" do',
      '      exit_nonzero',     # +1 errors
      '    end',
      '  end',
      '',
      '  def test_foo2',
      '    cmd "true" do',
      '      exit_zero',
      '    end',
      '    non_existing_method', # +1 fatals
      '  end',
      '',
      '  def test_foo3',
      '    cmd "true" do',
      '      exit_zero',
      '    end',
      '    non_existing_method', # +1 fatals
      '  end',
      '',
      '  def test_foo4',
      '    cmd "true" do',
      '      exit_nonzero',     # +1 errors
      '    end',
      '  end',
      '',
      '  def test_foo5',
      '    cmd "true" do',
      '      exit_nonzero',     # +1 errors
      '    end',
      '  end',
      '',
      'end',
    ]

    cmd_cmdtest_verbose do
      stdout_equal /. 1 test classes/
      stdout_equal /. 5 test methods/
      stdout_equal /. 8 commands/
      stdout_equal /. 3 errors/
      stdout_equal /. 2 fatals/
      exit_nonzero
    end
  end

end
