#----------------------------------------------------------------------
# testcase.rb
#----------------------------------------------------------------------
# Copyright 2002-2021 Johan Holmberg.
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

require "fileutils"
require "set"
require "stringio"

require "cmdtest/lcs"

module Cmdtest

  class AssertFailed < RuntimeError ; end
  class TestSkipped < RuntimeError ; end
  class UsageError < RuntimeError ; end

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

    ORIG_CWD = Dir.pwd

    attr_reader :_work_dir, :_env_setenv

    def initialize(test_method, clog, runner)
      @_test_method = test_method
      @_clog = clog
      @_runner = runner
      @_work_dir = Workdir.new(self, runner)
      @_cwd = @_runner.tmp_work_dir
      @_env_setenv = Hash.new
      @_in_cmd = false
      @_comment_str = nil
      @_env_path = @_runner.orig_env_path
      @_t1 = @_t2 = 0
      @_output_encoding = 'ascii'
      @_output_newline = Util.windows? ? "\r\n" : "\n"
    end

    def output_encoding(encoding)
      if block_given?
        saved_encoding = @_output_encoding
        begin
          @_output_encoding = encoding
          yield
        ensure
          @_output_encoding = saved_encoding
        end
      else
        @_output_encoding = encoding
      end
    end

    def output_newline(newline)
      if block_given?
        saved_newline = @_output_newline
        begin
          @_output_newline = newline
          yield
        ensure
          @_output_newline = saved_newline
        end
      else
        @_output_newline = newline
      end
    end

    #------------------------------
    # Import file into the "workdir" from the outside world.
    # The source is found relative to the current directory when "cmdtest"
    # was invoked. The target is created inside the "workdir" relative to
    # the current directory at the time of the call.

    def import_file(src, tgt)
      src_path = File.expand_path(src, @_runner.test_files_top)
      tgt_path = _cwd_path(tgt)
      FileUtils.mkdir_p(File.dirname(tgt_path))
      if File.file?(src_path)
        FileUtils.cp(src_path, tgt_path)
      else
        raise UsageError, "'import_file' argument not a file: '#{src}'"
      end
    end

    #------------------------------
    # Import directory into the "workdir" from the outside world.
    # The source is found relative to the current directory when "cmdtest"
    # was invoked. The target is created inside the "workdir" relative to
    # the current directory at the time of the call.

    def import_directory(src, tgt)
      src_path = File.expand_path(src, @_runner.test_files_top)
      tgt_path = _cwd_path(tgt)
      FileUtils.mkdir_p(File.dirname(tgt_path))
      if File.exists?(tgt_path)
        raise UsageError, "'import_directory' target argument already exist: '#{tgt}'"
      elsif File.directory?(src_path)
        FileUtils.cp_r(src_path, tgt_path)
      else
        raise UsageError, "'import_directory' argument not a directory: '#{src}'"
      end
    end

    #------------------------------
    # Create a file inside the "workdir".
    # The content can be specified either as an Array of lines or as
    # a string with the content of the whole file.
    # The filename is evaluated relative to the current directory at the
    # time of the call.

    def create_file(filename, lines)
      #_wait_for_new_second
      FileUtils.mkdir_p( File.dirname(_cwd_path(filename)) )
      File.open(_cwd_path(filename), "w") do |f|
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
      #_wait_for_new_second
      FileUtils.touch(_cwd_path(filename))
    end

    #------------------------------

    def file_read(filename)
      File.read(_cwd_path(filename))
    end

    #------------------------------

    def file_open(filename, *args, &block)
      File.open(_cwd_path(filename), *args, &block)
    end

    #------------------------------

    def dir_mkdir(filename, *args)
      Dir.mkdir(_cwd_path(filename), *args)
    end

    #------------------------------

    def file_symlink(filename1, filename2)
      File.symlink(filename1, _cwd_path(filename2))
    end

    #------------------------------

    def remove_file(filename)
      FileUtils.rm_f(_cwd_path(filename))
    end

    #------------------------------

    def remove_file_tree(filename)
      Util.rm_rf(_cwd_path(filename))
    end

    #------------------------------

    def file_utime(arg1, arg2, filename)
      File.utime(arg1, arg2, _cwd_path(filename))
    end

    #------------------------------

    def file_chmod(arg, filename)
      File.chmod(arg, _cwd_path(filename))
    end

    #------------------------------

    def setenv(name, value)
      @_env_setenv[name] = [:setenv, value]
    end

    #------------------------------

    def unsetenv(name)
      @_env_setenv[name] = [:unsetenv]
    end

    #------------------------------

    def current_directory
      self._cwd
    end

    def _cwd
      if @_runner.opts.parallel == 1
        Dir.pwd
      else
        @_cwd
      end
    end

    def _cwd=(dir)
      if @_runner.opts.parallel == 1
        Dir.chdir(dir)
      else
        @_cwd = dir
      end
    end

    #------------------------------

    def chdir(dir, &block)
      dir_path = File.expand_path(dir, self._cwd)
      if block_given?
        saved_cwd = self._cwd
        self._cwd = dir_path
        begin
          yield
        ensure
          self._cwd = saved_cwd
        end
      else
        self._cwd = dir_path
      end
    end

    #------------------------------
    # Don't count the specified file when calculating the "side effects"
    # of a command.

    def ignore_file(file)
      @_work_dir.ignore_file(file)
    end

    #------------------------------
    # Don't count the specified file when calculating the "side effects"
    # of a command.

    def ignore_files(*files)
      for file in files.flatten
        @_work_dir.ignore_file(file)
      end
    end

    #------------------------------
    # Count the specified file when calculating the "side effects"
    # of a command, even if a less specific call to 'ignore_files'
    # exist.

    def dont_ignore_files(*files)
      for file in files.flatten
        @_work_dir.dont_ignore_file(file)
      end
    end

    #------------------------------
    # Prepend the given directory to the PATH before running commands.
    # The path is evaluated relative to the current directory when 'cmdtest'
    # was started.

    def prepend_path(dir)
      @_env_path.unshift(File.expand_path(dir, @_runner.orig_cwd))
    end

    #------------------------------
    # Prepend the given directory to the PATH before running commands.
    # The path is evaluated relative to the current directory at the time
    # of the call was started.

    def prepend_local_path(dir)
      @_env_path.unshift(File.expand_path(dir, self._cwd))
    end

    #------------------------------

    def set_path(*dirs)
      @_env_path = dirs.flatten
    end

    #------------------------------

    def get_path
      @_env_path
    end

    #------------------------------

    def windows?
      Util.windows?
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

    def time(time_interval)
      _process_after do
        diff = @_t2 - @_t1
        _assert diff >= time_interval.begin && diff <= time_interval.end do
          "expected time in interval #{time_interval}"
        end
      end
    end

    #------------------------------

    def skip_test(reason)
      raise TestSkipped, "SKIP: " + reason
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
        if @_runner.opts.diff
          _format_output("ERROR",
                         xxx.to_s.gsub(/_/, " ").gsub(/modified/, "changed"),
                         actual,
                         expected)
        else
          _format_output("ERROR",
                         xxx.to_s.gsub(/_/, " ").gsub(/modified/, "changed"),
                         actual.inspect + "\n",
                         expected.inspect + "\n")
        end
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

    def _cwd_path(path)
      File.expand_path(path, self._cwd)
    end

    #------------------------------

    def _read_file(what, file)
      path = _cwd_path(file)
      if Util.windows? && File.directory?(path)
        :is_directory
      elsif (RUBY_PLATFORM =~ /java/) && File.directory?(path)
        :is_directory
      else
        Util.read_file(what, path)
      end
    rescue Errno::ENOENT
      :no_such_file
    rescue Errno::EISDIR
      :is_directory
    rescue
      :other_error
    end

    # Assert file encoding
    def file_encoding(file, enc, bom: nil)
      _process_after do
        bytes = nil
        File.open(file, 'rb') do |f|
          bytes = f.read
        end
        str = bytes.force_encoding(enc)
        valid = str.valid_encoding?
        _assert valid do
          "file not in encoding: #{file}, #{enc}"
        end
        if valid && bom != nil
          has_bom = str.size >= 1 && str.codepoints[0] == 0xfeff
          _assert ! (! bom && has_bom) do
            "file has unexpected BOM: #{file}"
          end
          _assert ! (bom && ! has_bom) do
            "file hasn't expected BOM: #{file}"
          end
        end
      end
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
        what = "content of file '#{file}'"
        actual = _read_file(what, file)
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
          actual_text, err = actual.text(@_output_encoding, @_output_newline)
          _assert err == nil do
            err
          end
          _xxx_equal(what, positive, actual_text, expected)
        end
      end
    end

    # Assert stdout contains the specific value.
    def stdout_contain(expected)
      _stdxxx_contain_aux("stdout", true, expected)
    end

    # Assert stderr contains the specific value.
    def stderr_contain(expected)
      _stdxxx_contain_aux("stderr", true, expected)
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

    # Yield stdout to user, expecting 'assert' call.
    def stdout_check(&block)
      _stdxxx_check_aux("stdout", &block)
    end

    # Yield stderr to user, expecting 'assert' call.
    def stderr_check(&block)
      _stdxxx_check_aux("stderr", &block)
    end

    # helper methods

    def _stdxxx_check_aux(stdxxx)
      _process_after do
        @_checked[stdxxx] = true
        str, err = @_effects.send(stdxxx).text(@_output_encoding, @_output_newline)
        _assert err == nil do
          err
        end
        yield _str_as_lines(str)
      end
    end

    def _stdxxx_contain_aux(stdxxx, positive, expected)
      _process_after do
        @_checked[stdxxx] = true
        actual, err = @_effects.send(stdxxx).text(@_output_encoding, @_output_newline)
        _assert err == nil do
          err
        end
        _xxx_contain(stdxxx, positive, actual, expected)
      end
    end

    def _n_matches_here(actual_lines, i, expected_lines)
      n = 0
      expected_lines.each_index do |j|
        break if i+j >= actual_lines.size
        break if ! (expected_lines[j] === actual_lines[i+j])
        n += 1
      end
      return [n, i]
    end

    def _xxx_contain(xxx, positive, actual, expected)
      actual_lines = _str_as_lines(actual)
      expected_lines = _str_or_arr_as_lines(expected)
      n_matches = actual_lines.each_index.map do |i|
        _n_matches_here(actual_lines, i, expected_lines)
      end
      n_matches.sort!
      n_matches.reverse!
      msg = []
      if n_matches.size == 0
        msg << "ERROR: empty #{xxx}, should contain:"
        for line in expected_lines
          msg << "    " + _show_line(line)
        end
      else
        match_size, offset = n_matches[0]
        if match_size == expected_lines.size
          # ok
        elsif match_size > 0
          msg << "ERROR: found only part in #{xxx}:"
          for line in expected_lines[0...match_size]
            msg << "    " + _show_line(line)
          end

          msg << "ERROR: should have been followed by:"
          for line in expected_lines[match_size..-1]
            msg << "    " + _show_line(line)
          end

          if offset+match_size == actual_lines.size
            msg << "ERROR: instead at EOF"
          else
            msg << "ERROR: instead followed by:"
            for line in actual_lines[(offset+match_size)...(offset+expected_lines.size)]
              msg << "    " + _show_line(line)
            end
          end
        else
          msg << "ERROR: not found in #{xxx}:"
          for line in expected_lines
            msg << "    " + _show_line(line)
          end
        end
      end
      _assert0 msg.size == 0 do
        msg.join("\n")
      end
    end

    #---

    def _stdxxx_equal_aux(stdxxx, positive, expected)
      _process_after do
        @_checked[stdxxx] = true
        actual, err = @_effects.send(stdxxx).text(@_output_encoding, @_output_newline)
        _assert err == nil do
          err
        end
        _xxx_equal(stdxxx, positive, actual, expected)
      end
    end

    def _xxx_equal(xxx, positive, actual, expected)
      _assert0 _output_match(positive, actual, expected) do
        _format_output "ERROR", "wrong #{xxx}", actual, expected
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
        lines[-1] << "[[missing newline]]"
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

    def _show_line(arg)
      case arg
      when String
        arg.gsub("\r", "\\r")
      when Regexp
        arg.inspect
      else
        arg.to_s # or error ???
      end
    end

    def _to_lines(str)
      if Array === str
        lines = str
      else
        lines = str.split(/\n/, -1)
        if lines[-1] == ""
          lines.pop
        elsif ! lines.empty?
          lines[-1] << "[[missing newline]]"
        end
      end
      return lines
    end

    def _indented_lines(prefix, output)
      case output
      when Array
        lines = output
      when String
        lines = _to_lines(output)
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
          prefix + _show_line(line) + "\n"
        else
          " " * prefix.size + _show_line(line) + "\n"
        end
      end.join("")
    end

    def _format_output(level, error, actual, expected)
      res = ""
      res << "#{level}: #{error}\n"
      if @_runner.opts.diff && (Array === expected || String === expected)
        expected_lines = _to_lines(expected)
        actual_lines = _to_lines(actual)
        diff = DiffLCS.new(expected_lines, actual_lines)
        res << _indented_lines("  ", diff.to_a)
      else
        res << _indented_lines("       actual: ", actual)
        if expected != nil
          res << _indented_lines("       expect: ", expected)
        end
      end
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

      hardlinkdir = @_work_dir.hardlinkdir
      FileUtils.mkdir_p(hardlinkdir)
      Find.find(@_work_dir.path) do |path|
        st = File.lstat(path)
        if st.file?
          inode_path = "%s/%d" % [hardlinkdir, st.ino]
          if ! File.file?(inode_path)
            FileUtils.ln(path,inode_path)
          end
        end
      end
    end

    #------------------------------

    def _delayed_run_cmd
      return if @_cmd_done
      @_cmd_done = true

      @_clog.cmdline(@_cmdline, @_comment_str)
      @_comment_str = nil
      @_t1 = Time.now
      @_effects = @_work_dir.run_cmd(@_cmdline, @_env_path)
      @_t2 = Time.now

      if @_effects.stdout.bytes =~ /^CMDTEST_SKIP: (.*)/
        skip_test $1.gsub(/\r$/, "")
      end
      if @_effects.stderr.bytes =~ /^CMDTEST_SKIP: (.*)/
        skip_test $1.gsub(/\r$/, "")
      end

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
        if Util.windows?
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

    def _wait_for_new_second
      Util.wait_for_new_second(@_runner.tmp_dir, @_runner.tmp_work_dir)
    end

    #------------------------------

    def shell(cmdline)
      if Array === cmdline
        cmdline = _args_to_quoted_string(cmdline)
      end
      @_cmdline = cmdline
      @_nerrors = 0
      @_io = StringIO.new

      @_clog.cmdline("shell: " + @_cmdline, nil)
      @_effects = @_work_dir.run_cmd(@_cmdline, @_env_path)
      status = @_effects.exit_status
      if status != 0
        _assert false do
          "expected zero exit status, got #{status}"
        end

        actual_text, err = @_effects.stdout.text(@_output_encoding, @_output_newline)
        _assert0 false do
          _format_output "INFO", "the stdout", actual_text, nil
        end

        actual_text, err = @_effects.stderr.text(@_output_encoding, @_output_newline)
        _assert0 false do
          _format_output "INFO", "the stderr", actual_text, nil
        end
      end

      if @_nerrors > 0
        str = @_io.string
        str = str.gsub(/actual: \S+\/tmp-command\.sh/, "actual: COMMAND.sh")
        raise AssertFailed, str
      end
    end

    #------------------------------

    def cmd(cmdline)
      @_work_dir.push_ignored_files
      if Array === cmdline
        cmdline = _args_to_quoted_string(cmdline)
      end
      _wait_for_new_second
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
    ensure
      @_work_dir.pop_ignored_files
    end

  end

end
