#
# Example of testing some UN*X commands.
#

class CMDTEST_simple < Cmdtest::Testcase

  #----------------------------------------
  # true

  def test_true
    cmd "true" do
    end

    # same but explicit
    cmd "true" do
      exit_zero
      stdout_equal ""
      stderr_equal ""
    end

    # same but explicit another way
    cmd "true" do
      exit_status 0
      stdout_equal []
      stderr_equal []
    end
  end

  #----------------------------------------
  # false

  def test_false
    cmd "false" do
      exit_nonzero
    end
  end

  #----------------------------------------
  # sleep

  def test_sleep
    cmd "sleep 5" do
      time 4..6
    end
  end

  #----------------------------------------

  def test_echo
    cmd "echo" do
      stdout_equal "\n"
    end

    cmd "echo hello" do
      stdout_equal "hello\n"
    end

    cmd "echo hello world" do
      stdout_equal "hello world\n"
    end
  end

    #------------------------------

    def test_touch
      # one file
      cmd "touch aaa" do
        created_files "aaa"
      end

      # two files
      cmd "touch bbb ccc" do
        created_files "bbb", "ccc"
      end

      # existing file
      cmd "touch aaa" do
        changed_files "aaa"
      end
    end

    #------------------------------

    def test_mkdir
      # one directory
      cmd "mkdir aaa" do
        created_files "aaa/"
      end

      # two directories
      cmd "mkdir bbb ccc" do
        created_files "bbb/", "ccc/"
      end

      # existing directory
      cmd "mkdir aaa" do
        exit_nonzero
        stderr_equal /File exists/
      end
    end

end
