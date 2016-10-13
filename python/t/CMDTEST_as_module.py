
from os.path import dirname, abspath, join as path_join

class TC_as_module(TestCase):

    def setup(self):
        self.always_ignore_file('subdir/tmp-cmdtest-python/')

    def test_as_module(self):
        self.create_file("subdir/CMDTEST_foo.py", [
            'class TC_foo(TestCase):',
            '    def test_01(self):',
            '        with self.cmd("echo hello") as c:',
            '            c.stdout_equal("hello\\n")',
            '    def test_02(self):',
            '        with self.cmd("echo world") as c:',
            '            c.stdout_equal("world\\n")',
            '    def test_03(self):',
            '        with self.cmd("echo hello") as c:',
            '            c.stdout_equal("world\\n")',
        ])

        dpath = dirname(abspath(__file__))
        command = path_join(dpath, 'as_module.py')
        with self.cmd(command + ' subdir') as c:
            c.stdout_match([
                r'--- ERROR: stdout_equal',
                r'actual:',
                r'     hello',
                r'expect:',
                r'     world',
                r'Statistics\(classes=1, methods=3, command=3, errors=1, fatals=0\)',
            ])
            c.exit_nonzero()
