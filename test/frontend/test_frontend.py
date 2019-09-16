import unittest
import saliweb.test

# Import the itcell frontend with mocks
itcell = saliweb.test.import_mocked_frontend("itcell", __file__,
                                             '../../frontend')


class Tests(saliweb.test.TestCase):

    def test_index(self):
        """Test index page"""
        c = itcell.app.test_client()
        rv = c.get('/')
        self.assertIn(b'Select MHC type or upload peptide-MHC structure',
                      rv.data)

    def test_about(self):
        """Test about page"""
        c = itcell.app.test_client()
        rv = c.get('/about')
        self.assertIn(b'TCell is a method for prediction of T-cell epitopes',
                      rv.data)

    def test_help(self):
        """Test help page"""
        c = itcell.app.test_client()
        rv = c.get('/help')
        self.assertIn(b'output table contains the peptides and their pMHCII',
                      rv.data)

    def test_download(self):
        """Test download page"""
        c = itcell.app.test_client()
        rv = c.get('/download')
        self.assertIn(b'The source code of this web service is', rv.data)

    def test_queue(self):
        """Test queue page"""
        c = itcell.app.test_client()
        rv = c.get('/job')
        self.assertIn(b'No pending or running jobs', rv.data)


if __name__ == '__main__':
    unittest.main()
