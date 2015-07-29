#----------------------------------------------------------------------
# baselogger.rb
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

module Cmdtest

  class BaseLogger

    attr_reader :opts

    def initialize(opts)
      @opts = opts
    end

    def testsuite_begin
    end

    def testsuite_end
    end

    def testfile_begin(file)
    end

    def testfile_end(file)
    end

    def testclass_begin(testcase_class)
    end

    def testclass_end(testcase_class)
    end

    def testmethod_begin(method)
    end

    def testmethod_end(method)
    end

    def cmdline(method, comment)
    end

    def assert_failure(str)
    end

    def assert_error(str)
    end
  end

  class ErrorLogger < BaseLogger

    @@debug = false

    attr_reader :n_suites, :n_files, :n_classes
    attr_reader :n_methods, :n_commands, :n_failures, :n_errors

    def initialize(opts)
      super

      @n_suites   = 0
      @n_files    = 0
      @n_classes  = 0
      @n_methods  = 0
      @n_commands = 0
      @n_failures = 0
      @n_errors   = 0
    end

    def testsuite_begin
      @n_suites += 1
    end

    def testfile_begin(file)
      @n_files += 1
    end

    def testclass_begin(testcase_class)
      @n_classes += 1
    end

    def testmethod_begin(method)
      @n_methods += 1
    end

    def cmdline(method, comment)
      @n_commands += 1
    end

    def assert_failure(msg)
      @n_failures += 1
    end

    def assert_error(str)
      @n_errors += 1
    end

    def everything_ok?
      @n_errors == 0 && @n_failures == 0
    end

  end
end
