
require "selftest_utils"

class CMDTEST_dont_ignore_files < Cmdtest::Testcase

  include SelftestUtils

  #----------------------------------------
  # a filename can be made "visible",
  # overriding an earlier "ignore_files" command

  def test_dont_ignore_files
    create_CMDTEST_foo [
      "ignore_files 'dir/'",
      "dont_ignore_files 'dir/f1'",
      "",
      "create_file 'dir/empty', ''",
      "",
      "cmd 'touch.rb dir/f1 dir/f2' do",
      "  created_files 'dir/f1'",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### touch.rb dir/f1 dir/f2",
      ]
    end
  end

  #----------------------------------------
  # works for wildcards too

  def test_dont_ignore_files_WILDCARD
    create_CMDTEST_foo [
      "ignore_files '**/f*'",
      "dont_ignore_files '**/*1'",
      "",
      "create_file 'dir/empty', ''",
      "",
      "cmd 'touch.rb dir/f1 dir/f2' do",
      "  created_files 'dir/f1'",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### touch.rb dir/f1 dir/f2",
      ]
    end
  end

end
