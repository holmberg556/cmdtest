#----------------------------------------------------------------------
# notify.rb
#----------------------------------------------------------------------
# Copyright 2012-2021 Johan Holmberg.
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


require "thread"

module Cmdtest

  class NotifyBase
    def initialize(queue)
      @queue = queue
    end

    def _queue_notify(arg)
      @queue << arg
    end
  end

  class NotifyBackground < NotifyBase
  end

  class NotifyForeground < NotifyBase
    def initialize(n_parallel)
      @n_parallel = n_parallel
      queue = Queue.new
      super(queue)
      @stack = [queue]
      @queue_count = 1
      _init
      yield self
      _finish
    end

    def _queue_notify(arg)
      super(arg)
      _process_queue { false }
    end

    def _finish
      @queue << :end
      _process_queue { true }
    end

    def _wait?(&blocking)
      return false if @stack.empty?
      return true if ! @stack[-1].empty?
      return blocking.call
    end

    def _get_item(&blocking)
      _wait?(&blocking) ? @stack[-1].deq : nil
    end

    def _process_queue(&blocking)
      q = @stack[-1]
      loop do
        e = _get_item(&blocking)
        break if e == nil
        case e
        when Queue
          @stack.push(e)
        when :end
          @stack.pop
          @queue_count -= 1
        else
          process_queue_item(e)
        end
      end
    end

    def background(*args, &block)
      if @n_parallel == 1
        block.call( self, *args )
      else
        q = Queue.new
        @queue << q
        @queue_count += 1
        _process_queue { @queue_count > 1 + @n_parallel }
        Thread.new do
          block.call( background_class.new(q), *args )
          q << :end
        end
      end
    end
  end

end
