
#----------------------------------------------------------------------
# output.rb
#----------------------------------------------------------------------
# Copyright 2010-2016 Johan Holmberg.
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

  # Formatted output

  class Output

    def initialize
      @text_stack = [""]
    end

    #------------------------------

    def text
      @text_stack.last
    end

    #------------------------------

    def _ensure_newline
      @text_stack.last << "\n" unless @text_stack.last =~ /\n$/
    end

    #------------------------------

    def _nested_scope
      @text_stack.push ""
      yield
      _ensure_newline
      @text_stack.pop
    end

    #------------------------------

    def _text_as_lines(text)
      text.chomp.split(/\n/, -1)
    end

    #------------------------------

    def boxed(&block)
      text = _nested_scope(&block)
      lines = _text_as_lines(text)
      width = lines.map {|line| line.size }.max
      boxed_text = _nested_scope do
        puts "+" + "-" * width + "+"
        text.gsub!(/^/, "|")
        puts _text_as_lines(text).map {|x| x.ljust(width + 1) + "|" }
        puts "+" + "-" * width + "+"
      end
      print(boxed_text)
    end

    #------------------------------

    def lined(&block)
      text = _nested_scope(&block)
      lines = _text_as_lines(text)
      width = lines.map {|line| line.size }.max
      used_width = [width, 10].max
      boxed_text = _nested_scope do
        puts "=" * used_width
        puts _text_as_lines(text)
        puts "=" * used_width
      end
      print(boxed_text)
    end

    #------------------------------

    def margin(&block)
      text = _nested_scope(&block)
      width = text.split(/\n/, -1).map {|line| line.size }.max
      margin_text = _nested_scope do
        puts " "
        puts text.split(/\n/, -1).map {|x| " " + x + " " }
        puts " "
      end
      print(margin_text)
    end

    #------------------------------

    def prefix(str, &block)
      text = _nested_scope(&block)
      print(text.gsub(/^/, str))
    end

    #------------------------------

    def hanging(str, &block)
      text = _nested_scope(&block)
      n = 0
      text.gsub!(/^/) do
        (n += 1) == 1 ? str : " " * str.length
      end
      print(text)
    end

    #------------------------------

    def puts(str = "")
      for line in [str].flatten
        print(line)
        print("\n") unless line =~ /\n$/
      end
    end

    #------------------------------

    def print(str)
      @text_stack.last << str
    end

    #------------------------------

    def write(str)
      @text_stack.last << str
      return str.length
    end

    #------------------------------

    def <<(arg)
      @text_stack.last << arg.to_s
      return self
    end

  end

end
