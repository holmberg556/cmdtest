# -*- ruby -*-

ENV["LC_ALL"] = "C" if RUBY_PLATFORM =~ /darwin/

desc "run regression tests"
task "test" do
  sh "ruby -w run-regression.rb"
end

desc "generate HTML manual"
task "html" do
  sh "rst2html.py -gds --stylesheet doc/rst.css doc/cmdtest.txt doc/cmdtest.html"
end

desc "generate HTML README"
task "readme-html" do
  sh "rst2html.py -gds --stylesheet doc/rst.css README.rst README.html"
end

desc "generate DEB package"
task "generate-debian-package" do
  sh "rm -rf build"
  sh "mkdir build"
  sh "cd build && cmake .. && make package"
end
