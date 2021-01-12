from flask import request
import saliweb.frontend
from .params import ALL_MHC_TYPES


def handle_new_job():
    mhctype = request.form.get('mhctype')
    mhcpdbfile = request.files.get('mhcpdbfile')
    tcrfile = request.files.get('tcrfile')
    antigen = request.form.get('antigen')
    email = request.form.get('email')
    jobname = request.form.get('jobname')

    saliweb.frontend.check_email(email, required=False)

    job = saliweb.frontend.IncomingJob(jobname)

    pmhc_file_name = get_peptide_mhc_file(job, mhctype, mhcpdbfile)
    get_tcr_file(job, tcrfile)
    get_antigen(job, antigen)

    # write parameters
    with open(job.get_path('input.txt'), 'w') as fh:
        fh.write("%s TCR.pdb antigen_seq.txt\n" % pmhc_file_name)
    with open(job.get_path('data.txt'), 'w') as fh:
        fh.write("%s %s %s %s %s\n"
                 % (mhctype, mhcpdbfile, tcrfile, email, jobname))

    job.submit(email)

    # Pop up an exit page
    return saliweb.frontend.render_submit_template('submit.html', email=email,
                                                   job=job)


def has_atoms(fname):
    """Return True iff fname has at least one ATOM record"""
    with open(fname) as fh:
        for line in fh:
            if line.startswith('ATOM  '):
                return True


def get_peptide_mhc_file(job, mhctype, mhcpdbfile):
    """Get input peptide-MHC by type or uploaded PDB file"""
    if mhctype in ALL_MHC_TYPES:
        return mhctype
    elif mhcpdbfile:
        fname = 'pMHC.pdb'
        full_fname = job.get_path(fname)
        mhcpdbfile.save(full_fname)  # todo: check chain IDs
        if not has_atoms(full_fname):
            raise saliweb.frontend.InputValidationError(
                "PDB file contains no ATOM records!")
        return fname
    else:
        raise saliweb.frontend.InputValidationError(
                "Error in input PDB: please specify MHC type or upload file")


def get_tcr_file(job, tcrfile):
    """Handle upload of TCR structure"""
    if tcrfile:
        fname = job.get_path('TCR.pdb')
        atoms = 0
        with open(fname, 'wb') as out:
            for line in tcrfile:
                if line.startswith(b'ATOM  '):
                    atoms += 1
                    out.write(line)
        if atoms == 0:
            raise saliweb.frontend.InputValidationError(
                "You have uploaded a TCR file containing no atoms")
    else:
        raise saliweb.frontend.InputValidationError(
                "Please upload valid TCR file")


def get_antigen(job, antigen):
    """Handle upload of antigen sequence"""
    if antigen:
        with open(job.get_path('antigen_seq.txt'), 'w') as fh:
            fh.write(antigen)
        # todo: validate sequence
    else:
        raise saliweb.frontend.InputValidationError(
                "Please provide antigen sequence")
