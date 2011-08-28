#!/usr/bin/ruby
#----------------------------------------------------------------------
# cmdtest.rb
#----------------------------------------------------------------------
# Copyright 2002-2010 Johan Holmberg.
#----------------------------------------------------------------------
# This file is part of "cmdtest".
#
# "cmdtest" is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# "cmdtest" is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with "cmdtest".  If not, see <http://www.gnu.org/licenses/>.
#----------------------------------------------------------------------

# This is the main program of "cmdtest".
# It reads a number of "CMDTEST_*.rb" files and executes the testcases
# found in the files. The result can be reported in different ways.
# Most of the testing logic is found in the library files "cmdtest/*.rb".

top_dir = File.dirname(File.dirname(__FILE__))
lib_dir = File.join(File.expand_path(top_dir), "lib")
$:.unshift(lib_dir) if File.directory?(File.join(lib_dir, "cmdtest"))

require "cmdtest/baselogger"
require "cmdtest/consolelogger"
require "cmdtest/junitlogger"
require "cmdtest/testcase"
require "cmdtest/workdir"
require "cmdtest/methodfilter"
require "cmdtest/util"
require "set"
require "stringio"
require "fileutils"
require "find"
require "digest/md5"
require "rbconfig"

module Cmdtest

  #----------------------------------------------------------------------

  class TestMethod

    def initialize(test_method, test_class, runner)
      @test_method, @test_class, @runner = test_method, test_class, runner
    end

    def method_id
      [@test_class.file, @test_class.testcase_class, @test_method]
    end

    def skip?
      patterns = @runner.opts.patterns
      selected = (patterns.size == 0 ||
                    patterns.any? {|pattern| pattern =~ @test_method } )

      !selected || @runner.method_filter.skip?(*method_id)
    end

    def run
      @runner.notify("testmethod", @test_method) do
        obj = @test_class.testcase_class.new(self, @runner)
        obj._work_dir.chdir do
          obj.setup
          begin
            obj.send(@test_method)
            @runner.assert_success
          rescue Cmdtest::AssertFailed => e
            @runner.assert_failure(e.message)
            @runner.method_filter.error(*method_id)
          rescue => e
            io = StringIO.new
            io.puts "CAUGHT EXCEPTION:"
            io.puts "  " + e.message + " (#{e.class})"
            io.puts "BACKTRACE:"
            io.puts e.backtrace.map {|line| "  " + line }
            @runner.assert_error(io.string)
            @runner.method_filter.error(*method_id)
          end
          obj.teardown
        end
      end
    end

  end

  #----------------------------------------------------------------------

  class TestClass

    attr_reader :testcase_class, :file

    def initialize(testcase_class, file, runner)
      @testcase_class, @file, @runner = testcase_class, file, runner
    end

    def run
      @runner.notify("testclass", @testcase_class) do
        get_test_methods.each do |method|
          test_method = TestMethod.new(method, self, @runner)
          test_method.run unless test_method.skip?
        end
      end
    end

    def get_test_methods
      @testcase_class.public_instance_methods(false).sort.select do |method|
        in_list = @runner.opts.tests.empty? || @runner.opts.tests.include?(method)
        method =~ /^test_/ && in_list
      end
    end

  end

  #----------------------------------------------------------------------

  class TestFile

    attr_reader :path

    def initialize(path)
      @path = path
    end

    def run(runner)
      @runner = runner
      @runner.notify("testfile", @path) do
        testcase_classes = Cmdtest::Testcase.new_subclasses do
          Kernel.load(@path, true)
        end
        for testcase_class in testcase_classes
          test_class = TestClass.new(testcase_class, self, @runner)
          if ! test_class.get_test_methods.empty?
            test_class.run
          end
        end
      end
    end
    
  end

  #----------------------------------------------------------------------

  class Runner

    attr_reader :opts, :orig_cwd, :method_filter

    FILTER_FILENAME = ".cmdtest-filter"

    def initialize(project_dir, opts)
      @project_dir = project_dir
      @listeners = []
      @opts = opts
      @method_filter = MethodFilter.new(FILTER_FILENAME, self)
    end

    def add_listener(listener)
      @listeners << listener
    end

    def notify_once(method, *args)
      for listener in @listeners
        listener.send(method, *args)
      end
    end

    def notify(method, *args)
      if block_given?
        notify_once(method + "_begin", *args)
        yield
        notify_once(method + "_end", *args)
      else
        notify_once(method, *args)
      end
    end

    def _path_separator
      Config::CONFIG["PATH_SEPARATOR"] || ":"
    end

    def orig_env_path
      @orig_env_path.dup
    end

    def set_env_path(path_arr)
      path_str = path_arr.join(_path_separator)
      if path_str != ENV["PATH"]
        ENV["PATH"] = path_str
      end
    end

    def run
      @orig_cwd = Dir.pwd
      ENV["PATH"] = Dir.pwd + _path_separator + ENV["PATH"]
      @orig_env_path = ENV["PATH"].split(_path_separator)
      @n_assert_failures  = 0
      @n_assert_errors    = 0
      @n_assert_successes = 0
      notify("testsuite") do
        for test_file in @project_dir.test_files
          test_file.run(self)
        end
      end
      @method_filter.write
    end

    def everything_ok?
      @n_assert_errors == 0 && @n_assert_failures == 0
    end

    def assert_success
      @n_assert_successes += 1
    end

    def assert_failure(str)
      @n_assert_failures += 1
      notify("assert_failure", str)
    end

    def assert_error(str)
      @n_assert_errors += 1
      notify("assert_error", str)
    end
  end

  #----------------------------------------------------------------------

  class ProjectDir

    def initialize(argv)
      @argv = argv
    end

    def test_files
      if ! @argv.empty?
        files = _expand_files_or_dirs(@argv)
        if files.empty?
          puts "ERROR: no files given"
          exit 1
        end
        return files
      end

      try = Dir.glob("t/CMDTEST_*.rb")
      return _test_files(try) if ! try.empty?

      try = Dir.glob("test/CMDTEST_*.rb")
      return _test_files(try) if ! try.empty?

      try = Dir.glob("CMDTEST_*.rb")
      return _test_files(try) if ! try.empty?

      puts "ERROR: no CMDTEST_*.rb files found"
      exit 1
    end

    private

    def _test_files(files)
      files.map {|file| TestFile.new(file) }
    end

    def _expand_files_or_dirs(argv)
      files = []
      for arg in @argv
        if File.file?(arg)
          if File.basename(arg) =~ /^.*\.rb$/
            files << TestFile.new(arg)
          else
            puts "ERROR: illegal file: #{arg}"
            exit(1)
          end
        elsif File.directory?(arg)
          Dir.foreach(arg) do |entry|
            path = File.join(arg,entry)
            next unless File.file?(path)
            next unless entry =~ /^CMDTEST_.*\.rb$/
            files << TestFile.new(path)
          end
        else
          puts "ERROR: unknown file: #{arg}"
        end
      end
      return files
    end

  end

  #----------------------------------------------------------------------

  class Main

    attr_reader :tests, :quiet, :verbose, :fast, :ruby_s, :incremental, :patterns

    def initialize
      @tests = []
      @quiet = false
      @verbose = false
      @fast = false
      @xml = nil
      @set_exit_code = true
      @ruby_s = false
      @incremental = false
      @patterns = []

      _update_cmdtest_level
    end

    def run
      files = []
      while ! ARGV.empty?
        opt = ARGV.shift
        case
        when opt =~ /^--test=(.*)/
          @tests << $1
        when opt =~ /^--quiet$/
          @quiet = true
        when opt =~ /^--verbose$/
          @verbose = true
        when opt =~ /^--fast$/
          @fast = true
        when opt =~ /^--xml=(.+)$/
          @xml = $1
        when opt =~ /^--no-exit-code$/
          @set_exit_code = false
        when opt =~ /^--ruby_s$/
          @ruby_s = true
        when opt =~ /^-r$/
          @incremental = true
        when opt =~ /^-i$/
          @incremental = true
        when opt =~ /^--help$/ || opt =~ /^-h$/
          puts
          _show_options
          puts
          exit 0
        when File.file?(opt)
          files << opt
        when File.directory?(opt)
          files << opt
        when opt =~ /^\/(.+)\/$/
          @patterns  << $1
        else
          puts "ERROR: unknown argument: #{opt}"
          puts
          _show_options
          puts
          exit 1
        end
      end

      begin
        @patterns.map! {|pattern| Regexp.new(pattern) }
      rescue RegexpError => e
        puts "ERROR: syntax error in regexp?"
        puts "DETAILS: " + e.message
        exit(1)
      end

      Util.opts = self
      @project_dir = ProjectDir.new(files)
      @runner = Runner.new(@project_dir, self)
      logger = ConsoleLogger.new(self)
      @runner.add_listener(logger)
      if @xml
        @runner.add_listener(JunitLogger.new(self, @xml))
      end

      @runner.run
      error_exit = @set_exit_code && ! @runner.everything_ok?
      exit( error_exit ? 1 : 0 )
    end

    private

    def _update_cmdtest_level
      $cmdtest_level = (ENV["CMDTEST_LEVEL"] || "0").to_i + 1
      ENV["CMDTEST_LEVEL"] = $cmdtest_level.to_s
    end

    def _show_options
      puts "Usage: cmdtest [options] [files/directories]"
      puts
      puts "  --help            show this help"
      puts "  --quiet           be more quiet"
      puts "  --verbose         be more verbose"
      puts "  --fast            run fast without waiting for unique mtime:s"
      puts "  --test=NAME       only run named test"
      puts "  --xml=FILE        write summary on JUnit format"
      puts "  --no-exit-code    exit with 0 status even after errors"
      puts "  -i                incremental mode"
    end

  end

end

#----------------------------------------------------------------------
Cmdtest::Main.new.run
#----------------------------------------------------------------------
