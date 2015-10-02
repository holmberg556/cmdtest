#!/usr/bin/ruby

top_dir = File.dirname(File.dirname(__FILE__))
lib_dir = File.join(File.expand_path(top_dir), "lib")
$:.unshift(lib_dir) if File.directory?(File.join(lib_dir, "cmdtest"))

require "cmdtest/argumentparser"


pr = Cmdtest::ArgumentParser.new("jcons_cmds")

pr.add("-q", "--quiet",       "be more quiet")
pr.add("-j", "--parallel",    "build in parallel",  type: Integer, default: 1, metavar: "N")

pr.add("-k", "--keep-going",  "continue after errors")
pr.add("-B", "--always-make", "always build targets")
pr.add("-r", "--remove",      "remove targets")
pr.add("",   "--accept-existing-target", "make updating an existing target a nop")

pr.add("", "--dont-trust-mtime", "always consult files for content digest")

pr.add("-f", "--file",        "name of *.cmds file", type: [String])
pr.add("-v", "--verbose",     "be more verbose")
pr.add("",   "--version",     "show version")

pr.add("",   "--cache-dir",   "name of cache directory", type: String)
pr.add("",   "--cache-force", "copy existing files into cache")

pr.add("-p", "--list-targets", "list known targets")
pr.add("",   "--list-commands","list known commands")
pr.add("",   "--log-states",   "log state machine")

pr.addpos("arg", "target or NAME=VALUE", nargs: 0..999)

opts = pr.parse_args(ARGV)

p opts
