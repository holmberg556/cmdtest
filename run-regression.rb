#!/usr/local/bin/ruby
#----------------------------------------------------------------------
# run-regression.rb
#----------------------------------------------------------------------
# Copyright (c) 2007,2008,2009 by Johan Holmberg. All rights reserved.
#----------------------------------------------------------------------
# @(#) $Id$
#----------------------------------------------------------------------

require "rbconfig"
require "dbm"
require "digest/md5"

#----------------------------------------------------------------------

TMPFILES = [
  "tmp-cmdtest-2",
  "tmp-cmdtest-2/tmp-command.sh",
  "tmp-cmdtest-2/tmp-stderr.log",
  "tmp-cmdtest-2/tmp-stdout.log",
  "tmp-cmdtest-2/workdir",
  "tmp-cmdtest-2/workdir/TIMESTAMP"
]

class ActualTcRegression

    def initialize
        @count = 0
        @f = File.open("TC_actual-regression.rb", "w")

        @f.puts [
            "class TC_cmdtest < Cmdtest::Testcase",
            "",
            "  def setup",
            TMPFILES.map {|file| "    ignore_file #{file.inspect}" },
            "  end",
            "",
        ]

    end

    def _list_elements(level, lines)
        lines.map do |line|
            "  " * level + line.inspect + ","
        end
    end

    def _indent(level, lines)
        lines.map do |line|
            "  " * level + line
        end
    end

    def _gen_count
        @count += 1
    end

    def _comment_str(lines)
        lines.each do |line|
            if line =~ /^#/              # ..
                res = line.sub(/^#\s*/, "")
                return res
            end
        end
        return "no comment given"
    end

    def add(prefix, code, stdout)
        @f.puts [
            "  def test_#{_gen_count}",
            "    create_file \"TC_tmp.rb\", [",
            "      'class TC_cmdtest < Cmdtest::Testcase',",
            "      '  def test_foo',",
            _list_elements(3, _indent(2, prefix)),
            _list_elements(3, _indent(2, code)),
            "      '  end',",
            "      'end',",
            "    ]",
            "",
            "    cmd 'cmdtest.rb --quiet' do",
            "      comment #{_comment_str(code).inspect}",
            "      stdout_equal [",
            _list_elements(4, stdout),
            "      ]",
            "    end",
            "  end",
            "",
        ].flatten
    end

    def write
        @f.puts [
            "",
            "end",
            "",
        ]

        @f.close
    end
end

#----------------------------------------------------------------------

class ActualRegression

    def initialize
        @o2 = ActualTcRegression.new

        @f = File.open("actual-regression.rb", "w")
    end

    def add(prefix, code, stdout)
        prefix   = prefix.map {|line| line.chomp }
        code     = code  .map {|line| line.chomp }
        stdout   = stdout.map {|line| line.chomp }

        @o2.add(prefix,code,stdout)

        @f.puts prefix
        @f.puts "#" + "-" * 35
        @f.puts code
        @f.puts "# stdout begin"
        @f.puts stdout.map {|line| "# %s" % [line] }
        @f.puts "# stdout end"
    end

    def write
        @o2.write

        @f.close
    end
end

#----------------------------------------------------------------------

class RegressionData

    def initialize(files)
        @lines = files.map {|file| File.readlines(file) }.flatten
        @i = 0
    end

    def eof?
        j = @i
        while j < @lines.size && @lines[j].strip.empty?
            j += 1
        end
        return j >= @lines.size
    end

    def skip_to(pattern)
        # ignore return value
        get_to(pattern)
    end

    def _show_line(i)
        puts "%d: %s" % [
            i,
            @lines[i],
        ]
    end

    def get_to(pattern)
        res = []
        i1 = @i
        while ! eof? && @lines[@i] !~ pattern
            _show_line(@i) if $opt_verbose
            res << @lines[@i]
            @i += 1
        end
        if eof?
            puts "Error: looking at:"
            _show_line(i1)
            raise "eof looking for #{pattern}"
        end
        # get past matching line
        @i += 1
        return res
    end
end

#----------------------------------------------------------------------

SystemResult = Struct.new(:status, :stdout, :stderr)

def my_system(cmd)
    full_cmd = "#{cmd} > tmp-stdout 2> tmp-stderr"
    #puts "+ #{full_cmd}"
    ok = system full_cmd
    status = $?.exitstatus
    stdout = File.readlines("tmp-stdout")
    stderr = File.readlines("tmp-stderr")
    if status != 0
        puts "INTERNAL ERROR:"
        puts "STDOUT:"
        puts stdout
        puts "STDERR:"
        puts stderr
        exit 1
    end
    #p [:my_system, cmd, status, stdout, stderr]
    return SystemResult.new(status, stdout, stderr)
end    

#----------------------------------------------------------------------

def indented(lines)
    lines.map {|line| "    " + line.to_s }
end

#----------------------------------------------------------------------

def matching_arrays(a,b)
    return false if a.size != b.size
    a.each_index do |i|
        return false unless a[i] === b[i]
    end
    return true
end

#----------------------------------------------------------------------

$opt_verbose = false
$opt_only = nil
$opt_remember = false

while /^-/ =~ ARGV[0]
    arg = ARGV.shift
    case arg
    when "-v"
        $opt_verbose = true
    when "-r"
        $opt_remember = true
    when /^--only=(\d+)$/
        $opt_only = $1.to_i
    else
        puts "Error: unknown option: #{arg}"
        exit 1
    end
end

ENV["PATH"] = (File.expand_path("t/bin") +
                   Config::CONFIG["PATH_SEPARATOR"] +
                   ENV["PATH"])

files = ARGV.empty? ? Dir.glob("t/*.rb") : ARGV
rd = RegressionData.new(files)

tests = []

while ! rd.eof?
    prefix = rd.get_to( /^#----------/ )
    code   = rd.get_to( /^# stdout begin/ )
    stdout = rd.get_to( /^# stdout end/ ).map do |line|
        if line =~ /^# (.*\n)/ #..
            $1
        elsif line =~ /^#\/(.*)/ #..
            Regexp.new($1)
        else
            line                # should not occur
        end
    end
    tests << [prefix, code, stdout]
end

puts "###"
puts "### found %d tests in file." % [tests.size]
puts "###"

act = ActualRegression.new

already_ok = DBM.open("already_ok")
if ! $opt_remember
    already_ok.clear
end

errors = 0
iii = -1
for prefix, code, stdout in tests
    iii += 1
    next if $opt_only && iii != $opt_only

    digest = Digest::MD5.hexdigest([prefix,code,stdout].flatten.join)
    if already_ok.has_key?(digest)
        #puts "### #{iii}: %s ... [[cahced]]" % [code[0].chomp]
        next
    end

    code_str = code.join("\n")
    if code_str =~ /REQUIRE: \s+ (.*)/x
        expr = $1
        if ! eval(expr)
            puts "### #{iii}: SKIP: %s: %s ..." % [expr, code[0].chomp]
            act.add(prefix, code, stdout)
            next
        end
    end

    puts "### #{iii}: %s ..." % [code[0].chomp]

    lines = []
    #lines << "require 'Test/Cmd'"
    lines << ""
    lines << "class TC_foo < Cmdtest::Testcase"
    lines << ""
    lines << "    def test_foo"
    lines << code
    lines << "    end"
    lines << ""
    lines << "end"
    lines << ""
    lines.flatten!

    File.open("CMDTEST_tmp_regression.rb", "w") do |f|
        f.puts lines
    end

    res = my_system "ruby -w bin/cmdtest.rb --quiet --ruby_s CMDTEST_tmp_regression.rb"
    if res.status != 0
        puts "ERROR: non-zero exit from:"
        puts lines
        exit 1
    end
    if matching_arrays(stdout, res.stdout)
        already_ok[digest] = true
    else
        puts "ERROR: unexpected STDOUT:"
        puts "ACTUAL:"
        puts indented(res.stdout)
        puts "EXPECTED:"
        puts indented(stdout)
        errors += 1
    end

    act.add(prefix, code, res.stdout)
end

act.write

puts
if errors == 0
    puts "### all tests OK"
else
    puts "--- error in #{errors} tests"
end
puts
