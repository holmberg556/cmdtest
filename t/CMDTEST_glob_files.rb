
require "selftest_utils"

class CMDTEST_glob_files < Cmdtest::Testcase

  include SelftestUtils

  def make_file(name)
    create_file "t/CMDTEST_#{name}.rb", [
      "class CMDTEST_#{name} < Cmdtest::Testcase",
      "  def setup",
      "    prepend_path #{BIN.inspect}",
      "    prepend_path #{PLATFORM_BIN.inspect}",
      "  end",
      "",

      "  def test_1",
      "    cmd \"true\" do",
      "      comment \"#{name}\"",
      "    end",
      "  end",
      "",
      "end",
    ]
  end

  def test_1
    make_file("aaa")
    make_file("ccc")
    make_file("bbb")
    make_file("ddd")

    cmd_cmdtest do
      stdout_equal [
        "### aaa",
        "### bbb",
        "### ccc",
        "### ddd",
      ]
    end
  end

  def test_2
    # generate "aaa", "aab", "aac", ...
    names = (1..30).reduce(["aaa"]) {|acc, i| acc << acc[-1].succ }
    for name in names.shuffle(random: Random.new(1234))
      make_file(name)
    end

    cmd_cmdtest do
      stdout_equal names.map {|name| "### #{name}" }
    end
  end

end
