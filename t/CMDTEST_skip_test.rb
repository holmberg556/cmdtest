
require "selftest_utils"

class CMDTEST_skip_test < Cmdtest::Testcase

  include SelftestUtils

  def test_skip_test
    create_CMDTEST_foo [
      "skip_test 'FooBar platform only' if true",
      "cmd 'false.rb' do",
      "end",
    ]
    cmd_cmdtest do
      stdout_equal [
        '--- SKIP: FooBar platform only',
      ]
    end
  end

end
