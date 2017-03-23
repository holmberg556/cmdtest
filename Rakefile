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
  date = ENV["CMDTEST_DATE"] || Time.now.strftime("%Y%m%d.%H%M")

  sh "rm -rf build"
  sh "mkdir build"
  sh "cd build && cmake -DCMDTEST_DATE=#{date} .. && make package"

  sh "rm -rf build_simple"
  sh "mkdir build_simple"
  sh "cd build_simple && cmake -DCMDTEST_DATE=#{date} -DCMDTEST_SIMPLE=YES .. && make package"
end
