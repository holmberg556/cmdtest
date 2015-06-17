#!/usr/bin/env python3
#----------------------------------------------------------------------
# cmdtest.py
#----------------------------------------------------------------------
# Copyright 2013-2015 Johan Holmberg.
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

# This is a minimal Python version of "cmdtest".

import argparse
import copy
import glob
import hashlib
import io
import os
import re
import shutil
import subprocess
import sys
import time
import types

if sys.platform == 'win32':
    try:
        import win_unicode_console
    except ImportError:
        pass
    else:
        win_unicode_console.enable()

class AssertFailed(Exception):
    pass

ORIG_CWD = os.getcwd()

class Statistics:
    def __init__(self):
        self.classes = 0
        self.methods = 0
        self.commands = 0
        self.errors = 0
        self.fatals = 0

    def __repr__(self):
        return "Statistics(classes=%s, methods=%s, command=%s, errors=%s, fatals=%s)" % (
            self.classes,
            self.methods,
            self.commands,
            self.errors,
            self.fatals,
        )

#----------------------------------------------------------------------

def subranges(n, arr):
    arr = list(arr)
    for i in range(0,len(arr)-n+1):
        yield arr[i:i+n]

def to_list(arg):
    return arg if isinstance(arg, list) else [arg]

def to_content(lines):
    return ''.join(line + "\n" for line in lines)

def to_lines(content, newline="\n"):
    lines = content.split("\n")
    if lines[-1] == '':
        lines.pop()
    else:
        lines[-1] += "<nonewline>"
    return lines

def mkdir_for(filepath):
    dirpath = os.path.dirname(filepath)
    if dirpath:
        os.makedirs(dirpath, exist_ok=True)


def progress(*args):
    print("###", "-" * 50, *args)

def error_show(name, what, arg):
    try:
        msg = arg.error_msg(what)
    except:
        if re.match(r'(stdout|stderr|file)_', name):
            print(what)
            if len(arg) == 0:
                print("     <<empty>>")
            else:
                for line in arg:
                    print("    ", line)
        else:
            print(what, arg)
    else:
        print(msg, end='')

class Lines:
    def __init__(self, lines):
        self.lines = lines

    def error_msg(self, what):
        res = io.StringIO()
        print(what, file=res)
        for line in self.lines:
            print("    ", line, file=res)
        return res.getvalue()

class Regexp:
    def __init__(self, pattern):
        self.pattern = pattern

    def error_msg(self, what):
        res = io.StringIO()
        print(what, file=res)
        print("     pattern '%s'" % self.pattern, file=res)
        return res.getvalue()

#----------------------------------------------------------------------

class File:
    def __init__(self, fname):
        with open(fname, 'rb') as f:
            self.content = f.read()

    def lines(self, encoding):
        return to_lines(self.content.decode(encoding=encoding), os.linesep)

#----------------------------------------------------------------------

class ExpectFile:
    def __init__(self, result, content, encoding):
        self.result = result
        self.encoding = encoding
        if isinstance(content, list):
            self.lines = content
        else:
            self.lines = to_lines(content)

    def check(self, name, actual_bytes):
        try:
            actual_lines = actual_bytes.lines(self.encoding)
        except UnicodeDecodeError:
            actual_lines = ["<CAN'T DECODE AS " + self.encoding + ">"]

        if actual_lines != self.lines:
            print("--- ERROR:", name)
            error_show(name, "actual:", actual_lines)
            error_show(name, "expect:", self.lines)
            self.result._nerrors += 1

#----------------------------------------------------------------------

class ExpectPattern:
    def __init__(self, result, pattern, encoding):
        self.result = result
        self.encoding = encoding
        self.pattern = pattern

    def _match(self, lines):
        patterns = to_list(self.pattern)
        for some_lines in subranges(len(patterns), lines):
            for pattern, line in zip(patterns, some_lines):
                if not re.search(pattern, line):
                    break
            else:
                return True

    def check(self, name, actual_bytes):
        try:
            actual_lines = actual_bytes.lines(self.encoding)
        except UnicodeDecodeError:
            actual_lines = ["<CAN'T DECODE AS " + self.encoding + ">"]
            ok = False
        else:
            ok = self._match(actual_lines)

        if not ok:
            print("--- ERROR:", name)
            error_show(name, "actual:", actual_lines)
            error_show(name, "expect:", ['PATTERN:'] + to_list(self.pattern))
            self.result._nerrors += 1

#----------------------------------------------------------------------

class Result:
    def __init__(self, err, before, after, stdout, stderr, tmpdir):
        self._err = err
        self._before = before
        self._after = after
        self._stdout = stdout
        self._stderr = stderr

        self._checked_stdout = False
        self._checked_stderr = False
        self._checked_status = False
        self._checked_files = set()
        self._nerrors = 0

    def __enter__(self, *args):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        if exc_type is not None: return False

        if "created"  not in self._checked_files:  self.created_files()
        if "modified" not in self._checked_files:  self.modified_files()
        if "removed"  not in self._checked_files:  self.removed_files()

        if not self._checked_status: self.exit_zero()

        if not self._checked_stdout: self.stdout_equal([])
        if not self._checked_stderr: self.stderr_equal([])

        if self._nerrors > 0:
            raise AssertFailed("...")

    def _error(self, name, actual, expect):
        self._nerrors += 1
        print("--- ERROR:", name)
        error_show(name, "actual:", actual)
        error_show(name, "expect:", expect)
        print()

    def exit_status(self, status):
        self._checked_status = True
        if self._err != status:
            self._error("exit_status", actual=self._err, expect=status)

    def exit_nonzero(self):
        self._checked_status = True
        if self._err == 0:
            self._error("exit_nonzero", actual=self._err, expect="<nonzero value>")

    def exit_zero(self):
        self._checked_status = True
        if self._err != 0:
            self._error("exit_zero", actual=self._err, expect=0)

    def stdout_match(self, pattern, encoding='utf-8'):
        self._checked_stdout = True
        expect = ExpectPattern(self, pattern, encoding)
        expect.check("stdout_match", self._stdout)

    def stderr_match(self, pattern, encoding='utf-8'):
        self._checked_stderr = True
        expect = ExpectPattern(self, pattern, encoding)
        expect.check("stderr_match", self._stderr)

    def stdout_equal(self, content, encoding='utf-8'):
        self._checked_stdout = True
        expect = ExpectFile(self, content, encoding)
        expect.check("stdout_equal", self._stdout)

    def stderr_equal(self, content, encoding='utf-8'):
        self._checked_stderr = True
        expect = ExpectFile(self, content, encoding)
        expect.check("stderr_equal", self._stderr)

    def file_match(self, fname, pattern, encoding='utf-8'):
        expect = ExpectPattern(self, pattern, encoding)
        expect.check("file_match %s" % fname, File(fname))

    def file_equal(self, fname, content, encoding='utf-8'):
        expect = ExpectFile(self, content, encoding)
        expect.check("file_equal %s" % fname, File(fname))

    TESTS = {
        "created_files"  : (lambda before,after: not before and after,
                            {"created"}),
        "modified_files" : (lambda before,after: before and after and before != after,
                            {"modified"}),
        "written_files"  : (lambda before,after: (not before and after or
                                                 before and after and before != after),
                            {"created","modified"}),
        "affected_files" : (lambda before,after: (bool(before) != bool(after) or
                                                  before and after and before != after),
                            {"created","modified","removed"}),
        "removed_files"  : (lambda before,after: before and not after,
                            {"removed"}),
    }

    def __getattr__(self, name):
        try:
            f, tags = self.TESTS[name]
        except KeyError:
            raise AttributeError("'%s' object has no attribute '%s'" %
                                 (type(self).__name__, name))

        self._checked_files |= tags

        def method(*fnames):
            expect = set(fnames)
            known = self._after.files() | self._before.files()
            actual = set()
            for x in known:
                after  = self._after.get(x)
                before = self._before.get(x)
                if f(before, after):
                    actual.add(x)

            if actual != expect:
                self._error(name,
                            actual=sorted(actual),
                            expect=sorted(expect))

        return method


#----------------------------------------------------------------------

class TestCase:
    def __init__(self, tmpdir, statistics):
        self.__tmpdir = tmpdir
        self.__statistics = statistics

    def setup(self):
        pass

    def teardown(self):
        pass

    def prepend_path(self, dirpath):
        os.environ['PATH'] = os.pathsep.join((os.path.join(ORIG_CWD, dirpath),
                                              os.environ['PATH']))

    def prepend_local_path(self, dirpath):
        os.environ['PATH'] = os.pathsep.join((os.path.join(self.__tmpdir.top, dirpath),
                                              os.environ['PATH']))

    def import_file(self, src, tgt):
        mkdir_for(tgt)
        shutil.copy(os.path.join(ORIG_CWD, src), tgt)

    def create_file(self, fname, content, encoding='utf-8'):
        mkdir_for(fname)
        with open(fname, "w", encoding=encoding) as f:
            if type(content) == list:
                for line in content:
                    print(line, file=f)
            else:
                f.write(content)

    def transcode_file(self, src_file, tgt_file=None, src_encoding='utf-8', tgt_encoding='utf-8'):
        if tgt_file:
            mkdir_for(tgt_file)
        else:
            tgt_file = src_file

        with open(src_file, "r", encoding=src_encoding) as f:
            data = f.read()
        with open(tgt_file, "w", encoding=tgt_encoding) as f:
            f.write(data)

    def cmd(self, cmdline):
        tmpdir = self.__tmpdir
        before = tmpdir.snapshot()
        stdout_log = tmpdir.stdout_log()
        stderr_log = tmpdir.stderr_log()
        self._wait_for_new_second()
        self.__statistics.commands += 1
        print("### cmdline:", cmdline)
        with open(stdout_log, "w") as stdout, open(stderr_log, "w") as stderr:
            err = subprocess.call(cmdline, stdout=stdout, stderr=stderr, shell=True)
        after = tmpdir.snapshot()

        return Result(err, before, after,
                      File(stdout_log), File(stderr_log),
                      tmpdir)

    def _wait_for_new_second(self):
        newest = self._newest_file_time()
        while self._current_file_time() == newest:
            time.sleep(0.1)

    def _newest_file_time(self):
        newest = None
        for dirpath, dirnames, filenames in os.walk(self.__tmpdir.top):
            for filename in filenames:
                path = os.path.join(dirpath, filename)
                mtime = os.path.getmtime(path)
                if not newest or mtime > newest:
                    newest = mtime
        return newest

    def _current_file_time(self):
        with open(self.__tmpdir.timestamp_file(), "w") as f:
            print("file written to detect 'mtime'", file=f)
        return os.path.getmtime(self.__tmpdir.timestamp_file())


#----------------------------------------------------------------------

class DirInfo:
    def __init__(self, dirpath, prefix=""):
        self.dirpath = dirpath
        self.prefix = prefix
        self.display_path = prefix

    def entries(self):
        for entry in os.listdir(self.dirpath):
            path = os.path.join(self.dirpath, entry)
            if os.path.isdir(path):
                yield DirInfo(path, self.prefix + entry + "/")
            else:
                yield FileInfo(path, self.prefix + entry)

    def __eq__(self, other):
        return self.display_path == other.display_path

    def __ne__(self, other):
        return not (self == other)


class FileInfo:
    def __init__(self, path, relpath):
        self.path = path
        self.relpath = relpath
        self.display_path = relpath
        self.stat = os.stat(self.path)

        m = hashlib.md5()
        with open(path, "rb") as f:
            m.update(f.read())
        self.digest = m.hexdigest()

    def __eq__(self, other):
        return (self.display_path == other.display_path and
                self.digest == other.digest and
                self.stat.st_ino == other.stat.st_ino and
                self.stat.st_mtime == other.stat.st_mtime)

    def __ne__(self, other):
        return not (self == other)

#----------------------------------------------------------------------

class FsSnapshot:
    def __init__(self, topdir):
        self.topdir = topdir
        self.bypath = {}
        self._collect_files(DirInfo(topdir))

    def __getitem__(self, path):
        return self.bypath[path]

    def get(self, path):
        try:
            return self[path]
        except KeyError:
            return None

    def _collect_files(self, dirinfo):
        for entry in dirinfo.entries():
            self.bypath[entry.display_path] = entry
            if isinstance(entry, DirInfo):
                self._collect_files(entry)

    def files(self):
        return set(self.bypath.keys())

#----------------------------------------------------------------------

class Tmpdir:
    def __init__(self):
        self.top = os.path.abspath("tmp-cmdtest-python/work")
        self.logdir = os.path.dirname(self.top)
        self.environ_path = os.environ['PATH']
        self.old_cwds = []

    def stdout_log(self):
        return os.path.join(self.logdir, "tmp.stdout")

    def stderr_log(self):
        return os.path.join(self.logdir, "tmp.stderr")

    def timestamp_file(self):
        return os.path.join(self.logdir, "tmp.timestamp")

    def snapshot(self):
        return FsSnapshot(self.top)

    def clear(self):
        if os.path.exists(self.top):
            shutil.rmtree(self.top)
        os.makedirs(self.top)

    def __enter__(self):
        self.old_cwds.append(os.getcwd())
        os.chdir(self.top)

    def __exit__(self, exc_type, exc_value, traceback):
        os.chdir(self.old_cwds.pop())
        os.environ['PATH'] = self.environ_path

        if exc_type is not None: return False


#----------------------------------------------------------------------

class Tmethod:
    def __init__(self, method, tclass):
        self.method = method
        self.tclass = tclass

    def name(self):
        return self.method.__name__

    def run(self, tmpdir, statistics):
        obj = self.tclass.klass(tmpdir, statistics)
        tmpdir.clear()
        with tmpdir:
            try:
                obj.setup()
                self.method(obj)
            except AssertFailed as e:
                statistics.errors += 1
            except Exception as e:
                print("--- exception in test: %s: %s" % (sys.exc_info()[0].__name__, e))
                import traceback
                traceback.print_tb(sys.exc_info()[2])
                statistics.fatals += 1
            obj.teardown()


#----------------------------------------------------------------------

class Tclass:
    def __init__(self, klass, tfile):
        self.klass = klass
        self.tfile = tfile

    def name(self):
        return self.klass.__name__

    def tmethods(self):
        for name in sorted(self.klass.__dict__.keys()):
            if re.match(r'test_', name):
                yield Tmethod(self.klass.__dict__[name], self)

#----------------------------------------------------------------------

class Tfile:
    def __init__(self, filename):
        try:
            with open(filename, encoding='utf-8') as f:
                co = compile(f.read(), filename, "exec")
        except IOError as e:
            print("cmdtest: error: failed to read %s" % filename,
                  file=sys.stderr)
            sys.exit(1)
        except SyntaxError as e:
            print("cmdtest: error: syntax error reading %s: %s" % (filename, e),
                  file=sys.stderr)
            sys.exit(1)

        self.glob = dict()
        self.glob['TestCase'] = TestCase
        exec(co, self.glob)

    def tclasses(self):
        for name in sorted(self.glob.keys()):
            if re.match(r'TC_', name):
                yield Tclass(self.glob[name], self)

#----------------------------------------------------------------------

def parse_otions():
    parser = argparse.ArgumentParser('jcons')
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="be more verbose")
    parser.add_argument("arg", nargs="*",
                        help="CMDTEST_*.py files / test methods")
    options = parser.parse_args()
    py_files = []
    selected_methods = set()
    for arg in options.arg:
        if re.match(r'CMDTEST_.*\.py$', arg):
            py_files.append(arg)
        else:
            selected_methods.add(arg)
    if not py_files:
        py_files = glob.glob("CMDTEST_*.py")
        if not py_files:
            print("ERROR: no CMDTEST_*.py files found")
            exit(1)

    return options, py_files, selected_methods

def main():
    options, py_files, selected_methods = parse_otions()
    statistics = Statistics()
    for py_file in py_files:
        tfile = Tfile(py_file)
        tmpdir = Tmpdir()
        for tclass in tfile.tclasses():
            statistics.classes += 1
            progress(tclass.name())
            for tmethod in tclass.tmethods():
                if not selected_methods or tmethod.name() in selected_methods:
                    statistics.methods += 1
                    progress(tmethod.name())
                    tmethod.run(tmpdir, statistics)
    print()
    print(statistics)
    print()
    exit(0 if statistics.errors == 0 and statistics.fatals == 0 else 1)

if __name__ == '__main__':
    main()
