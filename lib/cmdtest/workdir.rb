#----------------------------------------------------------------------
# workdir.rb
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

require "cmdtest/fssnapshot"
require "cmdtest/cmdeffects"
require "cmdtest/util"

require "fileutils"

module Cmdtest
  class Workdir

    attr_reader :path, :hardlinkdir
    attr_accessor :ignored_files, :non_ignored_files

    def initialize(testcase, runner)
      @testcase = testcase
      @runner = runner
      @path = @runner.tmp_work_dir
      @hardlinkdir = File.join(@runner.tmp_dir, "hardlinks")
      Util.rm_rf(@path)
      Util.rm_rf(@hardlinkdir)
      FileUtils.mkdir_p(@path)
      @ignored_files = []
      @non_ignored_files = []
    end

    #--------------------

    def _take_snapshot
      FsSnapshot.new(@path, @ignored_files, @non_ignored_files)
    end

    def _shell
      if Util.windows?
        cmd_exe = ENV["COMSPEC"] || "cmd.exe"
        "#{cmd_exe} /Q /c"
      else
        "/bin/sh"
      end
    end

    def _tmp_redirect_sh
      File.join(@runner.tmp_dir,
                Util.windows? ? "tmp-redirect.bat" : "tmp-redirect.sh")
    end

    def _tmp_command_name
      Util.windows? ? "tmp-command.bat" : "tmp-command.sh"
    end

    def _tmp_command_sh
      File.join(@runner.tmp_dir, _tmp_command_name)
    end

    def _tmp_stdout_name
      "tmp-stdout.log"
    end

    def _tmp_stderr_name
      "tmp-stderr.log"
    end

    def _tmp_stdout_log
      File.join(@runner.tmp_dir, _tmp_stdout_name)
    end

    def _tmp_stderr_log
      File.join(@runner.tmp_dir, _tmp_stderr_name)
    end

    def _ENV_strs(env)
      env.keys.sort.map do |k|
        what = env[k][0]
        case what
        when :setenv
          if Util.windows?
            "set %s=%s" % [k, env[k][1]]
          else
            "export %s='%s'" % [k, env[k][1]]
          end
        when :unsetenv
          if Util.windows?
            "set %s=" % [k]
          else
            "unset %s" % [k]
          end
        else
          raise "internal error"
        end
      end
    end

    def _chdir_str(dir)
      "cd %s" % _quote(_slashes(dir))
    end

    def _set_env_path_str(env_path)
      if Util.windows?
        "set path=" + env_path.join(";")
      else
        "export PATH=" + _quote(env_path.join(":"))
      end
    end

    def _ruby_S(cmdline)
      if @runner.opts.ruby_s
        if cmdline =~ /ruby/
          cmdline
        else
          cmdline.gsub(/\b(\w+\.rb)\b/, 'ruby -S \1')
        end
      else
        cmdline
      end
    end

    def _slashes(str)
      if Util.windows?
        str.gsub("/", "\\")
      else
        str
      end
    end

    def _quote(str)
      return Cmdtest::Util::quote_path(str)
    end

    def run_cmd(cmdline, env_path)
      File.open(_tmp_command_sh, "w") do |f|
        f.puts _ruby_S(cmdline)
      end

      File.open(_tmp_redirect_sh, "w") do |f|
        f.puts _ENV_strs(@testcase._env_setenv)
        f.puts
        f.puts _chdir_str(@testcase._cwd)
        f.puts
        f.puts _set_env_path_str(env_path)
        f.puts
        f.printf "%s %s > %s 2> %s\n" % [
          _shell,
          _quote(_tmp_command_sh),
          _quote(_tmp_stdout_log),
          _quote(_tmp_stderr_log),
        ]
        f.puts
      end

      str = "%s %s" % [
        _shell,
        _quote(_tmp_redirect_sh),
      ]
      before = _take_snapshot
      system(str) # TODO: really ignore exit status !?
      after = _take_snapshot
      CmdEffects.new($?,
                     Util.read_file("STDOUT", _tmp_stdout_log),
                     Util.read_file("STDERR", _tmp_stderr_log),
                     before, after)
    end
  end

end
