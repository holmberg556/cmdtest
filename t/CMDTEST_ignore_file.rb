
require "selftest_utils"

class CMDTEST_ignore_file < Cmdtest::Testcase

  include SelftestUtils

  #----------------------------------------
  # an ignored file is not counted as a created file
  # even when it is actually created

  def test_ignore_file_IGNORED
    create_CMDTEST_foo [
      "ignore_file 'bbb'",
      "",
      "cmd 'touch.rb aaa bbb' do",
      "  created_files 'aaa'",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### touch.rb aaa bbb",
      ]
    end
  end

  #----------------------------------------
  # it is ok for an ignored file to not be created

  def test_ignore_file_IGNORED_NOT_CREATED
    create_CMDTEST_foo [
      "ignore_file 'bbb'",
      "",
      "cmd 'touch.rb aaa' do",
      "  created_files 'aaa'",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### touch.rb aaa",
      ]
    end
  end

  #----------------------------------------
  # 'created_files' is wrong if the file is mentioned,
  # even when the file actually was created

  def test_ignore_file_AS_IF_NOT_CREATED
    create_CMDTEST_foo [
      "ignore_file 'bbb'",
      "",
      "cmd 'touch.rb aaa bbb' do",
      "  created_files 'aaa', 'bbb'",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        '### touch.rb aaa bbb',
        '--- ERROR: created files',
        '---        actual: ["aaa"]',
        '---        expect: ["aaa", "bbb"]',
      ]
      exit_nonzero
    end
  end

  #----------------------------------------
  # the ignored file can have a directory component in the filename

  def test_ignore_file_IGNORED_IN_SUBDIR
    create_CMDTEST_foo [
      "ignore_file 'dir/bbb'",
      "dir_mkdir 'dir'",
      "",
      "cmd 'touch.rb aaa bbb dir/aaa dir/bbb' do",
      "  created_files 'aaa', 'bbb', 'dir/aaa'",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### touch.rb aaa bbb dir/aaa dir/bbb",
      ]
    end
  end

  #----------------------------------------
  # the argument to 'ignore_file' is the *path* to a file,
  # not just the basename.

  def test_ignore_file_PATH_MATTERS
    create_CMDTEST_foo [
      "ignore_file 'bbb'",
      "dir_mkdir 'dir'",
      "",
      "cmd 'touch.rb aaa bbb dir/aaa dir/bbb' do",
      "  created_files 'aaa', 'dir/aaa', 'dir/bbb'",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### touch.rb aaa bbb dir/aaa dir/bbb",
      ]
    end
  end

end
