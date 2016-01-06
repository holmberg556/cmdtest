
from selftest_utils import SelftestUtils

class TC_stdout_equal(SelftestUtils, TestCase):

    def test_stdout_equal_CORRECT_EMPTY(self):
        self.create_CMDTEST_foo(
            'with self.cmd("true") as c:',
            '    c.stdout_equal([',
            '    ])',
        )

        with self.cmd_cmdtest() as c:
            c.stdout_equal([
                "### cmdline: true",
            ])

    def test_stdout_equal_INCORRECT_EMPTY(self):
        self.create_CMDTEST_foo(
            'with self.cmd("echo hello") as c:',
            '    c.stdout_equal([',
            '    ])',
        )

        with self.cmd_cmdtest() as c:
            c.stdout_equal([
                "### cmdline: echo hello",
                "--- ERROR: stdout_equal",
                "actual:",
                "     hello",
                "expect:",
                "     <<empty>>",
            ])
            c.exit_nonzero()

    def test_stdout_equal_CORRECT_2_LINES(self):
        self.create_CMDTEST_foo(
            'with self.cmd("echo hello && echo world") as c:',
            '    c.stdout_equal([',
            '        "hello",',
            '        "world",',
            '    ])',
        )

        with self.cmd_cmdtest() as c:
            c.stdout_equal([
                "### cmdline: echo hello && echo world",
            ])

    def test_stdout_equal_INCORRECT_2_LINES(self):
        self.create_CMDTEST_foo(
            'with self.cmd("echo hello && echo world && echo MORE") as c:',
            '    c.stdout_equal([',
            '        "hello",',
            '        "world",',
            '    ])',
        )

        with self.cmd_cmdtest() as c:
            c.stdout_equal([
                "### cmdline: echo hello && echo world && echo MORE",
                "--- ERROR: stdout_equal",
                "actual:",
                "     hello",
                "     world",
                "     MORE",
                "expect:",
                "     hello",
                "     world",
            ])
            c.exit_nonzero()
