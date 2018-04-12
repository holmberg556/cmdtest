#!/usr/bin/ruby
#----------------------------------------------------------------------
# cmdtest.rb
#----------------------------------------------------------------------
# Copyright 2002-2018 Johan Holmberg.
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

TOP_DIR = File.expand_path(File.dirname(File.dirname(__FILE__)))
LIB_DIR = File.join(TOP_DIR, "lib")
$:.unshift(LIB_DIR) if File.directory?(File.join(LIB_DIR, "cmdtest"))

require "cmdtest/argumentparser"
require "cmdtest/baselogger"
require "cmdtest/consolelogger"
require "cmdtest/junitlogger"
require "cmdtest/methodfilter"
require "cmdtest/testcase"
require "cmdtest/util"
require "cmdtest/workdir"

require "digest/md5"
require "fileutils"
require "find"
require "rbconfig"
require "set"
require "stringio"

module Cmdtest

  ORIG_CWD = Dir.pwd

  GIT_REV  = '$GIT_REV_STRING$'
  GIT_DATE = '$GIT_DATE_STRING$'
  VERSION  = '$VERSION$'

  SHORT_VERSION = '1.5'

  #----------------------------------------------------------------------

  class LogClient

    def initialize
      @listeners = []
    end

    def add_listener(listener)
      @listeners << listener
    end

    def _call(m, args)
      @listeners.each {|listener| listener.send(m, *args) }
    end

    def method_missing(m, *args)
      if block_given?
        _call("#{m}_begin", args)
        yield
        _call("#{m}_end", args)
      else
        _call(m, args)
      end
    end

    def assert_success
      # nop
    end

  end

  #----------------------------------------------------------------------

  class MethodId

    attr_reader :file

    def initialize(file, klass, method)
      @file = file
      @klass = klass
      @method = method
    end

    def key
      @file + ":" + @klass + "." + @method.to_s
    end

  end

  #----------------------------------------------------------------------

  class TestMethod

    def initialize(method, adm_class, runner)
      @method, @adm_class, @runner = method, adm_class, runner
    end

    def to_s
      class_name = @adm_class.runtime_class.name.sub(/^.*::/, "")
      "<<TestMethod: #{class_name}.#{@method}>>"
    end

    def as_filename
      klass_name = @adm_class.as_filename
      "#{klass_name}.#{@method}"
    end

    def method_id
      MethodId.new(@adm_class.adm_file.path, @adm_class.runtime_class.display_name, @method)
    end

    def skip?
      patterns = @runner.opts.patterns
      selected = (patterns.size == 0 ||
                    patterns.any? {|pattern| pattern =~ @method } )

      return !selected || @runner.method_filter.skip?(method_id)
    end

    def run(clog, runner)
      ok = false
      clog.testmethod(@method) do
        obj = @adm_class.runtime_class.new(self, clog, runner)
        Dir.chdir(obj._work_dir.path)
        begin
          obj.setup
          obj.send(@method)
          Dir.chdir(obj._work_dir.path)
          obj.teardown

          clog.assert_success
          runner.method_filter.success(method_id)
          ok = true
        rescue Cmdtest::TestSkipped => e
          obj.teardown
          clog.test_skipped(e.message)
          runner.method_filter.failure(method_id)
        rescue Cmdtest::AssertFailed => e
          obj.teardown
          clog.assert_failure(e.message)
          runner.method_filter.failure(method_id)
        rescue => e
          io = StringIO.new
          io.puts "CAUGHT EXCEPTION:"
          io.puts "  " + e.message + " (#{e.class})"
          io.puts "BACKTRACE:"
          io.puts e.backtrace.map {|line| "  " + line }
          clog.assert_error(io.string)
          runner.method_filter.failure(method_id)
        end
      end
      return ok
    ensure
      Dir.chdir(ORIG_CWD)
    end

  end

  #----------------------------------------------------------------------

  class TestClass

    attr_reader :runtime_class, :adm_file, :adm_methods

    def initialize(runtime_class, adm_file, runner)
      @runtime_class, @adm_file, @runner = runtime_class, adm_file, runner

      tested = runner.opts.test
      @adm_methods = @runtime_class.public_instance_methods(true).sort.select do |name|
        name =~ /^test_/
      end.map do |name|
        TestMethod.new(name, self, runner)
      end.select do |adm_method|
        (tested.empty? || tested.include?(adm_method.name)) && ! adm_method.skip?
      end
    end

    def nitems
      return @adm_methods.size
    end

    def as_filename
      @runtime_class.name.sub(/^.*::/, "")
    end

  end

  #----------------------------------------------------------------------

  class TestFile

    attr_reader :path, :adm_classes

    def initialize(path, runner)
      @path, @runner = path, runner
      @adm_classes = Cmdtest::Testcase.new_subclasses do
        Kernel.load(@path, true)
      end.map do |runtime_class|
        TestClass.new(runtime_class, self, runner)
      end.reject do |adm_class|
        adm_class.nitems == 0
      end
    end

    def nitems
      return @adm_classes.size
    end

  end

  #----------------------------------------------------------------------

  class Runner

    attr_reader :opts, :orig_cwd, :method_filter

    def initialize(project_dir, incremental, opts)
      @project_dir = project_dir
      @opts = opts
      @method_filter = MethodFilter.new(Dir.pwd, incremental, self)

      # find local files "required" by testcase files
      $LOAD_PATH.unshift(@project_dir.test_files_dir)

      # force loading of all test files
      @adm_files = @project_dir.test_filenames.map do
        |x| TestFile.new(x, self)
      end.reject do |adm_file|
        adm_file.nitems == 0
      end
    end

    def _path_separator
      File::PATH_SEPARATOR || ":"
    end

    def orig_env_path
      @orig_env_path.dup
    end

    def test_files_top
      @project_dir.test_files_top
    end

    #----------

    def tmp_cmdtest_dir
      File.join(ORIG_CWD, "tmp-cmdtest-%d" % [$cmdtest_level])
    end

    def tmp_dir
      if ! @opts.slave
        File.join(tmp_cmdtest_dir, "top")
      else
        tmp_dir_slave(@opts.slave)
      end
    end

    def tmp_dir_slave(slave_name)
      File.join(tmp_cmdtest_dir, slave_name)
    end

    def tmp_work_dir
      File.join(tmp_dir, "work")
    end

    #----------

    def run(clog)
      @orig_cwd = Dir.pwd
      ENV["PATH"] = Dir.pwd + _path_separator + ENV["PATH"]
      @orig_env_path = ENV["PATH"].split(_path_separator)

      # make sure class names are unique
      used_adm_class_filenames = {}
      for adm_file in @adm_files
        for adm_class in adm_file.adm_classes
          filename = adm_class.as_filename
          prev_adm_file = used_adm_class_filenames[filename]
          if prev_adm_file
            puts "ERROR: same class name used twice: #{filename}"
            puts "ERROR:     prev file: #{prev_adm_file.path}"
            puts "ERROR:     curr file: #{adm_file.path}"
            exit(1)
          end
          used_adm_class_filenames[filename] = adm_file
        end
      end
      _loop(clog)
    end

    def self.create(project_dir, incremental, opts)
      if opts.parallel > 1
        klass = RunnerParallel
      elsif opts.slave
        klass = RunnerSlave
      else
        klass = RunnerSerial
      end
      return klass.new(project_dir, incremental, opts)
    end
  end

  class RunnerParallel < Runner
    def _loop(clog)
      json_files = []
      nclasses = 0
      File.open("tmp.sh", "w") do |f|
        for adm_file in @adm_files
          if ! @opts.quiet
            f.puts "echo '### " + "=" * 40 + " " + adm_file.path + "'"
          end
          for adm_class in adm_file.adm_classes
            nclasses += 1
            if ! @opts.quiet
              f.puts "echo '### " + "-" * 40 + " " + adm_class.as_filename + "'"
            end
            for adm_method in adm_class.adm_methods
              slave_name = adm_method.as_filename
              f.puts "#{$0} %s --slave %s %s" % [
                (@opts.quiet ? "-q" : ""),
                slave_name,
                adm_file.path,
              ]
              json_files << File.join(tmp_dir_slave(slave_name), "result.json")
            end
          end
        end
      end
      cmd = "parallel -k -j%d < tmp.sh" % [@opts.parallel]
      ok = system(cmd)
      summary = Hash.new(0)
      for file in json_files
        File.open(file) do |f|
          data = JSON.load(f)
          for k,v in data
            summary[k] += v
          end
        end
      end
      summary["classes"] = nclasses
      if ! @opts.quiet
        Cmdtest.print_summary(summary)
      end

      ok = summary["errors"] == 0 && summary["failures"] == 0
      error_exit = ! @opts.no_exit_code && ! ok
      exit( error_exit ? 1 : 0 )
    end
  end

  class RunnerSlave < Runner

    def _loop(clog)
      for adm_file in @adm_files
        for adm_class in adm_file.adm_classes
          for adm_method in adm_class.adm_methods
            if adm_method.as_filename == @opts.slave
              adm_method.run(clog, self)
            end
          end
        end
      end
    end

    def report_result(error_logger)
      result = {
        "classes" => error_logger.n_classes,
        "methods" => error_logger.n_methods,
        "commands" => error_logger.n_commands,
        "skipped" => error_logger.n_skipped,
        "failures" => error_logger.n_failures,
        "errors" => error_logger.n_errors,
      }
      result_file = File.join(self.tmp_dir, "result.json")
      File.open(result_file, "w") do |f|
        f.puts JSON.pretty_generate(result)
      end
      exit(0)
    end

  end

  class RunnerSerial < Runner
    def _loop(clog)
      clog.testsuite do
        for adm_file in @adm_files
          clog.testfile(adm_file.path) do
            for adm_class in adm_file.adm_classes
              clog.testclass(adm_class.runtime_class.display_name) do
                for adm_method in adm_class.adm_methods
                  ok = adm_method.run(clog, self)
                  if !ok && @opts.stop_on_error
                    puts "cmdtest: exiting after first error ..."
                    exit(1)
                  end
                  if $cmdtest_got_ctrl_c > 0
                    puts "cmdtest: exiting after Ctrl-C ..."
                    exit(1)
                  end
                end
              end
            end
          end
        end
      end
      @method_filter.write
    end

    def report_result(error_logger)
      if ! opts.quiet
        summary = {
          "classes"  => error_logger.n_classes,
          "methods"  => error_logger.n_methods,
          "commands" => error_logger.n_commands,
          "skipped"  => error_logger.n_skipped,
          "failures" => error_logger.n_failures,
          "errors"   => error_logger.n_errors,
        }
        Cmdtest.print_summary(summary)
      end

      ok = error_logger.everything_ok?
      error_exit = ! opts.no_exit_code && ! ok
      exit( error_exit ? 1 : 0 )
    end

  end

  #----------------------------------------------------------------------

  START_TIME = Time.now

  def self.print_summary(summary)
    s = (Time.now - START_TIME).to_i
    m, s = s.divmod(60)
    h, m = m.divmod(60)

    puts "###"
    puts "### Finished: %s,  Elapsed: %02d:%02d:%02d" % [Time.now.strftime("%F %T"), h,m,s]
    puts
    puts "%s %d test classes, %d test methods, %d commands, %d skipped, %d errors, %d fatals." % [
      summary["failures"] == 0 && summary["errors"] == 0 ? "###" : "---",
      summary["classes"],
      summary["methods"],
      summary["commands"],
      summary["skipped"],
      summary["failures"],
      summary["errors"],
    ]
    puts
  end

  #----------------------------------------------------------------------

  class ProjectDir

    def initialize(argv)
      @argv = argv
      @test_filenames = nil
    end

    def test_filenames
      @test_filenames ||= _fs_test_filenames
    end

    def test_files_dir
      File.expand_path(File.dirname(test_filenames[0]), ORIG_CWD)
    end

    def test_files_top
      ORIG_CWD
    end

    private

    def _sorted_glob(str)
      Dir.glob(str).sort
    end

    def _fs_test_filenames
      if ! @argv.empty?
        files = _expand_files_or_dirs(@argv)
        if files.empty?
          puts "ERROR: no files given"
          exit 1
        end
        return files
      end

      try = _sorted_glob("t/CMDTEST_*.rb")
      return try if ! try.empty?

      try = _sorted_glob("test/CMDTEST_*.rb")
      return try if ! try.empty?

      try = _sorted_glob("CMDTEST_*.rb")
      return try if ! try.empty?

      puts "ERROR: no CMDTEST_*.rb files found"
      exit 1
    end

    def _expand_files_or_dirs(argv)
      files = []
      for arg in @argv
        if File.file?(arg)
          if File.basename(arg) =~ /^.*\.rb$/
            files << arg
          else
            puts "ERROR: illegal file: #{arg}"
            exit(1)
          end
        elsif File.directory?(arg)
          for entry in Dir.entries(arg).sort
            path = File.join(arg,entry)
            next unless File.file?(path)
            next unless entry =~ /^CMDTEST_.*\.rb$/
            files << path
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

    def initialize
    end

    def _parse_options
      pr = @argument_parser = ArgumentParser.new("cmdtest")
      pr.add("-h", "--help",         "show this help message and exit")
      pr.add("",   "--shortversion", "show just version number")
      pr.add("",   "--version",      "show version")
      pr.add("-q", "--quiet",        "be more quiet")
      pr.add("-v", "--verbose",      "be more verbose")
      pr.add("",   "--diff",         "diff output (default)")
      pr.add("",   "--no-diff",      "old non-diff output")
      pr.add("",   "--fast",         "run fast without waiting for unique mtime:s")
      pr.add("-j", "--parallel",     "build in parallel",  type: Integer, default: 1, metavar: "N")
      pr.add("",   "--test",         "only run named test", type: [String])
      pr.add("",   "--xml",          "write summary on JUnit format", type: String, metavar: "FILE")
      pr.add("",   "--no-exit-code", "exit with 0 status even after errors")
      pr.add("",   "--stop-on-error","exit after first error")
      pr.add("-i", "--incremental",  "incremental mode")
      pr.add("",   "--slave",        "run in slave mode", type: String)
      pr.addpos("arg", "testfile or pattern", nargs: 0..999)

      opts = pr.parse_args(ARGV, patterns: [], ruby_s: Util.windows?)

      # default '--diff', reversed by --no-diff
      if opts.diff and opts.no_diff
        puts "ERROR: both --diff and --no-diff specified"
        exit(1)
      elsif ! opts.no_diff
        opts.diff = true
      end

      if opts.help
        pr.print_usage()
        exit(0)
      end
      return opts
    end

    def run
      opts = _parse_options

      if opts.shortversion
        puts SHORT_VERSION
        exit(0)
      elsif opts.version
        puts "Version:   " + (VERSION =~ /^\$/ ? SHORT_VERSION : VERSION)
        if File.directory?(File.join(TOP_DIR, ".git"))
          Dir.chdir(TOP_DIR) do
            git_rev = `git rev-parse HEAD`
            git_date = `git show -s --format=%ci HEAD`
            puts "Revision:  #{git_rev}"
            puts "Date:      #{git_date}"
          end
        else
          puts "Revision:  #{GIT_REV}"
          puts "Date:      #{GIT_DATE}"
        end
        exit(0)
      end

      if opts.stop_on_error && opts.parallel != 1
        puts "cmdtest: error: --stop-on-error can not be used with --parallel"
        exit(1)
      end

      _update_cmdtest_level(opts.slave ? 0 : 1)

      files = []
      for arg in opts.args
        case
        when File.file?(arg)
          files << arg
        when File.directory?(arg)
          files << arg
        when arg =~ /^\/(.+)\/$/
          opts.patterns  << $1
        else
          puts "ERROR: unknown argument: #{arg}"
          puts
          @argument_parser.print_usage()
          puts
          exit 1
        end
      end

      begin
        opts.patterns.map! {|pattern| Regexp.new(pattern) }
      rescue RegexpError => e
        puts "ERROR: syntax error in regexp?"
        puts "DETAILS: " + e.message
        exit(1)
      end

      clog = LogClient.new
      Util.opts = opts

      error_logger = ErrorLogger.new(opts)
      clog.add_listener(error_logger)

      logger = ConsoleLogger.new(opts)
      clog.add_listener(logger)

      if opts.xml
        clog.add_listener(JunitLogger.new(opts, File.expand_path(opts.xml)))
      end

      @project_dir = ProjectDir.new(files)
      @runner = Runner.create(@project_dir, opts.incremental, opts)

      $cmdtest_got_ctrl_c = 0
      trap("INT") do
        puts "cmdtest: got ctrl-C ..."
        $cmdtest_got_ctrl_c += 1
        if $cmdtest_got_ctrl_c > 3
          puts "cmdtest: several Ctrl-C, exiting ..."
          exit(1)
        end
      end
      @runner.run(clog)
      @runner.report_result(error_logger)
    end

    private

    def _update_cmdtest_level(inc)
      $cmdtest_level = (ENV["CMDTEST_LEVEL"] || "0").to_i + inc
      ENV["CMDTEST_LEVEL"] = $cmdtest_level.to_s
    end

  end

end

#----------------------------------------------------------------------
Cmdtest::Main.new.run
#----------------------------------------------------------------------
