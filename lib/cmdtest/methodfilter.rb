#----------------------------------------------------------------------
# methodfilter.rb
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

require "json"

module Cmdtest
  class MethodFilter

    def initialize(cwd, incremental, runner)
      @incremental = incremental
      @cwd = cwd
      @filter_filename = File.expand_path(".cmdtest-filter", @cwd)

      @runner = runner

      if @runner.opts.incremental && File.file?(@filter_filename)
        File.open(@filter_filename, "r") do |f|
          @filter = JSON.load(f)
        end
      else
        @filter = {}
      end

      @files_read = {}
      @signatures = {}
      @new_filter = @filter.dup
    end

    def write
      File.open(@filter_filename, "w") do |f|
        f.puts JSON.pretty_generate(@new_filter)
      end
    end

    def _get_method_signature(method_id)
      _maybe_read_ruby_file(method_id.file)
      return @signatures[method_id.key] || "NO-SIGNATURE-FOUND"
    end

    def skip?(method_id)
      return @incremental && @new_filter[method_id.key] == _get_method_signature(method_id)
    end

    def success(method_id)
      @new_filter[method_id.key] = _get_method_signature(method_id)
    end

    def failure(method_id)
      @new_filter.delete(method_id.key)
    end

    def _maybe_read_ruby_file(file)
      return if @files_read[file]
      @files_read[file] = true

      path = File.expand_path(file, @cwd)
      if File.file?(path)
        method_signatures = _collect_method_signatures(file, path)
        @signatures.merge!(method_signatures)
      end
    end

    # Collect signatures of all methods, as found in the CMDTEST_*.rb file.

    def _collect_method_signatures(file, path)
      method_signatures = {}
      lines = File.readlines(path)
      klass  = klass_indent  = klass_i  = nil
      methods = method_indent = method_i = nil

      lines.each_with_index do |line, i|
        case
        when line =~ /^ (\s*) class \s+ (\w+) \s* < \s* Cmdtest::Testcase \b /x
          klass = $2
          klass_indent = $1
          klass_i = i
          ## p [:class_begin, klass]

        when klass && line =~ /^#{klass_indent}end\b/ #...
          ## p [:class_end, klass]
          klass = nil
          klass_indent = nil

        when klass && line =~ /^(#{klass_indent}\s+)## methods: (.*)$/ #...
          methods = $2.split
          method_indent = $1
          method_i = i
          ## p [:method_begin, methods]

        when klass && line =~ /^(#{klass_indent}\s+)def\s+(test_\w+)\b/ #...
          methods = [$2]
          method_indent = $1
          method_i = i
          ## p [:method_begin, methods]

        when klass && methods && line =~ /^#{method_indent}end\b/ #...
          ## p [:method_end, methods]
          for method in methods
            key = MethodId.new(file, klass, method).key
            method_signatures[key] = _method_signature(lines[method_i..i])
          end
          methods = nil
          method_indent = nil
        end
      end
      return method_signatures
    end

    def _method_signature(content)
      Digest::MD5.hexdigest(content.join)
    end

  end
end
