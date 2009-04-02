
Cmdtest - a program for testing executable programs
===================================================

"cmdtest" is a program to test executable programs. Tests are written in
an "xunit style", using assertions about created files, content of
standard output, exit code, etc. "cmdtest" is written in Ruby.
It consists of a main program and a number of library files.

Documentation
-------------

A "Cmdtest User Guide" can be found in the file `<doc/cmdtest.html>`_.
It is generated from the file "cmdtest.txt" which is written in
reStructuredText format. There is also an `<examples>`_ directory with
some real-world examples of using "cmdtest".

Installation
------------

No installation is needed to use "cmdtest". The file
"cmdtest.rb" can be executed directly from where it is checked out.

But the program can also be installed. Use the following command::

  $ svn co http://cmdtest.googlecode.com/svn/trunk cmdtest
  $ cd cmdtest
  $ ruby setup.rb            # sudo may be needed

For details about options to ``setup.rb`` use ``ruby setup.rb --help``
or see <http://i.loveruby.net/en/projects/setup/doc/usage.html>.

License
-------

"cmdtest" is released under the GNU General Public License version 3.
For details see the file `<COPYING.txt>`_ in the same directory as this file.

History
-------

I got the idea to create "cmdtest" when I was using and making changes to Cons,
the make-replacement written in Perl. The program had tests written
using the Perl module Test::Cmd. Later I developed other
programs that also needed some kind of "unit tests" for the executables.
I looked for existing tools but could not find anything that I was completely
comfortable with. So I started to develop my own tool, and the result was
"cmdtest".

Author
------

"cmdtest" was created by Johan Holmberg <holmberg556 at gmail dot com>.

