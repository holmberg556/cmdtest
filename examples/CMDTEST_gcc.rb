#----------------------------------------------------------------------
# CMDTEST_gcc.rb
#----------------------------------------------------------------------
# Copyright 2010-2012 Johan Holmberg.
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

#
# Example of testing GCC command line interface using "cmdtest".
#

ENV['LC_ALL'] = 'C'

class CMDTEST_gcc < Cmdtest::Testcase

  def gcc
    ENV["CMDTEST_GCC_TO_TEST"] || "gcc"
  end

  def gxx
    ENV["CMDTEST_GXX_TO_TEST"] || "g++"
  end

  #----------------------------------------

  def test_no_arguments
    cmd "#{gcc}" do
      comment "no arguments"
      stderr_equal /^.*gcc.*: no input files/
      exit_nonzero
    end
  end

  #----------------------------------------

  def test_nonexisting_input
    cmd "#{gcc} -c non-existing.c" do
      stderr_equal /^.*gcc.*: non-existing.c: No such file/
      stderr_equal /^.*gcc.*: no input files/
      exit_nonzero
    end

    cmd "#{gcc} non-existing.c" do
      stderr_equal /^.*gcc.*: non-existing.c: No such file/
      stderr_equal /^.*gcc.*: no input files/
      exit_nonzero
    end

    cmd "#{gcc} non-existing.o" do
      stderr_equal /^.*gcc.*: non-existing.o: No such file/
      stderr_equal /^.*gcc.*: no input files/
      exit_nonzero
    end
  end

  #----------------------------------------

  def test_compile_only

    create_file "alpha.c", "int add_alpha(int x, int y) { return x+y; }"
    create_file "alpha_err.c", "int add_alpha(int x, int y) { return x+y_alpha_err; }"

    cmd "#{gcc} -c alpha.c" do
      comment "compile one file"
      created_files "alpha.o"
    end

    cmd "#{gcc} -c alpha_err.c" do
      comment "compile one file with error"
      stderr_equal /y_alpha_err/
      exit_nonzero
    end

    create_file "beta.c", "int add_beta(int x, int y) { return x+y; }"
    create_file "gamma.c", "int add_gamma(int x, int y) { return x+y; }"
    create_file "beta_err.c", "int add_beta(int x, int y) { return x+y_beta_err; }"
    create_file "gamma_err.c", "int add_gamma(int x, int y) { return x+y_gamma_err; }"

    cmd "#{gcc} -c beta.c gamma.c" do
      comment "compile two files"
      written_files "beta.o", "gamma.o"
    end

    cmd "#{gcc} -c beta_err.c gamma.c" do
      comment "compile two files, the first with error"
      stderr_equal /y_beta_err/
      written_files "gamma.o"
      exit_nonzero
    end

    cmd "#{gcc} -c beta.c gamma_err.c" do
      comment "compile two files, the second with error"
      stderr_equal /y_gamma_err/
      written_files "beta.o"
      exit_nonzero
    end

    cmd "#{gcc} alpha.c -c" do
      comment "put -c after the file"
      written_files "alpha.o"
    end

    cmd "#{gcc} beta.c -c gamma.c" do
      comment "put -c between two files"
      written_files "beta.o", "gamma.o"
    end

    cmd "#{gcc} -c alpha.o" do
      comment "object file with -c"
      stderr_equal [
        /^.*gcc.*: alpha.o: linker input file unused because linking not done/,
      ]
    end

    cmd "#{gcc} -c alpha.o beta.o" do
      comment "two object files with -c"
      stderr_equal [
        /^.*gcc.*: alpha.o: linker input file unused because linking not done/,
        /^.*gcc.*: beta.o: linker input file unused because linking not done/,
      ]
    end
  end

  #----------------------------------------

  def test_compile_output

    create_file "alpha.c", "int add_alpha(int x, int y) { return x+y; }"
    create_file "beta.c", "int add_beta(int x, int y) { return x+y; }"

    cmd "#{gcc} -c alpha.c -o alpha.o" do
      comment "-o to select object file output"
      created_files "alpha.o"
    end

    cmd "#{gcc} -c alpha.c -o beta.o" do
      comment "-o to select object file output (II)"
      created_files "beta.o"
    end

    cmd "#{gcc} -o gamma.o -c alpha.c" do
      comment "-o first"
      created_files "gamma.o"
    end

    cmd "#{gcc} -o gamma.o -c alpha.c beta.c" do
      comment "-o with two source files give error"
      stderr_equal /^.*gcc.*: cannot specify -o with -c.* with multiple files/
      exit_nonzero
    end
  end

  #----------------------------------------

  def test_link

    create_file "alpha.c", "int main() { return 17; }"
    create_file "alpha_err.c", "extern int undefined_var; int main() { return undefined_var; }"

    cmd "#{gcc} -c alpha.c" do
      comment "compile source file"
      created_files "alpha.o"
    end

    cmd "#{gcc} alpha.o" do
      comment "link object file"
      created_files "a.out"
    end

    cmd "#{gcc} alpha.o -o beta" do
      comment "link object file with -o"
      created_files "beta"
    end

    cmd "#{gcc} -o gamma alpha.o" do
      comment "-o first"
      created_files "gamma"
    end

    cmd "#{gcc} -c alpha_err.c" do
      created_files "alpha_err.o"
    end

    cmd "#{gcc} alpha_err.o -o alpha_err" do
      comment "failed linking"
      stderr_equal /undefined_var/
      exit_nonzero
    end

  end

  #----------------------------------------

  def test_link_2

    create_file "alpha.c", "extern int beta_var ; int main() { return beta_var; }"
    create_file "beta.c", "int beta_var = 17;"
    create_file "beta_err.c", "int beta_var_err = 17;"

    cmd "#{gcc} -c alpha.c beta.c" do
      comment "compile two source files"
      created_files "alpha.o", "beta.o"
    end

    cmd "#{gcc} alpha.o beta.o" do
      comment "link two object files"
      created_files "a.out"
    end

    cmd "#{gcc} alpha.o beta.o -o beta" do
      comment "link two object files with -o"
      created_files "beta"
    end

    cmd "#{gcc} -o gamma alpha.o beta.o" do
      comment "-o first"
      created_files "gamma"
    end

    cmd "#{gcc} -c beta_err.c" do
      created_files "beta_err.o"
    end

    cmd "#{gcc} -o gamma_err alpha.o beta_err.o" do
      comment "failed linking of two object files"
      stderr_equal /beta_var/
      exit_nonzero
    end
  end

  #----------------------------------------

  def test_compile_and_link

    create_file "alpha.c", "extern int beta_var ; int main() { return beta_var; }"
    create_file "beta.c", "int beta_var = 17;"
    create_file "beta_err.c", "int beta_var_err = 17;"

    cmd "#{gcc} alpha.c beta.c" do
      comment "compile and link two source files"
      created_files "a.out"
    end

    cmd "#{gcc} alpha.c beta.c -o gamma" do
      comment "compile and link two source files with -o"
      created_files "gamma"
    end

    cmd "#{gcc} -o delta alpha.c beta.c" do
      comment "-o first"
      created_files "delta"
    end

    cmd "#{gcc} -o delta_err alpha.c beta_err.c" do
      comment "failed compile and link two source files"
      stderr_equal /beta_var/
      exit_nonzero
    end

    cmd "#{gcc} -c alpha.c" do
      created_files "alpha.o"
    end

    cmd "#{gcc} -o epsilon alpha.o beta.c" do
      comment "compile one file and link two files"
      created_files "epsilon"
    end

  end

  #----------------------------------------

  def test_preprocess

    create_file "alpha.c", [
      "#define VALUE 17",
      "int variable = VALUE;",
    ]

    create_file "alpha_err.c", [
      "#define VALUE(1729)",
      "int variable = VALUE;",
    ]

    cmd "#{gcc} -E alpha.c" do
      stdout_equal /"alpha.c"/
      stdout_equal /^int variable = 17;/
    end

    cmd "#{gcc} -E alpha_err.c" do
      stdout_equal /"alpha_err.c"/
      stderr_equal /1729/
      exit_nonzero
    end

    cmd "#{gcc} -E alpha.c -o alpha.preprocessed" do
      created_files "alpha.preprocessed"
      file_equal "alpha.preprocessed", /"alpha.c"/
      file_equal "alpha.preprocessed", /^int variable = 17;/
    end

    cmd "#{gcc} -E alpha_err.c -o alpha_err.preprocessed" do
      stderr_equal /1729/
      exit_nonzero
    end
  end

  #----------------------------------------

  def test_defines

    create_file "alpha.c", [
      "#ifndef AAA",
      "#define AAA aaa_in_file",
      "#endif",
      "#ifndef BBB",
      "#define BBB bbb_in_file",
      "#endif",
      "AAA --- BBB",
    ]

    cmd "#{gcc} -E alpha.c" do
      stdout_equal /^aaa_in_file --- bbb_in_file/
    end

    cmd "#{gcc} -DAAA=aaa_option -E alpha.c" do
      stdout_equal /^aaa_option --- bbb_in_file/
    end

    cmd "#{gcc} -DAAA=aaa_option -DBBB=bbb_option -E alpha.c" do
      stdout_equal /^aaa_option --- bbb_option/
    end

  end

  #----------------------------------------

  def test_includes

    create_file "alpha.c", [
      "#include <alpha.h>",
    ]

    create_file "dir1/alpha.h", "this_is_dir1"
    create_file "dir2/alpha.h", "this_is_dir2"

    cmd "#{gcc} -Idir1 -E alpha.c" do
      stdout_equal /this_is_dir1/
    end

    cmd "#{gcc} -Idir2 -E alpha.c" do
      stdout_equal /this_is_dir2/
    end

    cmd "#{gcc} -Idir1 -Idir2 -E alpha.c" do
      stdout_equal /this_is_dir1/
    end

    cmd "#{gcc} -Idir2 -Idir1 -E alpha.c" do
      stdout_equal /this_is_dir2/
    end

    create_file "beta.c", [
      "#include <beta1.h>",
      "#include <beta2.h>",
      "#include <beta12.h>",
    ]

    create_file "dir1/beta1.h", "dir1_beta1_h"
    create_file "dir1/beta12.h", "dir1_beta12_h"

    create_file "dir2/beta2.h", "dir2_beta2_h"
    create_file "dir2/beta12.h", "dir2_beta12_h"

    cmd "#{gcc} -Idir1 -Idir2 -E beta.c" do
      stdout_equal /dir1_beta1_h/
      stdout_equal /dir1_beta12_h/
      stdout_equal /dir2_beta2_h/
    end

    cmd "#{gcc} -Idir2 -Idir1 -E beta.c" do
      stdout_equal /dir1_beta1_h/
      stdout_equal /dir2_beta12_h/
      stdout_equal /dir2_beta2_h/
    end

  end

  #----------------------------------------

  def test_gcc_vs_gxx

    simple_cxx = [
      "#include <iostream>",
      "int main() { std::cout << \"hello\" << std::endl; return 0; }",
    ]
    create_file "alpha.c", simple_cxx
    create_file "alpha.cpp", simple_cxx

    cmd "#{gcc} -c alpha.c" do
      stderr_equal /iostream/
      exit_nonzero
    end

    cmd "#{gcc} -c alpha.cpp" do
      created_files "alpha.o"
    end

    cmd "#{gxx} -c alpha.c" do
      written_files "alpha.o"
    end

    cmd "#{gxx} -c alpha.cpp" do
      written_files "alpha.o"
    end

  end

  #----------------------------------------

  def setup_MD_MF_MT
    Dir.mkdir "obj"
    Dir.mkdir "other_dir"

    create_file "src/foo.h", [
      '#define HELLO "hello\n"',
    ]
    create_file "src/foo.c", [
      '#include <stdio.h>',
      '#include "foo.h"',
      'int main() { printf(HELLO); return 0; }',
    ]
  end

  def test_MD_MF
    setup_MD_MF_MT

    cmd "#{gcc} -c src/foo.c -o obj/bar.o" do
      comment "normal compile"
      written_files "obj/bar.o"
    end

    cmd "#{gcc} -MD -c src/foo.c -o obj/bar.o" do
      comment "using -MD (generate dependency file)"
      written_files "obj/bar.o", "obj/bar.d"
    end

    cmd "#{gcc} -MD -MF other_dir/other_name.d -c src/foo.c -o obj/bar.o" do
      comment "using -MD and -MF (name dependency file)"
      written_files "obj/bar.o", "other_dir/other_name.d"
      file_equal "other_dir/other_name.d", /^obj\/bar.o: /
    end
  end

  #----------------------------------------

  def test_MT
    setup_MD_MF_MT

    cmd "#{gcc} -MD -MT xxxxxx -MF other_dir/other_name.d -c src/foo.c -o obj/bar.o" do
      comment "using -MD -MF and -MT (name target in dependency file)"
      written_files "obj/bar.o", "other_dir/other_name.d"
      file_equal "other_dir/other_name.d", /^xxxxxx: /
    end

  end

  #----------------------------------------

  def XXX_test_gcc_vs_gxx_linking

    simple_cxx = [
      "#include <iostream>",
      "int main() { std::cout << \"hello\" << std::endl; return 0; }",
    ]
    create_file "alpha.cpp", simple_cxx

    cmd "#{gxx} -c alpha.cpp" do
      written_files "alpha.o"
    end

    cmd "#{gcc} alpha.o" do
      stderr_equal /main/
      exit_nonzero
    end

    cmd "#{gxx} alpha.o" do
      written_files "a.out"
    end

  end

  #----------------------------------------

end
