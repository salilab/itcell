import unittest
import saliweb.test
import re

# Import the itcell frontend with mocks
itcell = saliweb.test.import_mocked_frontend("itcell", __file__,
                                             '../../frontend')


class Tests(saliweb.test.TestCase):
    """Check results page"""

    def test_results_file(self):
        """Test download of results files"""
        with saliweb.test.make_frontend_job('testjob') as j:
            j.make_file('bad.log')
            c = itcell.app.test_client()
            # Bad file
            rv = c.get('/job/testjob/bad.log?passwd=%s' % j.passwd)
            self.assertEqual(rv.status_code, 404)
            # Good files
            for good in ('itcell.log', 'test_scores.txt',
                         'antigen_seq.txt.out.test'):
                j.make_file(good)
                rv = c.get('/job/testjob/%s?passwd=%s' % (good, j.passwd))
                self.assertEqual(rv.status_code, 200)

    def test_ok_job(self):
        """Test display of OK job"""
        with saliweb.test.make_frontend_job('testjob2') as j:
            j.make_file(
                "scores.txt",
                "     1  3 | NYKQKLATCDFY | -0.26 | 0.96 | -1.22 "
                "| -2523.349 | -1026.093 | -1497.256\n"
                "     2  1 | PKNYKQKLATCD | -0.15 | -1.38 | 1.23 "
                "| -2470.08 | -1142.602 | -1327.478")
            c = itcell.app.test_client()
            rv = c.get('/job/testjob2?passwd=%s' % j.passwd)
            r = re.compile(rb'Rank.*Number.*Peptide.*Total Z\-Score.*'
                           b'NYKQKLATCDFY.*PKNYKQKLATCD',
                           re.MULTILINE | re.DOTALL)
            self.assertRegex(rv.data, r)

    def test_failed_job(self):
        """Test display of failed job"""
        with saliweb.test.make_frontend_job('testjob3') as j:
            c = itcell.app.test_client()
            rv = c.get('/job/testjob3?passwd=%s' % j.passwd)
            self.assertIn(b'failed to produce any output', rv.data)


if __name__ == '__main__':
    unittest.main()
