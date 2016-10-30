#----------------------------------------------------------------------
# fssnapshot.rb
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

require "cmdtest/fileinfo"
require "cmdtest/util"

require "find"

module Cmdtest
  class FsSnapshot

    def recursive_find(ignore, prefix, dir, &block)
      for entry in Dir.entries(dir)
        next if entry == "."
        next if entry == ".."
        path = File.join(dir, entry)
        relpath = prefix + entry
        if File.directory?(path)
          ignore2 = yield ignore, relpath
          recursive_find(ignore2, relpath + "/", path, &block)
        else
          ignore2 = yield ignore, relpath
        end
      end
    end

    def initialize(dir, ignored_files)
      @dir = dir
      @ignored_files = ignored_files
      @fileinfo_by_path = {}

      recursive_find(false, "", @dir) do |ignore, path|
        file_info = FileInfo.new(path, @dir)
        display_path = file_info.display_path
        ignore2 = ignore || _ignore_file?(display_path)
        @fileinfo_by_path[display_path] = file_info
        file_info.ignored = ignore2
        ignore2
      end
    end

    def _ignore_file?(path)
      @ignored_files.any? do |ignored|
        if String === ignored && ignored.index("*")
          File.fnmatch(ignored, path, File::FNM_PATHNAME)
        else
          ignored === path
        end
      end
    end

    def files
      @fileinfo_by_path.keys.sort.select do |path|
        fileinfo = @fileinfo_by_path[path]
        stat = fileinfo.stat
        ! fileinfo.ignored && (stat.file? || stat.directory?)
      end
    end

    def fileinfo(path)
      @fileinfo_by_path[path]
    end

  end
end
