
require "selftest_utils"

class CMDTEST_chdir < Cmdtest::Testcase

  include SelftestUtils

  # The Ruby builtin "Dir.chdir" and "chdir" from "cmdtest"
  # can be used in a test-method. In both cases the following
  # should happen:
  #
  # - the "current directory" of the "cmdtest" Ruby process should be set,
  #   so later code in the samne test-method can rely on the new
  #   current directory.
  #
  # - when a command is executed with "cmd", it should get the same
  #   current directory as the "cmdtest" Ruby process.
  #

  # without any "chdir"
  def test_chdir_NONE
    create_CMDTEST_foo [
      "create_file 'SUBDIR/.flagfile', ''",
      "puts Dir.pwd",
    ]
    cmd_cmdtest do
      stdout_equal /^\/.*\/top\/work$/

    end
  end

  # "chdir" to a subdirectory
  def test_chdir_SUBDIR
    create_CMDTEST_foo [
      "create_file 'SUBDIR/.flagfile', ''",
      "chdir 'SUBDIR'",
      "puts Dir.pwd",
    ]
    cmd_cmdtest do
      stdout_equal /^\/.*\/top\/work\/SUBDIR$/

    end
  end

  # "Dir.chdir" to a subdirectory
  def test_dir_chdir_SUBDIR
    create_CMDTEST_foo [
      "create_file 'SUBDIR/.flagfile', ''",
      "Dir.chdir 'SUBDIR'",
      "puts Dir.pwd",
    ]
    cmd_cmdtest do
      stdout_equal /^\/.*\/top\/work\/SUBDIR$/

    end
  end

  # "cmd" after no "chdir"
  def test_chdir_NONE_cmd
    create_CMDTEST_foo [
      "create_file 'SUBDIR/.flagfile', ''",
      "cmd 'echo_pwd.rb' do",
      "    stdout_equal /^PWD=\\/.*\\/top\\/work$/",
      "end",
    ]
    cmd_cmdtest do
      stdout_equal [
        "### echo_pwd.rb",
      ]
    end
  end

  # "cmd" after "chdir"
  def test_chdir_SUBDIR_cmd
    create_CMDTEST_foo [
      "create_file 'SUBDIR/.flagfile', ''",
      "chdir 'SUBDIR'",
      "cmd 'echo_pwd.rb' do",
      "    stdout_equal /^PWD=\\/.*\\/top\\/work\\/SUBDIR$/",
      "end",
    ]
    cmd_cmdtest do
      stdout_equal [
        "### echo_pwd.rb",
      ]
    end
  end

  # "cmd" after "Dir.chdir"
  def test_dir_chdir_SUBDIR_cmd
    create_CMDTEST_foo [
      "create_file 'SUBDIR/.flagfile', ''",
      "Dir.chdir 'SUBDIR'",
      "cmd 'echo PWD=$(pwd)' do",
      "    stdout_equal /^PWD=\\/.*\\/top\\/work\\/SUBDIR$/",
      "end",
    ]
    cmd_cmdtest do
      stdout_equal [
        "### echo PWD=$(pwd)",
      ]
    end
  end

  # "create_file" after "Dir.chdir"
  def test_dir_chdir_SUBDIR_create_file
    create_CMDTEST_foo [
      "create_file 'SUBDIR/f0.txt', ''",
      "create_file 'f1.txt', ''",
      "Dir.chdir 'SUBDIR'",
      "create_file 'f2.txt', ''",
      "Dir.chdir '..'",
      "cmd 'find_files.rb' do",
      "    stdout_equal [",
      "        './SUBDIR/f0.txt',",
      "        './SUBDIR/f2.txt',",
      "        './f1.txt',",
      "    ]",
      "end",
    ]
    cmd_cmdtest do
      stdout_equal [
        "### find_files.rb",
      ]
    end
  end

end
