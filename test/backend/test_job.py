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
        d = saliweb.test.RunInDir(j.directory)
        open('input.txt', 'w').write('foo bar baz\n')
        cls = j.run()
        self.assert_(isinstance(cls, saliweb.backend.SGERunner),
                     "SGERunner not returned")
        os.unlink('input.txt')


if __name__ == '__main__':
    unittest.main()
