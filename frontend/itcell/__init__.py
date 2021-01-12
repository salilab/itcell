from flask import render_template, request, send_from_directory, abort
import saliweb.frontend
from saliweb.frontend import get_completed_job
import os
from . import submit_page, results_page
from .params import ALL_MHC_TYPES

parameters = []
app = saliweb.frontend.make_application(__name__, parameters)


@app.route('/')
def index():
    return render_template('index.html', mhc_types=ALL_MHC_TYPES)


@app.route('/help')
def help():
    return render_template('help.html')


@app.route('/about')
def about():
    return render_template('about.html')


@app.route('/download')
def download():
    return render_template('download.html')


@app.route('/job', methods=['GET', 'POST'])
def job():
    if request.method == 'GET':
        return saliweb.frontend.render_queue_page()
    else:
        return submit_page.handle_new_job()


@app.route('/results.cgi/<name>')  # compatibility with old perl-CGI scripts
@app.route('/job/<name>')
def results(name):
    job = get_completed_job(name, request.args.get('passwd'))
    scores = job.get_path('scores.txt')
    if os.path.exists(scores) and os.stat(scores).st_size > 0:
        return results_page.show_results_page(job)
    else:
        return saliweb.frontend.render_results_template("results_failed.html",
                                                        job=job)


@app.route('/job/<name>/<path:fp>')
def results_file(name, fp):
    job = get_completed_job(name, request.args.get('passwd'))
    if (fp == 'itcell.log' or 'scores.txt' in fp
            or 'antigen_seq.txt.out' in fp):
        return send_from_directory(job.directory, fp)
    else:
        abort(404)
