#----------------------------------------------------------------------
# methodfilter.rb
#----------------------------------------------------------------------
# Copyright 2009 Johan Holmberg.
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
  class MethodFilter

    def initialize(filter_filename, runner)
      @filter_filename = filter_filename
      @runner = runner
      @filter = {}
      if @runner.opts.incremental && File.file?(@filter_filename)
        File.open(filter_filename, "r") do |f|
          while line = f.gets
            line.chomp!
            key, signature = line.split(/\t/, 2)
            @filter[key] = signature
          end
        end
      end

      @files_read = {}
      @signatures = {}
      @new_filter = {}
    end

    def write
      File.open(@filter_filename, "w") do |f|
        for key in @new_filter.keys.sort
          f.puts "%s\t%s" % [
            key,
            @new_filter[key],
          ]
        end
      end
    end

    def skip?(file, klass, method)
      _maybe_read_ruby_file(file.path)
      key = _method_key(file.path, klass.display_name, method)
      #p [:skip, key, @signatures[key], @filter[key]]
      @new_filter[key] = @signatures[key]
      return @new_filter[key] && @new_filter[key] ==  @filter[key]
    end

    def error(file, klass, method)
      key = _method_key(file.path, klass.display_name, method)
      @new_filter.delete(key)
    end

    def _maybe_read_ruby_file(file)
      return if @files_read[file]
      @files_read[file] = true

      if File.file?(file)
        method_signatures = _collect_method_signatures(file)
        @signatures.merge!(method_signatures)
      end
    end

    # Collect signatures of all methods, as found in the CMDTEST_*.rb file.

    def _collect_method_signatures(file)
      method_signatures = {}
      lines = File.readlines(file)
      klass  = klass_indent  = klass_i  = nil
      method = method_indent = method_i = nil

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

        when klass && line =~ /^(#{klass_indent}\s+)def\s+(test_\w+)\b/ #...
          method = $2
          method_indent = $1
          method_i = i
          ## p [:method_begin, method]

        when method && line =~ /^#{method_indent}end\b/ #...
          ## p [:method_end, method]
          key = _method_key(file, klass, method)
          method_signatures[key] = _method_signature(lines[method_i..i])
          method = nil
          method_indent = nil
        end
      end
      return method_signatures
    end
    
    def _method_signature(content)
      Digest::MD5.hexdigest(content.join)
    end

    def _method_key(file, klass, method)
      file + ":" + klass + "." + method
    end

  end
end
