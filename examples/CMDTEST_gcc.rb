#----------------------------------------------------------------------
# CMDTEST_gcc.rb
#----------------------------------------------------------------------
# Copyright 2010 Johan Holmberg.
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

class CMDTEST_gcc < Cmdtest::Testcase

  #----------------------------------------

  def test_no_arguments
    cmd "gcc" do
      stderr_equal [
        /^.*gcc.*: no input files/,
      ]
      exit_nonzero
    end
  end

  #----------------------------------------

  def test_nonexisting_input
    cmd "gcc -c non-existing.c" do
      stderr_equal [
        /^.*gcc.*: non-existing.c: No such file/,
        /^.*gcc.*: no input files/,
      ]
      exit_nonzero
    end

    cmd "gcc non-existing.c" do
      stderr_equal [
        /^.*gcc.*: non-existing.c: No such file/,
        /^.*gcc.*: no input files/,
      ]
      exit_nonzero
    end

    cmd "gcc non-existing.o" do
      stderr_equal [
        /^.*gcc.*: non-existing.o: No such file/,
        /^.*gcc.*: no input files/,
      ]
      exit_nonzero
    end
  end

  #----------------------------------------

  def test_compile_only

    create_file "alpha.c", "int add_alpha(int x, int y) { return x+y; }"

    cmd "gcc -c alpha.c" do
      created_files "alpha.o"
    end

    create_file "beta.c", "int add_beta(int x, int y) { return x+y; }"
    create_file "gamma.c", "int add_gamma(int x, int y) { return x+y; }"

    cmd "gcc -c beta.c gamma.c" do
      created_files "beta.o", "gamma.o"
    end

    cmd "gcc alpha.c -c" do
      written_files "alpha.o"
    end

    cmd "gcc beta.c -c gamma.c" do
      written_files "beta.o", "gamma.o"
    end

    cmd "gcc -c alpha.o" do
      stderr_equal [
        /^.*gcc.*: alpha.o: linker input file unused because linking not done/,
      ]
    end

    cmd "gcc -c alpha.o beta.o" do
      stderr_equal [
        /^.*gcc.*: alpha.o: linker input file unused because linking not done/,
        /^.*gcc.*: beta.o: linker input file unused because linking not done/,
      ]
    end
  end

  #----------------------------------------

  def test_compile_output

    create_file "alpha.c", "int add_alpha(int x, int y) { return x+y; }"

    cmd "gcc -c alpha.c -o alpha.o" do
      created_files "alpha.o"
    end

    cmd "gcc -c alpha.c -o beta.o" do
      created_files "beta.o"
    end

    cmd "gcc -o gamma.o -c alpha.c" do
      created_files "gamma.o"
    end
  end

  #----------------------------------------

  def test_link

    create_file "alpha.c", "int main() { return 17; }"

    cmd "gcc -c alpha.c" do
      created_files "alpha.o"
    end

    cmd "gcc alpha.o" do
      created_files "a.out"
    end

    cmd "gcc alpha.o -o beta" do
      created_files "beta"
    end

    cmd "gcc -o gamma alpha.o" do
      created_files "gamma"
    end

  end

  #----------------------------------------

  def test_link_2

    create_file "alpha.c", "extern int beta ; int main() { return beta; }"
    create_file "beta.c", "int beta = 17;"

    cmd "gcc -c alpha.c beta.c" do
      created_files "alpha.o", "beta.o"
    end

    cmd "gcc alpha.o beta.o" do
      created_files "a.out"
    end

    cmd "gcc alpha.o beta.o -o beta" do
      created_files "beta"
    end

    cmd "gcc -o gamma alpha.o beta.o" do
      created_files "gamma"
    end

  end

  #----------------------------------------

  def test_compile_and_link

    create_file "alpha.c", "extern int beta ; int main() { return beta; }"
    create_file "beta.c", "int beta = 17;"

    cmd "gcc alpha.c beta.c" do
      created_files "a.out"
    end

    cmd "gcc alpha.c beta.c -o gamma" do
      created_files "gamma"
    end

    cmd "gcc -o delta alpha.c beta.c" do
      created_files "delta"
    end

    cmd "gcc -c alpha.c" do
      created_files "alpha.o"
    end

    cmd "gcc -o epsilon alpha.o beta.c" do
      created_files "epsilon"
    end

  end

  #----------------------------------------

  def test_preprocess

    create_file "alpha.c", [
      "#define VALUE 17",
      "int variable = VALUE;",
    ]

    cmd "gcc -E alpha.c" do
      stdout_equal /"alpha.c"/
      stdout_equal /^int variable = 17;/
    end

    cmd "gcc -E alpha.c -o alpha.preprocessed" do
      created_files "alpha.preprocessed"
      file_equal "alpha.preprocessed", /"alpha.c"/
      file_equal "alpha.preprocessed", /^int variable = 17;/
    end
  end

  #----------------------------------------

end
