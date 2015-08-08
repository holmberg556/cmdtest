#----------------------------------------------------------------------
# argumentparser.rb
#----------------------------------------------------------------------
# Copyright 2015 Johan Holmberg.
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

    class Option

        attr_reader :sname, :name, :help

        def initialize(sname, name, help, args)
            @sname = sname
            @name = name
            @help = help
            @extra = args
        end

        def init(opts)
            if _with_arg
                if @extra[:default]
                    opts[_opt_name] = @extra[:default]
                elsif Array === @extra[:type]
                    opts[_opt_name] = []
                else
                    opts[_opt_name] = nil
                end
            else
                opts[_opt_name] = false
            end
        end

        def _set(value, opts)
            if _with_arg
                if @extra[:type] == String
                    opts[_opt_name] = value
                elsif @extra[:type] == Integer
                    opts[_opt_name] = Integer(value)
                elsif @extra[:type] == [String]
                    opts[_opt_name] << value
                elsif @extra[:type] == [Integer]
                    opts[_opt_name] << Integer(value)
                else
                    raise RuntimeError, "unknown type"
                end
            else
                opts[_opt_name] = true
            end
        end

        def usage_text
            res = @sname.length == 0 ? name : sname
            res += _arg_extra()
            return "[" + res + "]"
        end

        def _arg_extra
            return _with_arg ? " " + _arg_name() : ""
        end

        def _with_arg
            return @extra[:type]
        end

        def _opt_name
            return @name.sub(/^-+/, "").gsub("-", "_")
        end

        def _arg_name
            return @extra[:metavar] if @extra[:metavar]
            return _opt_name.upcase
        end

        def names
            extra = _with_arg() ? " " + _arg_name() : ""
            if @sname.length == 0
                return name + extra
            else
                return sname + extra + ", " + name + extra
            end
        end

    end

    #----------------------------------------------------------------------

    class Argument
        attr_reader :name, :help

        def initialize(name, help, args)
            @name = name
            @help = help
            @extra = args
        end

        def usage_text
            n = @extra[:nargs] || 1
            if Range === n && n.begin == 0
                return "[" + @name + " [" + @name + " ...]]"
            else
                raise RuntimeError, "unexpected"
            end
        end

    end

    #----------------------------------------------------------------------

    class ArgumentParser

        def initialize(program)
            @program = program
            @options = []
            @argv = nil
            @optind = nil

            @help = false

            @args = []

            add("-h", "--help", "show this help message and exit")
        end

        def add(sname, name, help, args = {})
            option = Option.new(sname, name, help, args)
            @options << option
        end

        def addpos(name, help, args = {})
            @args << Argument.new(name, help, args)
        end

        def print_usage_synopsis(f)
            leading = "usage: " + @program
            f.print(leading)
            off = leading.size

            for option in @options
                str = option.usage_text()
                if off + 1 + str.size > 79
                    f.puts
                    f.print(" " * leading.size)
                    off = leading.length
                end
                f.print(" ", str)
                off += 1 + str.size
            end
            f.puts

            if @args.size > 0
                f.print(" " * leading.size)
                f.print(" ")
                f.print(@args.map {|arg| arg.usage_text() }.join(" "), "\n")
            end
        end

        def print_usage()
            print_usage_synopsis(STDOUT)

            if @args.size > 0
                puts
                puts("positional arguments:")
                for arg in @args
                    print("  ", arg.name, "           ", arg.help, "\n")
                end
                puts
            end
            puts("optional arguments:")
            puts("  -h, --help            show this help message and exit")
            for option in @options
                str = "  " + option.names()
                wanted = 22
                str = str.ljust(wanted)
                if str.size > wanted
                    puts(str)
                    print(" " * wanted, "  ", option.help, "\n")
                else
                    print(str, "  ", option.help, "\n")
                end
            end
        end

        def parse_args(argv, extras = {})
            @argv = argv
            @opts = {}

            # initialize options
            for option in @options
                option.init(@opts)
            end

            @optind = 0
            while _more_args() && _arg() =~ /^-./
                if _arg() == "-h"
                    print_usage()
                    exit(0)
                end

                if _arg() == "--"
                    @optind += 1
                    break
                end

                # -f
                if _arg() =~ /^(-\w)$/
                    option = _find_option($1)
                    if option._with_arg()
                        if ! _more_args(1)
                            print_usage_synopsis(STDERR);
                            STDERR.print(@program, ": error: argument ",
                                         option.show(), ": expected one argument")
                            exit(2)
                        end
                        option._set(_arg(1), @opts)
                        @optind += 2
                    else
                        option._set(true, @opts)
                        @optind += 1
                    end

                    # -f...
                elsif _arg() =~ /^(-\w)(.+)/
                    option = _find_option($1)
                    if option._with_arg()
                        option._set($2, @opts)
                        @optind += 1
                    else
                        option._set(true, @opts)
                        _setarg("-" + $2)
                    end

                    # --foo
                elsif _arg() =~ /^(--\w[-\w]*)$/
                    option = _find_option($1)
                    if option._with_arg()
                        option._set(_arg(1), @opts)
                        @optind += 2
                    else
                        option._set(true, @opts)
                        @optind += 1
                    end

                    # --foo=...
                elsif _arg() =~ /^(--\w[-\w]*)=(.*)$/
                    option = _find_option($1)
                    if option._with_arg()
                        option._set($2, @opts)
                        @optind += 1
                    else
                        print_usage_synopsis(STDERR)
                        STDERR.print(@program, ": error: argument: ",
                                     option.show(), ": ignored explicit argument '",
                                     $2, "'");
                        exit(2)
                    end

                else
                    STDERR.print("INTERNAL ERROR: arg = ", _arg())
                    raise RuntimeError("unexpected else ...");
                end
            end

            fields = @opts.keys.sort + ["args"]
            all_fields = fields + extras.keys.sort
            res_class = Struct.new("GivenOptions", *all_fields)
            values = fields.map {|k| @opts[k] }
            res = res_class.new(*values)
            res.args = []
            for k,v in extras
                res[k] = v
            end

            if @args.size > 0
                res.args.concat(@argv[@optind..999]) # TODO
            elsif @optind < @argv.size
                raise RuntimeError("too many options")
            end
            return res
        end

        def _find_option(name)
            for option in @options
                return option if option.name == name
                return option if option.sname == name
            end
            print_usage_synopsis(STDERR)
            STDERR.print(@program, ": error: unrecognized arguments: ", name, "\n")
            exit(2)
        end

        def _arg(i=0)
            if @optind + i < @argv.size
                return @argv[@optind + i]
            else
                raise RuntimeError("index out of range");
            end
        end

        def _setarg(value)
            if @optind < @argv.size
                @argv[@optind] = value
            else
                raise RuntimeError("index out of range");
            end
        end

        def _more_args(i=0)
            return @optind + i < @argv.size
        end

    end

end
