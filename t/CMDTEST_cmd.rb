
require "selftest_utils"

class CMDTEST_cmd < Cmdtest::Testcase

  include SelftestUtils

  #----------------------------------------
  # use of "cmd"
  #----------------------------------------


  def test_cmd_array_argument
    create_CMDTEST_foo [
      "cmd ['lines.rb', 'this is an argument', 'and another'] do",
      "    stdout_equal [",
      "        'this is an argument',",
      "        'and another',",
      "    ]",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        '### lines.rb "this is an argument" "and another"',
      ]
    end
  end

  #-----------------------------------

  def test_cmd_only_some_arguments_need_quoting
    create_CMDTEST_foo [
    "cmd ['lines.rb', 'arg1', 'a r g 2', '<arg3>'] do",
    "    stdout_equal [",
    "        'arg1',",
    "        'a r g 2',",
    "        '<arg3>',",
    "    ]",
    "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        '### lines.rb arg1 "a r g 2" "<arg3>"',
      ]
    end
  end

  #-----------------------------------

  def test_cmd_array_with_no_arguments
    create_CMDTEST_foo [
      "cmd ['true.rb'] do",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
      ]
    end
  end

  #-----------------------------------

  def test_array_with_no_arguments_II
    create_CMDTEST_foo [
      "cmd ['false.rb'] do",
      "    exit_nonzero",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### false.rb",
      ]
    end
  end

  #-----------------------------------

  def test_array_with_QQ_and_BACKSLASH_in_arguments
    create_CMDTEST_foo <<'_END_'
      cmd ["clines", "emb\"edded 1", "emb\\edded 2", "emb\\edd\"ed 3"] do
          stdout_equal [
              "emb\"edded 1",
              "emb\\edded 2",
              "emb\\edd\"ed 3",
          ]
      end
_END_

    cmd_cmdtest do
      stdout_equal [
        /### .*clines.*/,
      ]
    end
  end

  #-----------------------------------

  def test_array_with_DOLLAR_arguments_1
    create_CMDTEST_foo <<'_END_'
      cmd ["clines", "emb$edded 1", "emb$$edded 2"] do
          stdout_equal [
              "emb$edded 1",
              "emb$$edded 2",
          ]
      end
_END_

    cmd_cmdtest do
      stdout_equal [
        /### .*clines.*/,
      ]
    end
  end

  #-----------------------------------

  def test_array_with_DOLLAR_arguments_2
    #
    return unless RUBY_PLATFORM =~ /mswin32/

    create_CMDTEST_foo <<'_END_'
      cmd ["clines", "emb$edded1", "emb$$edded2"] do
          stdout_equal [
              "emb$edded1",
              "emb$$edded2",
          ]
      end
_END_

    cmd_cmdtest do
      stdout_equal [
        "### clines \"emb$edded1\" \"emb$$edded2\"",
      ]
    end
  end

  #-----------------------------------

  def test_cmd_all_characters
    # (but not backslash for now)
    #
    return unless RUBY_PLATFORM !~ /mswin32/

    create_CMDTEST_foo <<'_END_'
      all = " !\"\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_abcdefghijklmnopqrstuvwxyz{|}~"
      cmd ["lines.rb", all] do
          stdout_equal [
              " !\"\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_abcdefghijklmnopqrstuvwxyz{|}~"
          ]
      end
_END_

    cmd_cmdtest do
      stdout_equal <<'_END_'
### lines.rb " !\"#\$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_abcdefghijklmnopqrstuvwxyz{|}~"
_END_
    end
  end

  #-----------------------------------

  def test_BACKSLASH_character
    create_CMDTEST_foo [
      "all = \" ` \"",
      "cmd [\"lines.rb\", all] do",
      "    stdout_equal [",
      "        \" ` \",",
      "    ]",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        /### .*lines.*/,
      ]
    end
  end

end
