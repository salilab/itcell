import unittest
import itcell
import saliweb.test
import saliweb.backend
import os


class JobTests(saliweb.test.TestCase):
    """Check custom ITCell Job class"""

    def test_run_ok(self):
        """Test successful run method"""
        j = self.make_test_job(itcell.Job, 'RUNNING')
        with saliweb.test.working_directory(j.directory):
            with open('input.txt', 'w') as fh:
                fh.write('foo bar baz\n')
            cls = j.run()
            self.assertIsInstance(cls, saliweb.backend.SGERunner)
            os.unlink('input.txt')


if __name__ == '__main__':
    unittest.main()
