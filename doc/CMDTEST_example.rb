class CMDTEST_example < Cmdtest::Testcase

  def test_hello_world
    cmd "echo hello" do
      stdout_equal "hello\n"
    end

    cmd "echo WORLD" do
      stdout_equal "world\n"
    end
  end

  def test_touch_and_exit
    cmd "touch bar.txt ; exit 8" do
      created_files "foo.txt"
      exit_status 7
    end
  end

end
