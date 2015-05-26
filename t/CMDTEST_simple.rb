
require "selftest_utils"

class CMDTEST_simple < Cmdtest::Testcase

  include SelftestUtils
    
  #-----------------------------------

  def test_get_path
    create_CMDTEST_foo [
      'old = get_path()',
      'cmd "echo $PATH > old.path" do',
      '    created_files "old.path"',
      'end',
      'set_path("extra/dir", *old)',
      'cmd "echo $PATH > new.path" do',
      '    created_files "new.path"',
      'end',
      'cmd "diff -q old.path new.path" do',
      '    exit_nonzero',
      '    stdout_equal /differ/',
      'end',

      'set_path(*old)',
      'cmd "echo $PATH > restored.path" do',
      '    created_files "restored.path"',
      'end',
      'cmd "diff -q old.path restored.path" do',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        "### echo $PATH > old.path",
        "### echo $PATH > new.path",
        "### diff -q old.path new.path",
        "### echo $PATH > restored.path",
        "### diff -q old.path restored.path",
      ]
    end
  end

  #-----------------------------------

  def test_use_chdir
    create_CMDTEST_foo [
      'create_file "dir/file1", ["this is dir/file1"]',
      'chdir("dir")',
      'File.mtime("file1")',    # exception if failing
      'create_file "file2", ["this is dir/file2"]',
      'cmd "cat file1" do',
      '    stdout_equal ["this is dir/file1"]',
      'end',
      'cmd "cat file2" do',
      '    stdout_equal ["this is dir/file2"]',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### cat file1',
        '### cat file2',
      ]
    end
  end

  #-----------------------------------

  def test_try_to_run_non_existing_command_LINUX
    #
    return unless ! windows?
        
    create_CMDTEST_foo [
      'cmd "non-existing" do',
      '    exit_nonzero',
      '    stderr_equal /non-existing: .*not found/',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### non-existing',
      ]
    end
  end

  #-----------------------------------

  def test_try_to_run_non_existing_command_WINDOWS
    #
    return unless windows?

    create_CMDTEST_foo [
      'cmd "non-existing" do',
      '    exit_nonzero',
      '    stderr_equal [',
      '        /non-existing.*not recognized/,',
      '        /program or batch file/,',
      '    ]',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### non-existing',
      ]
    end
  end

  #-----------------------------------

  def test_FAILING_try_to_run_non_existing_command_LINUX
    #
    return unless ! windows?

    create_CMDTEST_foo [
      'cmd "non-existing" do',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### non-existing',
        '--- ERROR: expected zero exit status, got 127',
        '--- ERROR: wrong stderr',
        /---        actual:.*non-existing: .*not found/,
        '---        expect: [[empty]]',
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_FAILING_try_to_run_non_existing_command_WIN32
    #
    return unless windows?

    create_CMDTEST_foo [
      'cmd "non-existing" do',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### non-existing',
        '--- ERROR: expected zero exit status, got 1',
        '--- ERROR: wrong stderr',
        /---        actual:.*non-existing.*not recognized/,
        /---               .*program or batch file/,
        '---        expect: [[empty]]',
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_true_rb_is_archetypic_command__zero_exit_status__no_output
    create_CMDTEST_foo [
      'cmd "true.rb" do',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### true.rb',
      ]
    end
  end

  #-----------------------------------

  def test_true___explicit_exit_zero
    create_CMDTEST_foo [
      'cmd "true.rb" do',
      '    exit_zero',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### true.rb',
      ]
    end
  end

  #-----------------------------------

  def test_true___incorrect_exit_nonzero
    create_CMDTEST_foo [
      'cmd "true.rb" do',
      '    exit_nonzero',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### true.rb',
        '--- ERROR: expected nonzero exit status',
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_true___incorrect_exit_status
    create_CMDTEST_foo [
      'cmd "true.rb" do',
      '    exit_status 18',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### true.rb',
        '--- ERROR: expected 18 exit status, got 0',
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_true___correct_exit_status
    create_CMDTEST_foo [
      'cmd "true.rb" do',
      '    exit_status 0',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### true.rb',
      ]
    end
  end

  #-----------------------------------

  def test_true___incorrect_stdout
    create_CMDTEST_foo [
      'cmd "true.rb" do',
      '    stdout_equal ["hello"]',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### true.rb',
        '--- ERROR: wrong stdout',
        '---        actual: [[empty]]',
        '---        expect: hello',
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_true___correct_stdout
    create_CMDTEST_foo [
      'cmd "true.rb" do',
      '    stdout_equal []',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### true.rb',
      ]
    end
  end

  #-----------------------------------

  def test_true___incorrect_stderr
    create_CMDTEST_foo [
      'cmd "true.rb" do',
      '    stderr_equal ["hello"]',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### true.rb',
        '--- ERROR: wrong stderr',
        '---        actual: [[empty]]',
        '---        expect: hello',
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_true___correct_stderr
    create_CMDTEST_foo [
      'cmd "true.rb" do',
      '    stderr_equal []',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### true.rb',
      ]
    end
  end

  #-----------------------------------

  def test_true___incorrect_created_files_!
    create_CMDTEST_foo [
      'cmd "true.rb" do',
      '    created_files "foo"',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### true.rb',
        '--- ERROR: created files',
        '---        actual: []',
        '---        expect: ["foo"]',
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_true___incorrect_created_files_2
    create_CMDTEST_foo [
      'cmd "true.rb" do',
      '    created_files "foo", "bar"',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### true.rb',
        '--- ERROR: created files',
        '---        actual: []',
        '---        expect: ["bar", "foo"]',
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_true___correct_created_files
    create_CMDTEST_foo [
      'cmd "true.rb" do',
      '    created_files',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### true.rb',
      ]
    end
  end

  #-----------------------------------

  def test_true___incorrect_changed_files_1
    create_CMDTEST_foo [
      'cmd "true.rb" do',
      '    changed_files "foo"',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### true.rb',
        '--- ERROR: changed files',
        '---        actual: []',
        '---        expect: ["foo"]',
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_true___incorrect_changed_files_2
    create_CMDTEST_foo [
      'cmd "true.rb" do',
      '    changed_files "foo", "bar"',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### true.rb',
        '--- ERROR: changed files',
        '---        actual: []',
        '---        expect: ["bar", "foo"]',
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_true___correct_changed_files
    create_CMDTEST_foo [
      'cmd "true.rb" do',
      '    changed_files',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### true.rb',
      ]
    end
  end

  #-----------------------------------

  def test_true___incorrect_removed_files_1
    create_CMDTEST_foo [
      'cmd "true.rb" do',
      '    removed_files "foo"',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### true.rb',
        '--- ERROR: removed files',
        '---        actual: []',
        '---        expect: ["foo"]',
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_true___incorrect_removed_files_2
    create_CMDTEST_foo [
      'cmd "true.rb" do',
      '    removed_files "foo", "bar"',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### true.rb',
        '--- ERROR: removed files',
        '---        actual: []',
        '---        expect: ["bar", "foo"]',
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_true___correct_removed_files
    create_CMDTEST_foo [
      'cmd "true.rb" do',
      '    removed_files',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### true.rb',
      ]
    end
  end

  #======================================================================
  # test - without assertions

  #-----------------------------------

  def test_without_assertions____correct
    create_CMDTEST_foo [
      'cmd "true.rb" do',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### true.rb',
      ]
    end
  end

  #-----------------------------------

  def test_without_assertions____incorrect_exit_status
    create_CMDTEST_foo [
      'cmd "false.rb" do',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### false.rb',
        '--- ERROR: expected zero exit status, got 1',
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_without_assertions____incorrect_stdout
    create_CMDTEST_foo [
      'cmd "echo.rb hello" do',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### echo.rb hello',
        '--- ERROR: wrong stdout',
        '---        actual: hello',
        '---        expect: [[empty]]',
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_without_assertions____incorrect_stderr
    create_CMDTEST_foo [
      'cmd "echo.rb hello >&2" do',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### echo.rb hello >&2',
        '--- ERROR: wrong stderr',
        '---        actual: hello',
        '---        expect: [[empty]]',
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_without_assertions____incorrect_created_files
    create_CMDTEST_foo [
      'cmd "touch.rb new_file" do',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### touch.rb new_file',
        '--- ERROR: created files',
        '---        actual: ["new_file"]',
        '---        expect: []',
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_without_assertions____incorrect_changed_files
    create_CMDTEST_foo [
      'touch_file "changed_file"',
      'cmd "echo.rb ... >> changed_file" do',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### echo.rb ... >> changed_file',
        '--- ERROR: changed files',
        '---        actual: ["changed_file"]',
        '---        expect: []',
      ]
      exit_nonzero
    end
  end

  #-----------------------------------

  def test_without_assertions____incorrect_removed_files
    create_CMDTEST_foo [
      'touch_file "removed_file"',
      'cmd "rm.rb removed_file" do',
      'end',
    ]

    cmd_cmdtest do
      stdout_equal [
        '### rm.rb removed_file',
        '--- ERROR: removed files',
        '---        actual: ["removed_file"]',
        '---        expect: []',
      ]
      exit_nonzero
    end
  end

end
