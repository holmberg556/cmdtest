
require "selftest_utils"

class CMDTEST_junit < Cmdtest::Testcase

  include SelftestUtils

  def make_files(cmd="true")
    create_file "CMDTEST_foo.rb", [
      "class CMDTEST_foo1 < Cmdtest::Testcase",
      "  def setup",
      "    prepend_path #{BIN.inspect}",
      "    prepend_path #{PLATFORM_BIN.inspect}",
      "  end",
      "",

      '  def test_foo1',
      '    cmd "%s" do' % cmd,
      '    end',
      '  end',
      '',
      'end',
    ]
  end

  def test_1
    make_files("echo_ctrl_chars.rb 1:5 27:32")
    
    cmd_cmdtest_verbose "--quiet --xml=tmp.xml" do
      exit_nonzero
      stdout_contain [
        "### echo_ctrl_chars.rb 1:5 27:32",
        "--- ERROR: wrong stdout",
        /--- \^A --- \x01 ---/,
        /--- \^B --- \x02 ---/,
      ]
      created_files "tmp.xml"
      file_equal "tmp.xml", /--- \^A --- \^A ---/
      file_equal "tmp.xml", /--- \^B --- \^B ---/
      file_equal "tmp.xml", /--- \^\[ --- \^\[ ---/
    end

  end

end
