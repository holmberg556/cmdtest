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

    @@debug = false

    attr_reader :opts

    attr_reader :n_suites, :n_files, :n_classes
    attr_reader :n_methods, :n_commands, :n_failures, :n_errors

    def initialize(opts)
      @opts = opts

      @n_suites   = 0
      @n_files    = 0
      @n_classes  = 0
      @n_methods  = 0
      @n_commands = 0
      @n_failures = 0
      @n_errors   = 0
    end

    def testsuite_begin
      p :testsuite_begin if @@debug
      @n_suites += 1
    end
    
    def testsuite_end
      p :testsuite_end if @@debug
    end
    
    def testfile_begin(file)
      p [:testfile_begin, file] if @@debug
      @n_files += 1
    end
    
    def testfile_end(file)
      p :testfile_end if @@debug
    end
    
    def testclass_begin(testcase_class)
      p [:testclass_begin, testcase_class] if @@debug
      @n_classes += 1
    end
    
    def testclass_end(testcase_class)
      p :testclass_end if @@debug
    end
    
    def testmethod_begin(method)
      p [:testmethod_begin, method] if @@debug
      @n_methods += 1
    end
    
    def testmethod_end(method)
      p :testmethod_end if @@debug
    end

    def cmdline(method, comment)
      p :testmethod_end if @@debug
      @n_commands += 1
    end
    
    def assert_failure
      @n_failures += 1
    end

    def assert_error
      @n_errors += 1
    end

  end
end
