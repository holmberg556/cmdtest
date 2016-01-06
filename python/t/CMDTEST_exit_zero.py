
from selftest_utils import SelftestUtils

class TC_exit_zero(SelftestUtils, TestCase):

    def test_exit_zero_CORRECT(self):
        self.create_CMDTEST_foo(
            'with self.cmd("true") as c:',
            '    c.exit_zero()',
        )

        with self.cmd_cmdtest() as c:
            c.stdout_equal([
                "### cmdline: true",
            ])

    def test_exit_zero_INCORRECT(self):
        self.create_CMDTEST_foo(
            'with self.cmd("false") as c:',
            '    c.exit_zero()',
        )

        with self.cmd_cmdtest() as c:
            c.stdout_equal([
                "### cmdline: false",
                "--- ERROR: exit_zero",
                "actual: 1",
                "expect: 0",
                "",
            ])
            c.exit_nonzero()

    def test_exit_zero_INCORRECT_18(self):
        self.create_CMDTEST_foo(
            'with self.cmd("exit 18") as c:',
            '    c.exit_zero()',
        )

        with self.cmd_cmdtest() as c:
            c.stdout_equal([
                "### cmdline: exit 18",
                "--- ERROR: exit_zero",
                "actual: 18",
                "expect: 0",
                "",
            ])
            c.exit_nonzero()
