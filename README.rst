
Cmdtest - a program for testing executable programs
===================================================

Cmdtest_ is a program to test executable programs. Tests are written in
an "xunit style", using assertions about created files, content of
standard output, exit code, etc. Cmdtest_ is written in Ruby.
It consists of a main program and a number of library files.

Documentation
-------------

A `Cmdtest User Guide`_ is available.
It is generated from the file ``cmdtest.txt`` which is written in
reStructuredText_ format. There is also an ``examples`` directory with
some real-world examples of using Cmdtest_.

Installation
------------

No installation is needed to use Cmdtest_. The file ``cmdtest.rb`` can
be executed directly from where it is checked out or unpacked. But the
program can also be installed. Use the following command::

  $ hg clone https://bitbucket.org/holmberg556/cmdtest cmdtest
  $ cd cmdtest
  $ ruby setup.rb            # sudo may be needed

For details about options to ``setup.rb`` use ``ruby setup.rb --help``
or see <http://i.loveruby.net/en/projects/setup/doc/usage.html>.

License
-------

Cmdtest_ is released under the GNU General Public License version 3.
For details see the file ``COPYING.txt`` in the same directory as this file.

History
-------

I got the idea to create Cmdtest_ when I was using and making changes to Cons_,
the make-replacement written in Perl. The program had tests written
using the Perl module Test::Cmd. Later I developed other
programs that also needed some kind of "unit tests" for the executables.
I looked for existing tools but could not find anything that I was completely
comfortable with. So I started to develop my own tool, and the result was
Cmdtest_.

Author
------

Cmdtest_ was created by Johan Holmberg <holmberg556 at gmail dot com>.


.. _reStructuredText: http://docutils.sourceforge.net/rst.html
.. _Cmdtest:          https://bitbucket.org/holmberg556/cmdtest
.. _Cons:             http://www.dsmit.com/cons/

.. _`Cmdtest User Guide`:     http://holmberg556.bitbucket.org/cmdtest/doc/cmdtest.html
