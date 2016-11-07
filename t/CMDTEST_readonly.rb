
require "selftest_utils"

class CMDTEST_readonly < Cmdtest::Testcase

  include SelftestUtils

  def teardown
    if ! Cmdtest::Util.windows?
      File.chmod(0755, 'tmp-cmdtest-2/top/work/a_subdir')
    end
  end

  def test_readonly
    return if Cmdtest::Util.windows?

    create_CMDTEST_foo [
      "cmd 'true.rb' do",
      "end",
      "Dir.mkdir('a_subdir')",
      "File.open('a_subdir/file1', 'w') {|f| f.puts 123}",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
      ]
    end

    File.chmod(0555, 'tmp-cmdtest-2/top/work/a_subdir')

    cmd_cmdtest do
      stderr_equal /Directory not empty/
      exit_nonzero
    end
  end


end
