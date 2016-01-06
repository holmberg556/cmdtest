
import os
from contextlib import contextmanager

TOP = os.getcwd()

class SelftestUtils:

    def setup(self):
        self.always_ignore_file('tmp-cmdtest-python/')

    def create_CMDTEST_foo(self, *lines):
        self.create_file("CMDTEST_foo.py", [
            "class TC_foo(TestCase):",
            "    def setup(self):",
            "        #prepend_path #{BIN.inspect}",
            "        #prepend_path #{PLATFORM_BIN.inspect}",
            "        pass",
            "",
            "    def test_foo(self):",
            [ "        " + line for line in lines],
        ])

    @contextmanager
    def cmd_cmdtest(self, *args):
        cmdtest = "%s/cmdtest.py" % TOP
        command = "%s --quiet CMDTEST_foo.py" % cmdtest
        cmdline = ' '.join([command] + list(args))
        with self.cmd(cmdline) as c:
            yield c
