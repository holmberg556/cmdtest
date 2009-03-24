#----------------------------------------------------------------------
# util.rb
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

module Cmdtest
  class Util

    TRUST_MTIME = (ENV["TRUST_MTIME"] || "1").to_i != 0

    @@opts = nil

    def self.opts=(opts)
      @@opts = opts
    end

    def self._timestamp_file
      File.join(Workdir.tmp_cmdtest_dir, "TIMESTAMP")
    end

    def self.wait_for_new_second
      return if ! TRUST_MTIME || @@opts.fast
      loop do
        File.open(_timestamp_file, "w") {|f| f.puts Time.now }
        break if File.mtime(_timestamp_file) != _newest_file_time
        sleep 0.2
      end
    end

    def self._newest_file_time
      tnew = Time.at(0)
      Find.find(Workdir.tmp_work_dir) do |path|
        next if ! File.file?(path)
        t = File.mtime(path)
        tnew = t > tnew ? t : tnew
      end
      return tnew
    end

    def self.chdir(dir)
      old_cwd = Dir.pwd
      Dir.chdir(dir)
      yield
    ensure
      if Dir.pwd != old_cwd
        Dir.chdir(old_cwd)
      end
    end

  end
end
