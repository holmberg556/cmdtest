#----------------------------------------------------------------------
# cmdeffects.rb
#----------------------------------------------------------------------
# Copyright 2002-2014 Johan Holmberg.
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

module Cmdtest
  class CmdEffects

    attr_reader :stdout, :stderr

    def initialize(process_status, stdout, stderr, snapshot_before, snapshot_after)
      @process_status = process_status
      @stdout = stdout
      @stderr = stderr
      @before = snapshot_before
      @after  = snapshot_after
    end

    def exit_status
      @process_status.exitstatus
    end

    def _select_files
      files = @before.files.to_set + @after.files.to_set
      files.sort.select do |file|
        before = @before.fileinfo(file)
        after  = @after.fileinfo(file)
        yield before, after
      end
    end

    def affected_files
      _select_files do |before,after|
        ((!! before ^ !! after) ||
         (before && after && before != after))
      end
    end

    def written_files
      _select_files do |before,after|
        ((! before  && after) ||
         (before && after && before != after))
      end
    end

    def created_files
      _select_files do |before,after|
        (! before && after)
      end
    end

    def modified_files
      _select_files do |before,after|
        (before && after && before != after)
      end
    end

    def removed_files
      _select_files do |before,after|
        (before && ! after)
      end
    end

  end
end
