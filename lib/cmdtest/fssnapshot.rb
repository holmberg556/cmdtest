#----------------------------------------------------------------------
# fssnapshot.rb
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

require "cmdtest/fileinfo"
require "cmdtest/util"

require "find"

module Cmdtest
  class FsSnapshot

    def _dir_entries(dir, &block)
      if Cmdtest::Util.windows?
        Dir.entries(dir, encoding: 'UTF-8', &block)
      else
        Dir.entries(dir, &block)
      end
    end

    def recursive_find(ignore, prefix, dir, &block)
      for entry in _dir_entries(dir)
        next if entry == "."
        next if entry == ".."
        path = File.join(dir, entry)
        relpath = prefix + entry
        if ! File.symlink?(path) && File.directory?(path)
          ignore2 = yield ignore, relpath
          recursive_find(ignore2, relpath + "/", path, &block)
        else
          ignore2 = yield ignore, relpath
        end
      end
    end

    def initialize(dir, ignored_files, non_ignored_files)
      @dir = dir
      @ignored_files = ignored_files
      @non_ignored_files = non_ignored_files
      @fileinfo_by_path = {}

      recursive_find(false, "", @dir) do |ignore, path|
        file_info = FileInfo.new(path, @dir)
        display_path = file_info.display_path
        if _match_file?(@non_ignored_files, display_path)
          ignore2 = false
        else
          ignore2 = ignore || _match_file?(@ignored_files, display_path)
        end
        @fileinfo_by_path[display_path] = file_info
        file_info.ignored = ignore2
        ignore2
      end
    end

    def _match_file?(patterns, path)
      patterns.any? do |pattern|
        if String === pattern && pattern.index("*")
          File.fnmatch(pattern, path, File::FNM_PATHNAME)
        else
          pattern === path
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
