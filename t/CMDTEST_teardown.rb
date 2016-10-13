
require "selftest_utils"

class CMDTEST_teardown < Cmdtest::Testcase
  include SelftestUtils

  def test_teardown
    create_file "CMDTEST_foo.rb", [
      "class CMDTEST_foo < Cmdtest::Testcase",
      "  def setup",
      "    puts 'setup: ' + Dir.pwd",
      "  end",
      "",
      "  def teardown",
      "    puts 'teardown: ' + Dir.pwd",
      "  end",
      "",
      "  def test_foo",
      "    puts 'test: ' + Dir.pwd",
      "    Dir.mkdir('subdir')",
      "    Dir.chdir('subdir') do",
      "      puts 'test_subdir: ' + Dir.pwd",
      "    end",
      "  end",
      "end",
    ]

    cwd = Dir.pwd
    cmdtest = "#{TOP}/bin/cmdtest.rb"
    command = "ruby %s --quiet" % _quote(cmdtest)
    cmd(command) do
      stdout_equal [
        "setup: #{cwd}/tmp-cmdtest-2/top/work",
        "test: #{cwd}/tmp-cmdtest-2/top/work",
        "test_subdir: #{cwd}/tmp-cmdtest-2/top/work/subdir",
        "teardown: #{cwd}/tmp-cmdtest-2/top/work",
      ]
    end

  end

end
