#----------------------------------------------------------------------
# fssnapshot.rb
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

require "cmdtest/fileinfo"
require "cmdtest/util"

require "find"

module Cmdtest
  class FsSnapshot

    def initialize(dir, ignored_files)
      @dir = dir
      @ignored_files = ignored_files
      @fileinfo_by_path = {}
      Util.chdir(@dir) do
        Find.find(".") do |path|
          next if path == "."
          path.sub!(/^\.\//, "")
          file_info = FileInfo.new(path)
          display_path = file_info.display_path
          Find.prune if _ignore_file?(display_path)
          @fileinfo_by_path[display_path] = file_info
        end
      end
    end

    def _ignore_file?(path)
      @ignored_files.any? {|ignored| ignored === path }
    end

    def files
      @fileinfo_by_path.keys.sort.select do |path|
        stat = @fileinfo_by_path[path].stat
        stat.file? || stat.directory?
      end
    end

    def fileinfo(path)
      @fileinfo_by_path[path]
    end

  end
end