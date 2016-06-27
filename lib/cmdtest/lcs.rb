#----------------------------------------------------------------------
# lcs.rb
#----------------------------------------------------------------------
# Copyright 2016 Johan Holmberg.
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

  class LCS
    def print()
      i = @m
      j = @n
      while i > 0 || j > 0
        if @b[i][j] == :XY
          acc = []
          while @b[i][j] == :XY
            acc << @y[j]
            i -= 1
            j -= 1
          end
          found_xy(acc)
        elsif i > 0 && (j == 0 || @b[i][j] == :X)
          acc = []
          while i > 0 && (j == 0 || @b[i][j] == :X)
            acc << @x[i]
            i -= 1
          end
          found_x(acc)
        elsif j > 0 && (i == 0 || @b[i][j] == :Y)
          acc = []
          while j > 0 && (i == 0 || @b[i][j] == :Y)
            acc << @y[j]
            j -= 1
          end
          found_y(acc)
        else
          raise "internal error"
        end
      end
    end

    def initialize(x, y)
      @m = x.size
      @n = y.size
      @x = [nil] + x.reverse
      @y = [nil] + y.reverse
      @c = Array.new(@m+1) { Array.new(@n+1) }
      @b = Array.new(@m+1) { Array.new(@n+1) }

      for i in 1..@m
        @c[i][0] = 0
      end

      for j in 0..@n
        @c[0][j] = 0
      end

      for i in 1..@m
        for j in 1..@n
          if @x[i] === @y[j]
            @c[i][j] = @c[i-1][j-1] + 1
            @b[i][j] = :XY
          elsif @c[i-1][j] >= @c[i][j-1]
            @c[i][j] = @c[i-1][j]
            @b[i][j] = :X
          else
            @c[i][j] = @c[i][j-1]
            @b[i][j] = :Y
          end
        end
      end
    end

    def found_xy(arr)
    end

    def found_x(arr)
    end

    def found_y(arr)
    end
  end

  class DiffLCS < LCS
    include Enumerable

    def found_x(arr)
      for e in arr
        if Regexp === e
          @arr << "- " + e.inspect
        else
          @arr << "- " + e
        end
      end
    end

    def found_y(arr)
      for e in arr
        @arr << "+ " + e
      end
    end

    def found_xy(arr)
      for e in arr
        @arr << "  " + e
      end
    end

    def each
      @arr = []
      print
      for e in @arr
        yield e
      end
    end
  end


end
