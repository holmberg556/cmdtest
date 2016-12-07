#----------------------------------------------------------------------
# junitfile.rb
#----------------------------------------------------------------------
# Copyright 2009-2016 Johan Holmberg.
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
  class JunitFile

    #----------

    class XmlFile

      def initialize(file)
        @file = file
        @f = File.open(file, "w")
      end

      def put(str, args=[])
        @f.puts str % args.map {|arg| String === arg ? _quote(arg) : arg}
      end

      def _quote(arg)
        arg.gsub(/&/, "&amp;").gsub(/</, "&lt;").gsub(/>/, "&gt;")
      end

      def close
        @f.close
      end

    end

    #----------

    class Testcase
      def write(f)
        f.put '    <testcase classname="%s" name="%s" time="%.3f"/>', [
          @classname,
          @name,
          @duration,
        ]
      end
    end

    #----------

    class OkTestcase < Testcase

      def initialize(duration, classname, name)
        @duration  = duration
        @classname = classname
        @name      = name
        @message = @type = @text = nil
      end

    end

    #----------

    class ProblemTestcase < Testcase

      def initialize(duration, classname, name, message, type, text)
        @duration  = duration
        @classname = classname
        @name      = name
        @message   = message
        @type      = type
        @text      = text
      end

      def write(f)
        f.put '    <testcase classname="%s" name="%s" time="%.3f">', [
          @classname,
          @name,
          @duration,
        ]
        f.put '      <%s message="%s" type="%s">%s</%s>', [
          xml_tag,
          @message,
          @type,
          _asciify(@text),
          xml_tag,
        ]
        f.put '    </testcase>'
      end

      def _asciify(str)
        res = str.gsub(/[\x00-\x09\x0b-\x1f]/) do |x|
          "^" + (x.ord + 64).chr
        end
        return res
      end
    end

    #----------

    class ErrTestcase < ProblemTestcase
      def xml_tag
        "failure"
      end
    end

    class SkipTestcase < ProblemTestcase
      def xml_tag
        "skipped"
      end
    end

    #----------

    class Testsuite

      attr_accessor :duration

      def initialize(package, name)
        @package = package
        @name = name
        @testcases = []
        @duration = 0.0
      end

      def ok_testcase(duration, classname, name)
        testcase = OkTestcase.new(duration, classname, name)
        @testcases << testcase
        testcase
      end

      def err_testcase(duration, classname, name, message, type, text)
        testcase = ErrTestcase.new(duration, classname, name, message, type, text)
        @testcases << testcase
        testcase
      end

      def skip_testcase(duration, classname, name, message, type, text)
        testcase = SkipTestcase.new(duration, classname, name, message, type, text)
        @testcases << testcase
        testcase
      end

      def write(f)
        f.put '  <testsuite errors="%d" failures="%d" skipped="%d" name="%s" tests="%d" time="%.3f" package="%s">', [
          0,
          @testcases.grep(ErrTestcase).size,
          @testcases.grep(SkipTestcase).size,
          @name,
          @testcases.size,
          @duration,
          @package,
        ]
        for testcase in @testcases
          testcase.write(f)
        end
        f.put '  </testsuite>'
      end
    end

    #----------

    def initialize(file)
      @file = file
      @testsuites = []
    end

    def new_testsuite(*args)
      testsuite = Testsuite.new(*args)
      @testsuites << testsuite
      testsuite
    end

    def write
      @f = XmlFile.new(@file)
      @f.put '<?xml version="1.0" encoding="UTF-8" ?>'
      @f.put '<testsuites>'
      for testsuite in @testsuites
        testsuite.write(@f)
      end
      @f.put '</testsuites>'
      @f.close
    end

  end
end

if $0 == __FILE__
  jf = Cmdtest::JunitFile.new("jh.xml")
  ts = jf.new_testsuite("foo")
  ts.ok_testcase(1.0, "jh.Foo", "test_a")
  ts.ok_testcase(1.0, "jh.Foo", "test_b")

  ts.err_testcase(1.0, "jh.Foo", "test_c", "2 > 1", "assert", "111\n222\n333\n")

  ts = jf.new_testsuite("bar")
  ts.ok_testcase(1.0, "jh.Bar", "test_x")

  jf.write
end
