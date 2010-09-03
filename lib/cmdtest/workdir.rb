#----------------------------------------------------------------------
# workdir.rb
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

require "cmdtest/fssnapshot"
require "cmdtest/cmdeffects"

require "fileutils"

module Cmdtest
  class Workdir

    ORIG_CWD = Dir.pwd

    def self.tmp_cmdtest_dir
      File.join(ORIG_CWD, "tmp-cmdtest-%d" % [$cmdtest_level])
    end

    def self.tmp_work_dir
      File.join(tmp_cmdtest_dir, "workdir")
    end

    def initialize(runner)
      @runner = runner
      @dir = Workdir.tmp_work_dir
      hardlinkdir = File.join(Workdir.tmp_cmdtest_dir, "hardlinks")
      FileUtils.rm_rf(@dir)
      FileUtils.rm_rf(hardlinkdir)
      FileUtils.mkdir_p(@dir)
      @ignored_files = []
    end

    #--------------------
    # called by user (indirectly)

    def ignore_file(file)
      @ignored_files << file
    end

    #--------------------

    def chdir(&block)
      Util.chdir(@dir, &block)
    end

    def _take_snapshot
      FsSnapshot.new(@dir, @ignored_files)
    end

    def _windows
      RUBY_PLATFORM =~ /mswin32/
    end

    def _shell
      if _windows
        cmd_exe = ENV["COMSPEC"] || "cmd.exe"
        "#{cmd_exe} /Q /c"
      else
        "/bin/sh"
      end
    end

    def _tmp_command_sh
      File.join(Workdir.tmp_cmdtest_dir,
                _windows ? "tmp-command.bat" : "tmp-command.sh")
    end

    def _tmp_stdout_log
      File.join(Workdir.tmp_cmdtest_dir, "tmp-stdout.log")
    end

    def _tmp_stderr_log
      File.join(Workdir.tmp_cmdtest_dir, "tmp-stderr.log")
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

    def run_cmd(cmdline)
      File.open(_tmp_command_sh, "w") do |f|
        f.puts _ruby_S(cmdline)
      end
      str = "%s %s  > %s  2> %s" % [
        _shell,
        _tmp_command_sh,
        _tmp_stdout_log,
        _tmp_stderr_log,
      ]
      before = _take_snapshot
      ok = system(str)
      after = _take_snapshot
      CmdEffects.new($?,
                     File.read(_tmp_stdout_log),
                     File.read(_tmp_stderr_log),
                     before, after)
    end

  end
end
