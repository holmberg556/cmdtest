
require "selftest_utils"

class CMDTEST_raise < Cmdtest::Testcase

  include SelftestUtils

  def test_raise_TEST
    create_file "CMDTEST_foo.rb", [
      "class CMDTEST_foo < Cmdtest::Testcase",
      "  def setup",
      "    raise 'error in setup' if ENV['CMDTEST_RAISE'] == 'setup'",
      "  end",
      "",
      "  def teardown",
      "    raise 'error in teardown' if ENV['CMDTEST_RAISE'] == 'teardown'",
      "  end",
      "",
      "  def test_foo",
      "    raise 'error in test' if ENV['CMDTEST_RAISE'] == 'test'",
      "    puts '123'",
      "  end",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "123",
      ]
    end

    ENV['CMDTEST_RAISE'] = 'setup'
    cmd_cmdtest do
      exit_nonzero
      stdout_equal /--- CAUGHT EXCEPTION:/
      stdout_equal /---   error in setup/
    end

    ENV['CMDTEST_RAISE'] = 'test'
    cmd_cmdtest do
      exit_nonzero
      stdout_equal /--- CAUGHT EXCEPTION:/
      stdout_equal /---   error in test/
    end

    ENV['CMDTEST_RAISE'] = 'teardown'
    cmd_cmdtest do
      exit_nonzero
      stdout_equal /--- CAUGHT EXCEPTION:/
      stdout_equal /---   error in teardown/
    end

    ENV['CMDTEST_RAISE'] = nil
    cmd_cmdtest do
      stdout_equal "123\n"
    end
  end

end
