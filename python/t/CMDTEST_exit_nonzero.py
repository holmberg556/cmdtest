
from selftest_utils import SelftestUtils

class TC_exit_nonzero(SelftestUtils, TestCase):

    def test_exit_nonzero_CORRECT(self):
        self.create_CMDTEST_foo(
            'with self.cmd("false") as c:',
            '    c.exit_nonzero()',
        )

        with self.cmd_cmdtest() as c:
            c.stdout_equal([
                "### cmdline: false",
            ])

    def test_exit_nonzero_INCORRECT(self):
        self.create_CMDTEST_foo(
            'with self.cmd("true") as c:',
            '    c.exit_nonzero()',
        )

        with self.cmd_cmdtest() as c:
            c.stdout_equal([
                "### cmdline: true",
                "--- ERROR: exit_nonzero",
                "actual: 0",
                "expect: <nonzero value>",
                "",
            ])
            c.exit_nonzero()

    def test_exit_nonzero_CORRECT_18(self):
        self.create_CMDTEST_foo(
            'with self.cmd("exit 18") as c:',
            '    c.exit_nonzero()',
        )

        with self.cmd_cmdtest() as c:
            c.stdout_equal([
                "### cmdline: exit 18",
            ])
