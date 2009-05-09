#!/usr/bin/ruby
#----------------------------------------------------------------------
# cmdtest.rb
#----------------------------------------------------------------------
# Copyright 2002-2009 Johan Holmberg.
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
require "cmdtest/util"
require "set"
require "stringio"
require "fileutils"
require "find"
require "rbconfig"

module Cmdtest

  #----------------------------------------------------------------------

  class TestMethod

    def initialize(test_method, test_class, runner)
      @test_method, @test_class, @runner = test_method, test_class, runner
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
          rescue => e
            io = StringIO.new
            io.puts "CAUGHT EXCEPTION:"
            io.puts "  " + e.message + " (#{e.class})"
            io.puts "BACKTRACE:"
            io.puts e.backtrace.map {|line| "  " + line }
            @runner.assert_error(io.string)
          end
          obj.teardown
        end
      end
    end

  end

  #----------------------------------------------------------------------

  class TestClass

    attr_reader :testcase_class

    def initialize(testcase_class, file, runner)
      @testcase_class, @file, @runner = testcase_class, file, runner
    end

    def run
      @runner.notify("testclass", @testcase_class) do
        get_test_methods.each do |method|
          TestMethod.new(method, self, @runner).run
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

    def initialize(file)
      @file = file
    end

    def run(runner)
      @runner = runner
      @runner.notify("testfile", @file) do
        testcase_classes = Cmdtest::Testcase.new_subclasses do
          Kernel.load(@file, true)
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

    attr_reader :opts, :orig_cwd

    def initialize(project_dir, opts)
      @project_dir = project_dir
      @listeners = []
      @opts = opts
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

    def prepend_path_dirs(full_path_dirs)
      new_env_path = (full_path_dirs + [@orig_envpath]).join(Config::CONFIG["PATH_SEPARATOR"])
      if new_env_path != ENV["PATH"]
        ENV["PATH"] = new_env_path
      end
    end

    def run
      @orig_cwd = Dir.pwd
      ENV["PATH"] = Dir.pwd + Config::CONFIG["PATH_SEPARATOR"] + ENV["PATH"]
      @orig_envpath = ENV["PATH"]
      @n_assert_failures  = 0
      @n_assert_errors    = 0
      @n_assert_successes = 0
      notify("testsuite") do
        for test_file in @project_dir.test_files
          test_file.run(self)
        end
      end
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

    attr_reader :tests, :quiet, :verbose, :fast, :ruby_s

    def initialize
      @tests = []
      @quiet = false
      @verbose = false
      @fast = false
      @xml = nil
      @ruby_s = false

      _update_cmdtest_level
    end

    def run
      while ! ARGV.empty? && ARGV[0] =~ /^-/
        opt = ARGV.shift
        case opt
        when /^--test=(.*)/
          @tests << $1
        when /^--quiet$/
          @quiet = true
        when /^--verbose$/
          @verbose = true
        when /^--fast$/
          @fast = true
        when /^--xml=(.+)$/
          @xml = $1
        when /^--ruby_s$/
          @ruby_s = true
        when /^--help$/, /^-h$/
          puts
          _show_options
          puts
          exit 0
        else
          puts "ERROR: unknown option: #{opt}"
          puts
          _show_options
          puts
          exit 1
        end
      end

      Util.opts = self
      @project_dir = ProjectDir.new(ARGV)
      @runner = Runner.new(@project_dir, self)
      logger = ConsoleLogger.new(self)
      @runner.add_listener(logger)
      if @xml
        @runner.add_listener(JunitLogger.new(self, @xml))
      end

      @runner.run
    end

    private

    def _update_cmdtest_level
      $cmdtest_level = (ENV["CMDTEST_LEVEL"] || "0").to_i + 1
      ENV["CMDTEST_LEVEL"] = $cmdtest_level.to_s
    end

    def _show_options
      puts "  --help            show this help"
      puts "  --quiet           be more quiet"
      puts "  --verbose         be more verbose"
      puts "  --fast            run fast without waiting for unique mtime:s"
      puts "  --test=NAME       only run named test"
      puts "  --xml=FILE        write summary on JUnit format"
    end

  end

end

#----------------------------------------------------------------------
Cmdtest::Main.new.run
#----------------------------------------------------------------------
