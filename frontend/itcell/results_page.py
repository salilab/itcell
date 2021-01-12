import saliweb.frontend
import collections

Result = collections.namedtuple(
    'Result', ['rank', 'number', 'peptide', 'total_z', 'pmhc_z', 'tcr_z',
               'total', 'pmhc', 'tcr'])


def get_results(fh):
    for line in fh:
        (rank_num, peptide, total_z, pmhc_z, tcr_z,
         total, pmhc, tcr) = line.split('|')
        rank, num = rank_num.split()
        yield Result(rank=int(rank), number=int(num), peptide=peptide.strip(),
                     total_z=total_z.strip(), pmhc_z=pmhc_z.strip(),
                     tcr_z=tcr_z.strip(), total=total.strip(),
                     pmhc=pmhc.strip(), tcr=tcr.strip())


def show_results_page(job):
    with open(job.get_path('scores.txt')) as fh:
        results = list(get_results(fh))
    return saliweb.frontend.render_results_template("results_ok.html",
                                                    job=job, results=results)
