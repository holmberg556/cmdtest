require "selftest_utils"

class CMDTEST_setenv < Cmdtest::Testcase

  include SelftestUtils

  #-----------------------------------

  def test_setenv
    #----------
    create_CMDTEST_foo [
      'cmd "env.rb | grep.rb TESTVAR1" do',
      '  exit_nonzero', # no match in grep.rb
      'end',
    ]
    cmd_cmdtest do
      comment "TESTVAR1 not set"
      stdout_equal [
        "### env.rb | grep.rb TESTVAR1",
      ]
    end

    #----------
    create_CMDTEST_foo [
      'setenv "TESTVAR1", "123456"',
      'cmd "env.rb | grep.rb TESTVAR1" do',
      '  stdout_equal "TESTVAR1=123456\\n"',
      'end',
    ]
    cmd_cmdtest do
      comment "TESTVAR1 set by setenv"
      stdout_equal [
        "### env.rb | grep.rb TESTVAR1",
      ]
    end

    prepend_path 't/bin'

    cmd("env.rb | grep.rb TESTVAR1") do
      comment "TESTVAR1 still unset on level1"
      exit_nonzero # no match in grep.rb
    end
  end

  #-----------------------------------

  def test_unsetenv
    ENV['TESTVAR2'] = '987654'
    #----------
    create_CMDTEST_foo [
      'cmd "env.rb | grep.rb TESTVAR2" do',
      '  stdout_equal "TESTVAR2=987654\\n"',
      'end',
    ]
    cmd_cmdtest do
      comment "TESTVAR2 set from start"
      stdout_equal [
        "### env.rb | grep.rb TESTVAR2",
      ]
    end

    #----------
    create_CMDTEST_foo [
      'unsetenv "TESTVAR2"',
      'cmd "env.rb | grep.rb TESTVAR2" do',
      '  exit_nonzero', # no match in grep.rb
      'end',
    ]
    cmd_cmdtest do
      comment "TESTVAR2 unset by unsetenv"
      stdout_equal [
        "### env.rb | grep.rb TESTVAR2",
      ]
    end

    prepend_path 't/bin'

    cmd("env.rb | grep.rb TESTVAR2") do
      comment "TESTVAR2 still set on level1"
      stdout_equal [
        "TESTVAR2=987654",
      ]
    end
  end

end

