#----------------------------------------------------------------------
# junitlogger.rb
#----------------------------------------------------------------------
# Copyright 2002-2020 Johan Holmberg.
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
require "cmdtest/junitfile"

module Cmdtest
  class JunitLogger < BaseLogger

    def initialize(opts, file)
      super(opts)
      @file = file
    end

    def testsuite_begin
      @jf = JunitFile.new(@file)
    end

    def testclass_begin(testcase_class_name)
      @testclass_t1 = Time.now
      @testcase_class_name = testcase_class_name
      @ts = @jf.new_testsuite("CMDTEST", testcase_class_name)
    end

    def testclass_end(testcase_class_name)
      @testclass_t2 = Time.now
      @ts.duration = @testclass_t2 - @testclass_t1
    end

    def testmethod_begin(method)
      @err_assertions = []
      @err_skip = nil
      @progress = []
      @t1 = Time.now
    end

    def cmdline(cmdline_arg, comment)
      @progress << ">>> cmdline: #{cmdline_arg}\n"
      @progress << ">>> comment: #{comment}\n" if comment != nil
    end

    def testmethod_end(method)
      @t2 = Time.now
      @duration = @t2 - @t1
      if @err_skip != nil
        message = @err_skip.split(/\n/)[0]
        type = "skip"
        text = @err_skip
        @ts.skip_testcase(@duration, _xml_class, method, message, type, text)
      elsif @err_assertions.size > 0
        message = @err_assertions[0].split(/\n/)[0]
        type = "assert"
        text = [@progress + @err_assertions].join
        @ts.err_testcase(@duration, _xml_class, method, message, type, text)
      else
        @ts.ok_testcase(@duration, _xml_class, method)
      end
    end

    def _xml_class
      "CMDTEST." + @testcase_class_name
    end

    def test_skipped(str)
      @err_skip = str
    end

    def assert_failure(str)
      @err_assertions << str
    end

    def assert_error(str)
      @err_assertions << str
    end

    def testsuite_end
      @jf.write
    end

  end
end
