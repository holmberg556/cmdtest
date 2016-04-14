
require "selftest_utils"

class CMDTEST_import_directory < Cmdtest::Testcase

  include SelftestUtils

  #----------------------------------------
  # import_directory
  #----------------------------------------

  def test_import_directory_ERROR
    create_file "file1.dir/file1.txt", "This is file1.dir/file1.txt\n"
    create_file "file2.dir/file2.txt", "This is file2.dir/file2.txt\n"

    create_CMDTEST_foo [
      "import_directory 'file1.dir', 'qwerty1.dir'",
      "import_directory 'file2.dir', 'qwerty1.dir'",
    ]

    cmd_cmdtest do
      stdout_equal /CAUGHT EXCEPTION:/
      stdout_equal /'import_directory' target argument already exist: 'qwerty1.dir'/
      exit_nonzero
    end
  end

  #----------------------------------------

  def test_import_directory_DIFFERENT_DIRS
    create_file "file1.dir/file1.txt", "This is file1.dir/file1.txt\n"
    create_file "file2.dir/file2.txt", "This is file2.dir/file2.txt\n"

    create_CMDTEST_foo [
      "import_directory 'file1.dir', 'qwerty1.dir'",
      "import_directory 'file2.dir', 'subdir/qwerty2.dir'",
      "",
      "cmd 'cat.rb qwerty1.dir/file1.txt subdir/qwerty2.dir/file2.txt' do",
      "    stdout_equal [",
      "        'This is file1.dir/file1.txt',",
      "        'This is file2.dir/file2.txt',",
      "    ]",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### cat.rb qwerty1.dir/file1.txt subdir/qwerty2.dir/file2.txt",
      ]
    end
  end

  #----------------------------------------

  def test_import_directory_AFTER_CHDIR
    create_file "file1.dir/file1.txt", "This is file1.dir/file1.txt\n"
    create_file "file2.dir/file2.txt", "This is file2.dir/file2.txt\n"

    create_CMDTEST_foo [
      "dir_mkdir('dir')",
      "chdir('dir')",
      "import_directory 'file1.dir', 'qwerty1.dir'",
      "import_directory 'file2.dir', 'subdir/qwerty2.dir'",
      "",
      "cmd 'cat.rb qwerty1.dir/file1.txt subdir/qwerty2.dir/file2.txt' do",
      "    stdout_equal [",
      "        'This is file1.dir/file1.txt',",
      "        'This is file2.dir/file2.txt',",
      "    ]",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### cat.rb qwerty1.dir/file1.txt subdir/qwerty2.dir/file2.txt",
      ]
    end
  end

end
