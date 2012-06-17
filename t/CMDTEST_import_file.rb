
require "selftest_utils"

class CMDTEST_import_file < Cmdtest::Testcase

  include SelftestUtils

  #----------------------------------------
  # import_file
  #----------------------------------------

  def test_import_file_DIFFERENT_DIRS
    create_file "file1.txt", "This is file1.txt\n"
    create_file "file2.txt", "This is file2.txt\n"

    create_CMDTEST_foo [
      "import_file 'file1.txt', 'qwerty1.txt'",
      "import_file 'file2.txt', 'subdir/qwerty2.txt'",
      "",
      "cmd 'cat.rb qwerty1.txt subdir/qwerty2.txt' do",
      "    stdout_equal [",
      "        'This is file1.txt',",
      "        'This is file2.txt',",
      "    ]",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### cat.rb qwerty1.txt subdir/qwerty2.txt",
      ]
    end
  end

  #----------------------------------------

  def test_import_file_AFTER_CHDIR
    create_file "file1.txt", "This is file1.txt\n"
    create_file "file2.txt", "This is file2.txt\n"

    create_CMDTEST_foo [
      "dir_mkdir('dir')",
      "chdir('dir')",
      "import_file 'file1.txt', 'qwerty1.txt'",
      "import_file 'file2.txt', 'subdir/qwerty2.txt'",
      "",
      "cmd 'cat.rb qwerty1.txt subdir/qwerty2.txt' do",
      "    stdout_equal [",
      "        'This is file1.txt',",
      "        'This is file2.txt',",
      "    ]",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### cat.rb qwerty1.txt subdir/qwerty2.txt",
      ]
    end
  end

end
