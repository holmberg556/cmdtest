
require "selftest_utils"

class CMDTEST_readonly < Cmdtest::Testcase

  include SelftestUtils

  def teardown
    File.chmod(0755, 'tmp-cmdtest-2/top/work/a_subdir')
  end

  def test_readonly
    create_CMDTEST_foo [
      "cmd 'true.rb' do",
      "end",
      "Dir.mkdir('a_subdir')",
      "File.open('a_subdir/file1', 'w') {|f| f.puts 123}",
      "File.chmod(0, 'a_subdir')",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
      ]
    end

    cmd_cmdtest do
      stderr_equal /Directory not empty/
      exit_nonzero
    end
  end

end
