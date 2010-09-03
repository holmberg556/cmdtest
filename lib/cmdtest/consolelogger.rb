#----------------------------------------------------------------------
# consolelogger.rb
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

require "cmdtest/baselogger"

module Cmdtest
  class ConsoleLogger < BaseLogger

    def _banner(ch, str)
      puts "### " + ch * 40 + " " + str      
    end

    def testfile_begin(file)
      super
      _banner "=", file  if ! opts.quiet
    end

    def testclass_begin(testcase_class)
      super
      _banner "-", testcase_class.display_name if ! opts.quiet
    end

    def testmethod_begin(method)
      super
      _banner ".", method.to_s  if ! opts.quiet
    end

    def cmdline(cmdline_arg, comment)
      super

      if opts.verbose
        first = comment || "..."
        puts "### %s" % [first]
        puts "###         %s" % [cmdline_arg]
      else
        first = comment || cmdline_arg
        puts "### %s" % [first]
      end
    end

    def assert_failure(str)
      super()
      puts str.gsub(/^/, "--- ")
    end

    def assert_error(str)
      super()
      puts str.gsub(/^/, "--- ")
    end

    def testsuite_end
      super
      if ! opts.quiet
        puts
        puts "%s %d test classes, %d test methods, %d commands, %d errors, %d fatals." % [
          n_failures == 0 && n_errors == 0 ? "###" : "---",
          n_classes, n_methods, n_commands, n_failures, n_errors
        ]
        puts
      end
    end
    
  end
end
