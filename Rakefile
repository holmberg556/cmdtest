# -*- ruby -*-

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

