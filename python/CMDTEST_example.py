

class TC_example(TestCase):

    def setup(self):
        pass

    def test_01_exception(self):
        self.create_file("some/deep/dir/foo.txt", [
            "abc ...",
        ])
        raise RuntimeError("blaha...")

    def test_02_two_errors(self):
        with self.cmd("false") as c:
            c.exit_status(0)
            c.created_files("new_file")

        with self.cmd("true") as c:
            c.exit_status(0)


    def test_03_simple(self):
        self.create_file("some/deep/dir/foo.txt", [
            "abc ...",
        ])

        with self.cmd("echo hello") as c:
            c.stdout_equal(r'hello')
            c.exit_status(0)

        with self.cmd("touch aaa bbb") as c:
            c.created_files('aaa', 'bbb')
            c.exit_status(0)

        with self.cmd("echo 11 >> aaa") as c:
            c.modified_files('aaa', 'bbb')


    def test_04_stdout(self):
        with self.cmd("touch unexpected ; inc 3") as c:
            c.stdout_equal([
                "1",
                "2.1",
                "3",
            ])

    def test_04_stdout_match(self):
        with self.cmd("inc 3 ; date") as c:
            c.stdout_match(r'x CEST 2015')

    def test_05_implcit(self):
        with self.cmd("false") as c:
            c.exit_nonzero()

    def test_06_ls(self):
        self.create_file("aaa.txt", "aaa\n")
        self.import_file("../file1.txt", "subdir/bbb.txt")

        with self.cmd("ls") as c:
            c.stdout_equal([
                "aaa.txt",
                "subdir",
            ])

    def test_07_path(self):
        with self.cmd("hello1") as c:
            c.exit_nonzero()
            c.stderr_match('command not found')

        self.prepend_path("../files/bin")

        with self.cmd("hello1") as c:
            c.stdout_equal("hello\n")

    def test_07_path_ii(self):
        self.import_file("../files/bin/hello1", "blaha/hello2")

        with self.cmd("hello2") as c:
            c.exit_nonzero()
            c.stderr_match('command not found')

        self.prepend_local_path("blaha")

        with self.cmd("hello2") as c:
            c.stdout_equal(["hello2"])


    def test_08_encoding(self):
        self.create_file("abc.txt", [
            'detta är abc.txt',
            'räksmörgås',
            ' aaa',
            ' bbb',
            ' ccc',
            ' ddd',
        ], encoding='utf-16')
        with self.cmd("cat abc.txt") as c:
            c.stdout_equal([
                'detta är abc.txt',
                'räksmörgås',
            ], 'utf-16')
            c.stdout_match("tt", 'utf-16')

            c.file_equal("abc.txt", [
                'detta är abc.txtx',
                'räksmörgås',
            ], 'utf-16')
            c.file_match("abc.txt", [
                "xbb",
                "ccc",
            ], 'utf-16')

        with self.cmd("true") as c:
            pass

    def xxx_test_bool(self):
        with self.cmd("true") as c:
            c.exit_status(0)

        with self.cmd("false") as c:
            c.exit_nonzero()
