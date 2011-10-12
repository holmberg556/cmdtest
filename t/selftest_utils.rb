

module SelftestUtils

  TOP = Dir.pwd
  BIN = File.join(TOP, "t/bin")

  if RUBY_PLATFORM =~ /mswin/
    PLATFORM_BIN = File.join(TOP, "t/bin/windows")
  else
    PLATFORM_BIN = File.join(TOP, "t/bin/unix")
  end

  def setup
    ignore_file ".cmdtest-filter"
    ignore_file "tmp-cmdtest-2/"
    ignore_file "tmp-cmdtest-2/TIMESTAMP"
    ignore_file "tmp-cmdtest-2/tmp-command.sh"
    ignore_file "tmp-cmdtest-2/tmp-stderr.log"
    ignore_file "tmp-cmdtest-2/tmp-stdout.log"
    ignore_file "tmp-cmdtest-2/workdir/"
  end

  def create_CMDTEST_foo(lines)
    create_file "CMDTEST_foo.rb", [
      "class CMDTEST_foo < Cmdtest::Testcase",
      "  def setup",
      "    prepend_path #{BIN.inspect}",
      "    prepend_path #{PLATFORM_BIN.inspect}",
      "  end",
      "",
      "  def test_foo",
      lines,
      "  end",
      "end",
    ]
  end

  def cmd_cmdtest(*args)
    cmd("ruby #{TOP}/bin/cmdtest.rb --quiet", *args) do
      comment "running local cmdtest"
      yield
    end
  end

end
