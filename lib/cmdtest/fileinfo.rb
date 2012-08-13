#----------------------------------------------------------------------
# fileinfo.rb
#----------------------------------------------------------------------
# Copyright 2002-2012 Johan Holmberg.
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

require "digest/md5"

module Cmdtest
  class FileInfo

    attr_reader :stat, :digest

    def initialize(relpath, topdir)
      @topdir = topdir
      @relpath = relpath
      @path = File.join(topdir, relpath)
      @stat = File.lstat(@path)

      if @stat.file?
        md5 = Digest::MD5.new
        File.open(@path) {|f| f.binmode; md5.update(f.read) }
        @digest = md5.hexdigest
      else
        @digest = "a-directory"
      end
    end

    FILE_SUFFIXES = {
      "file"      => "",
      "directory" => "/",
      "link"      => "@",
    }

    def display_path
      @relpath + (FILE_SUFFIXES[@stat.ftype] || "?")
    end

    def ==(other)
      stat = other.stat
      case
      when @stat.file? && stat.file?
        (@stat.mtime == stat.mtime &&
         @stat.ino == stat.ino &&
         @digest == other.digest)
      when @stat.directory? && stat.directory?
        true
      else
        false
      end
    end
    
  end
end
