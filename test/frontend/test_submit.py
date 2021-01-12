import unittest
import saliweb.test
import os
import re
from werkzeug.datastructures import FileStorage

# Import the itcell frontend with mocks
itcell = saliweb.test.import_mocked_frontend("itcell", __file__,
                                             '../../frontend')


class Tests(saliweb.test.TestCase):
    """Check submit page"""

    def test_submit_page(self):
        """Test submit page"""
        with saliweb.test.temporary_directory() as tmpdir:
            incoming = os.path.join(tmpdir, 'incoming')
            os.mkdir(incoming)
            itcell.app.config['DIRECTORIES_INCOMING'] = incoming
            c = itcell.app.test_client()
            tcrfile = os.path.join(tmpdir, 'test.pdb')
            with open(tcrfile, 'w') as fh:
                fh.write(
                    "ATOM      2  CA  ALA     1      26.711  14.576   5.091\n")

            # Successful submission (no email)
            rv = c.post('/job', data={'mhctype': 'DRB1*0101',
                                      'tcrfile': open(tcrfile, 'rb'),
                                      'antigen': 'ABCD'})
            self.assertEqual(rv.status_code, 200)
            r = re.compile(
                b'Your job.*has been submitted.*Results will be found',
                re.MULTILINE | re.DOTALL)
            self.assertRegex(rv.data, r)

            # Successful submission (with email)
            rv = c.post('/job',
                        data={'mhctype': 'DRB1*0101',
                              'tcrfile': open(tcrfile, 'rb'),
                              'antigen': 'ABCD', 'email': 'test@test.com'})
            self.assertEqual(rv.status_code, 200)
            r = re.compile(
                b'Your job.*has been submitted.*Results will be found.*'
                b'You will be notified at', re.MULTILINE | re.DOTALL)
            self.assertRegex(rv.data, r)

    def test_get_peptide_mhc_file_mhc_type(self):
        """Test get_peptide_mhc_file with user-provided MHC type"""
        t = itcell.submit_page.get_peptide_mhc_file(None, 'DRB1*0101', None)
        self.assertEqual(t, 'DRB1*0101')

    def test_get_peptide_mhc_file_file(self):
        """Test get_peptide_mhc_file with user-provided PDB file"""
        with saliweb.test.temporary_directory() as incoming:
            itcell.app.config['DIRECTORIES_INCOMING'] = incoming

            with itcell.app.app_context():
                # Real but empty file
                job = saliweb.frontend.IncomingJob()
                infile = job.get_path('infile')
                with open(infile, 'w') as fh:
                    pass  # make empty file
                fh = FileStorage(stream=open(infile, 'rb'), filename='outfile')
                self.assertRaises(
                    saliweb.frontend.InputValidationError,
                    itcell.submit_page.get_peptide_mhc_file, job, "None", fh)
                # Real non-empty file
                with open(infile, 'w') as fh:
                    fh.write('REMARK\n')
                    fh.write("ATOM      2  CA  ALA     1      "
                             "26.711  14.576   5.091\n")
                fh = FileStorage(stream=open(infile, 'rb'), filename='outfile')
                t = itcell.submit_page.get_peptide_mhc_file(job, 'None', fh)
                self.assertEqual(t, 'pMHC.pdb')

    def test_get_peptide_mhc_file_none(self):
        """Test get_peptide_mhc_file with no MHC type or PDB file"""
        self.assertRaises(
            saliweb.frontend.InputValidationError,
            itcell.submit_page.get_peptide_mhc_file, None, None, None)

    def test_get_tcr_file(self):
        """Test get_tcr_file with provided TCR file"""
        with saliweb.test.temporary_directory() as incoming:
            itcell.app.config['DIRECTORIES_INCOMING'] = incoming

            with itcell.app.app_context():
                job = saliweb.frontend.IncomingJob()
                # No file
                self.assertRaises(
                    saliweb.frontend.InputValidationError,
                    itcell.submit_page.get_tcr_file, job, None)
                # Real but empty file
                infile = job.get_path('infile')
                with open(infile, 'w') as fh:
                    fh.write('REMARK\n')  # no atom records
                fh = FileStorage(stream=open(infile, 'rb'), filename='outfile')
                self.assertRaises(
                    saliweb.frontend.InputValidationError,
                    itcell.submit_page.get_tcr_file, job, fh)
                # Real non-empty file
                with open(infile, 'w') as fh:
                    fh.write('REMARK\n')
                    fh.write("ATOM      2  CA  ALA     1      "
                             "26.711  14.576   5.091\n")
                fh = FileStorage(stream=open(infile, 'rb'), filename='outfile')
                itcell.submit_page.get_tcr_file(job, fh)

    def test_get_antigen(self):
        """Test get_antigen"""
        with saliweb.test.temporary_directory() as incoming:
            itcell.app.config['DIRECTORIES_INCOMING'] = incoming

            with itcell.app.app_context():
                job = saliweb.frontend.IncomingJob()
                # No sequence
                self.assertRaises(
                    saliweb.frontend.InputValidationError,
                    itcell.submit_page.get_antigen, job, None)
                # Provided sequence
                itcell.submit_page.get_antigen(job, 'ABCD')
                self.assertTrue(
                    os.path.exists(job.get_path('antigen_seq.txt')))


if __name__ == '__main__':
    unittest.main()
