#----------------------------------------------------------------------
# util.rb
#----------------------------------------------------------------------
# Copyright 2002-2016 Johan Holmberg.
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

module Cmdtest
  class Util

    TRUST_MTIME = (ENV["TRUST_MTIME"] || "1").to_i != 0

    @@opts = nil

    def self.opts=(opts)
      @@opts = opts
    end

    def self._timestamp_file(tmp_dir)
      File.join(tmp_dir, "TIMESTAMP")
    end

    def self.wait_for_new_second(tmp_dir, tmp_work_dir)
      return if ! TRUST_MTIME || @@opts.fast
      loop do
        File.open(_timestamp_file(tmp_dir), "w") {|f| f.puts Time.now }
        break if File.mtime(_timestamp_file(tmp_dir)) != _newest_file_time(tmp_work_dir)
        sleep 0.2
      end
    end

    def self._newest_file_time(tmp_work_dir)
      tnew = Time.at(0)
      Find.find(tmp_work_dir) do |path|
        next if ! File.file?(path)
        t = File.mtime(path)
        tnew = t > tnew ? t : tnew
      end
      return tnew
    end

    def self.quote_path(str)
      needed = (str =~ /[^-\\a-zA-Z0-9_:]/)
      return needed ? '"' + str.gsub('"', '\"') + '"' : str
    end

    def self.windows?
      RUBY_PLATFORM =~ /mswin32|mingw32/
    end

    def self.rm_rf(path)
      if File.exist?(path)
        FileUtils.rm_r(path) # exception if failing
      end
    end

    def self.read_file(stdxxx, fname)
      bytes = nil
      File.open(fname, 'rb') do |f|
        bytes = f.read
      end
      return FileContent.new(stdxxx, bytes)
    end
  end

  class FileContent
    def initialize(name, bytes)
      @name = name
      @bytes = bytes
    end

    def text(encoding)
      extern_text = @bytes.dup
      extern_text.force_encoding(encoding)
      if ! extern_text.valid_encoding?
        raise AssertFailed, "ERROR: unexpected encoding: #{@name} not '#{encoding}'"
      end
      return extern_text.encode('utf-8')
    end
  end

end
