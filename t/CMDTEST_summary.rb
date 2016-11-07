
require "selftest_utils"

class CMDTEST_summery < Cmdtest::Testcase

  include SelftestUtils

  #-----------------------------------

  def test_summary_ERRORS

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
      '  def test_skip_1',
      '    skip_test "skip_1"',
      '    never_called()',
      '  end',
      '',
      '  def test_skip_2',
      '    skip_test "skip_2"',
      '    never_called()',
      '  end',
      '',
      '  def test_skip_3',
      '    skip_test "skip_3"',
      '    never_called()',
      '  end',
      '',
      '  def test_skip_4',
      '    skip_test "skip_4"',
      '    never_called()',
      '  end',
      '',
      'end',
    ]

    cmd_cmdtest_verbose do
      stdout_equal /^--- .* test classes,.*test methods,.*commands,.*skipped,.*errors,.*fatals\.$/
      stdout_equal /. 1 test classes/
      stdout_equal /. 9 test methods/
      stdout_equal /. 8 commands/
      stdout_equal /. 4 skipped/
      stdout_equal /. 3 errors/
      stdout_equal /. 2 fatals/
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_summary_OK

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
      '      exit_zero',
      '    end',
      '  end',
      '',
      '  def test_foo2',
      '    cmd "true" do',
      '      exit_zero',
      '    end',
      '  end',
      '',
      '  def test_foo3',
      '    cmd "true" do',
      '      exit_zero',
      '    end',
      '  end',
      '',
      '  def test_foo4',
      '    cmd "true" do',
      '      exit_zero',
      '    end',
      '  end',
      '',
      '  def test_foo5',
      '    cmd "true" do',
      '      exit_zero',
      '    end',
      '  end',
      '',
      'end',
    ]

    cmd_cmdtest_verbose do
      stdout_equal /^### .* test classes,.*test methods,.*commands,.*errors,.*fatals\.$/
      stdout_equal /. 1 test classes/
      stdout_equal /. 5 test methods/
      stdout_equal /. 8 commands/
      stdout_equal /. 0 errors/
      stdout_equal /. 0 fatals/
      exit_zero
    end
  end

end
