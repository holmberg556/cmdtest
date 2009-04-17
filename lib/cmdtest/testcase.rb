#----------------------------------------------------------------------
# testcase.rb
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

require "set"
require "stringio"

module Cmdtest

  class AssertFailed < RuntimeError ; end

  # Base class for testcases.
  # Some attributes and methods are prefixed with an "_" to avoid
  # name collisions with user declared variables/methods.

  class Testcase

    @@_loaded_classes = []

    def self.inherited(klass)
      @@_loaded_classes << klass
    end

    def self.new_subclasses
      @@_loaded_classes = []
      yield
      @@_loaded_classes
    end

    #------------------------------

    def self.display_name
      to_s.sub(/^.*?::/, "")
    end

    #------------------------------

    def setup
    end
    
    def teardown
    end
    
    #------------------------------

    attr_reader :_work_dir

    def initialize(test_method, runner)
      @_test_method = test_method
      @_runner = runner
      @_work_dir = Workdir.new(runner)
      @_in_cmd = false
      @_comment_str = nil
      @_prepend_path_dirs = []
    end

    #------------------------------
    # Import file into the "workdir" from the outside world.
    # The source is found relative to the current directory when "cmdtest"
    # was invoked. The target is created inside the "workdir" relative to
    # the current directory at the time of the call.

    def import_file(src, tgt)
      src_path = File.expand_path(src, Workdir::ORIG_CWD)
      tgt_path = tgt            # rely on CWD
      FileUtils.mkdir_p(File.dirname(tgt_path))
      FileUtils.cp(src_path, tgt_path)
    end

    #------------------------------
    # Create a file inside the "workdir".
    # The content can be specified either as an Array of lines or as
    # a string with the content of the whole file.
    # The filename is evaluated relative to the current directory at the
    # time of the call.

    def create_file(filename, lines)
      #Util.wait_for_new_second
      FileUtils.mkdir_p( File.dirname(filename) )
      File.open(filename, "w") do |f|
        case lines
        when Array
          f.puts lines
        else
          f.write lines
        end
      end
    end

    #------------------------------
    # "touch" a file inside the "workdir".
    # The filename is evaluated relative to the current directory at the
    # time of the call.

    def touch_file(filename)
      #Util.wait_for_new_second
      FileUtils.touch(filename)
    end

    #------------------------------
    # Dont count the specified file when calculating the "side effects"
    # of a command.

    def ignore_file(file)
      @_work_dir.ignore_file(file)
    end

    #------------------------------
    # Dont count the specified file when calculating the "side effects"
    # of a command.

    def ignore_files(*files)
      for file in files.flatten
        @_work_dir.ignore_file(file)
      end
    end

    #------------------------------
    # Prepend the given directory to the PATH before running commands.
    # The path is evaluated realtive to the current directory when 'cmdtest'
    # was started.

    def prepend_path(dir)
      @_prepend_path_dirs.unshift(dir)
    end

    #==============================

    # Used in methods invoked from the "cmd" do-block, in methods that
    # should be executed *before* the actual command.
    def _process_before
      yield
    end

    # Used in methods invoked from the "cmd" do-block, in methods that
    # should be executed *after* the actual command.
    def _process_after
      _delayed_run_cmd
      yield
    end


    def comment(str)
      _process_before do
        @_comment_str = str
      end
    end

    #------------------------------

    def assert(flag, msg=nil)
      _process_after do
        _assert flag do
          msg ? "assertion: #{msg}" : "assertion failed"
        end
      end
    end

    #------------------------------

    def exit_zero
      _process_after do
        @_checked_status = true
        status = @_effects.exit_status
        _assert status == 0 do
          "expected zero exit status, got #{status}"
        end
      end
    end

    #------------------------------

    def exit_nonzero
      _process_after do
        @_checked_status = true
        status = @_effects.exit_status
        _assert status != 0 do
          "expected nonzero exit status"
        end
      end
    end

    #------------------------------

    def exit_status(expected_status)
      _process_after do
        @_checked_status = true
        status = @_effects.exit_status
        _assert status == expected_status do
          "expected #{expected_status} exit status, got #{status}"
        end
      end
    end

    #------------------------------
    #------------------------------

    def _xxx_files(xxx, files)
      actual   = @_effects.send(xxx)
      expected = files.flatten.sort
      #p [:xxx_files, xxx, actual, expected]
      _assert0 actual == expected do
        _format_output(xxx.to_s.gsub(/_/, " ").gsub(/modified/, "changed"),
                       actual.inspect + "\n",
                       expected.inspect + "\n")
      end
    end

    #------------------------------

    def created_files(*files)
      _process_after do
        _xxx_files(:created_files, files)
        @_checked_files_set << :created
      end
    end

    #------------------------------

    def modified_files(*files)
      _process_after do
        _xxx_files(:modified_files, files)
        @_checked_files_set << :modified
      end
    end

    alias :changed_files :modified_files

    #------------------------------

    def removed_files(*files)
      _process_after do
        _xxx_files(:removed_files, files)
        @_checked_files_set << :removed
      end
    end

    #------------------------------

    def written_files(*files)
      _process_after do
        _xxx_files(:written_files, files)
        @_checked_files_set << :created << :modified
      end
    end

    #------------------------------

    def affected_files(*files)
      _process_after do
        _xxx_files(:affected_files, files)
        @_checked_files_set << :created << :modified << :removed
      end
    end

    #------------------------------

    def _read_file(file)
      if File.directory?(file) && RUBY_PLATFORM =~ /mswin32/
        :is_directory
      else
        File.read(file)
      end
    rescue Errno::ENOENT
      :no_such_file
    rescue Errno::EISDIR
      :is_directory
    rescue
      :other_error
    end

    # Assert file equal to specific value.
    def file_equal(file, expected)
      _file_equal_aux(true, file, expected)
    end

    def file_not_equal(file, expected)
      _file_equal_aux(false, file, expected)
    end

    def _file_equal_aux(positive, file, expected)
      _process_after do
        actual = _read_file(file)
        case actual
        when :no_such_file
          _assert false do
            "no such file: '#{file}'"
          end
        when :is_directory
          _assert false do
            "is a directory: '#{file}'"
          end
        when :other_error
          _assert false do
            "error reading file: '#{file}'"
          end
        else
          _xxx_equal("file '#{file}'", positive, actual, expected)
        end
      end
    end

    # Assert stdout equal to specific value.
    def stdout_equal(expected)
      _stdxxx_equal_aux("stdout", true, expected)
    end

    # Assert stdout not equal to specific value.
    def stdout_not_equal(expected)
      _stdxxx_equal_aux("stdout", false, expected)
    end

    # Assert stderr equal to specific value.
    def stderr_equal(expected)
      _stdxxx_equal_aux("stderr", true, expected)
    end

    # Assert stderr not equal to specific value.
    def stderr_not_equal(expected)
      _stdxxx_equal_aux("stderr", false, expected)
    end

    # helper methods

    def _stdxxx_equal_aux(stdxxx, positive, expected)
      _process_after do
        @_checked[stdxxx] = true
        actual = @_effects.send(stdxxx)
        _xxx_equal(stdxxx, positive, actual, expected)
      end
    end

    def _xxx_equal(xxx, positive, actual, expected)
      _assert0 _output_match(positive, actual, expected) do
        _format_output "wrong #{xxx}", actual, expected
      end
    end

    def _output_match(positive, actual, expected)
      ! positive ^ _output_match_positive(actual, expected)
    end

    def _output_match_positive(actual, expected)
      case expected
      when String
        expected == actual
      when Regexp
        expected =~ actual
      when Array
        actual_lines = _str_as_lines(actual)
        expected_lines = _str_or_arr_as_lines(expected)
        if actual_lines.size != expected_lines.size
          return false
        end
        actual_lines.each_index do |i|
          return false if ! (expected_lines[i] === actual_lines[i])
        end
        return true
      else
        raise "error"
      end
    end

    def _str_as_lines(str)
      lines = str.split(/\n/, -1)
      if lines[-1] == ""
        lines.pop
      elsif ! lines.empty?
        lines[-1] << "<<missing newline>>"
      end
      return lines
    end

    def _str_or_arr_as_lines(arg)
      case arg
      when Array
        arg
      when String
        _str_as_lines(arg)
      else
        raise "unknown arg: #{arg.inspect}"
      end
    end

    def _indented_lines(prefix, output)
      case output
      when Array
        lines = output
      when String
        lines = output.split(/\n/, -1)
        if lines[-1] == ""
          lines.pop
        elsif ! lines.empty?
          lines[-1] << "<<missing newline>>"
        end
      when Regexp
        lines = [output]
      else
        raise "unexpected arg: #{output}"
      end
      if lines == []
        lines = ["[[empty]]"]
      end
      first = true
      lines.map do |line|
        if first
          first = false
          prefix + line.to_s + "\n"
        else
          " " * prefix.size + line.to_s + "\n"
        end
      end.join("")
    end

    def _format_output(error, actual, expected)
      res = ""
      res << "ERROR: #{error}\n"
      res << _indented_lines("       actual: ", actual)
      res << _indented_lines("       expect: ", expected)
      return res
    end

    def _assert0(flag)
      if ! flag
        msg = yield
        @_io.puts msg
        @_nerrors += 1
      end
    end

    def _assert(flag)
      if ! flag
        msg = yield
        @_io.puts "ERROR: " + msg
        @_nerrors += 1
      end
    end

    #------------------------------

    def _update_hardlinks
      return if ! @_runner.opts.fast

      @_work_dir.chdir do
        FileUtils.mkdir_p("../hardlinks")
        Find.find(".") do |path|
          st = File.lstat(path)
          if st.file?
            inode_path = "../hardlinks/%d" % [st.ino]
            if ! File.file?(inode_path)
              FileUtils.ln(path,inode_path)
            end
          end
        end
      end
    end

    #------------------------------

    def _delayed_run_cmd
      return if @_cmd_done
      @_cmd_done = true

      @_runner.notify("cmdline", @_cmdline, @_comment_str)
      @_comment_str = nil
      @_runner.prepend_path_dirs(@_prepend_path_dirs)
      @_effects = @_work_dir.run_cmd(@_cmdline)

      @_checked_status = false

      @_checked = {}
      @_checked["stdout"] = false
      @_checked["stderr"] = false

      @_checked_files_set = Set.new

      @_nerrors = 0
      @_io = StringIO.new
    end

    #------------------------------

    def _args_to_quoted_string(args)
      quoted_args = []
      for arg in args
        if RUBY_PLATFORM =~ /mswin32/
          if arg =~ /[;&()><\\| $%"]/
            quoted_arg = arg.dup
            # \  --- no change needed
            quoted_arg.gsub!(/"/, "\"\"")
            # \" --- TODO: handle this
            # %  --- don't try to handle this
            quoted_args << '"' + quoted_arg + '"'
          else
            quoted_args << arg
          end
        else
          if arg =~ /[;&()><\\| $"]/
            quoted_arg = arg.dup
            quoted_arg.gsub!(/\\/, "\\\\")
            quoted_arg.gsub!(/"/, "\\\"")
            quoted_arg.gsub!(/\$/, "\\$")
            quoted_arg.gsub!(/`/, "\\\\`")
            quoted_args << '"' + quoted_arg + '"'
          else
            quoted_args << arg
          end
        end
      end
      quoted_args.join(" ")
    end

    #------------------------------

    def cmd(cmdline)
      if Array === cmdline
        cmdline = _args_to_quoted_string(cmdline)
      end
      Util.wait_for_new_second
      _update_hardlinks
      @_cmdline = cmdline
      @_cmd_done = false

      yield
      _delayed_run_cmd

      exit_zero       if ! @_checked_status
      stdout_equal "" if ! @_checked["stdout"]
      stderr_equal "" if ! @_checked["stderr"]

      created_files  []    if ! @_checked_files_set.include?( :created )
      modified_files []    if ! @_checked_files_set.include?( :modified )
      removed_files  []    if ! @_checked_files_set.include?( :removed )

      if @_nerrors > 0
        str = @_io.string
        str = str.gsub(/actual: \S+\/tmp-command\.sh/, "actual: COMMAND.sh")
        raise AssertFailed, str
      end
    end

  end

end
